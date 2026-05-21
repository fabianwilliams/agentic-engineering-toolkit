#!/usr/bin/env bash
#
# ADOTOB Loop: Always On, Time On, Budget.
#
# A constitutional bash-loop runtime for self-improving agent fleets.
# Implements the discipline in ../self-improving-fleet-loop/README.md.
#
# Apache 2.0. See LICENSE in repo root.
#
# Usage:
#   adotob-loop.sh           # continuous loop (default)
#   adotob-loop.sh --once    # single iteration, then exit (for cron / testing)
#   adotob-loop.sh --dry     # single iteration, no actions fired, no receipt persisted
#
# Required from the caller (wire in .env or shell init):
#   - llm_call <prompt>            shell function; takes prompt, returns JSON to stdout
#   - sensors/collect.sh           writes the iteration sensor JSON to $1
#   - actions/update_memory.sh     receives proposal JSON path as $1
#   - actions/open_pr.sh           receives proposal JSON path as $1
#   - actions/escalate.sh          receives proposal JSON path as $1
#   - actions/noop.sh              receives proposal JSON path as $1
#
# Constitution + policy are read from $ADOTOB_CONSTITUTION (default ./constitution.yml).
# Per-iteration receipts land in $ADOTOB_RECEIPT_DIR/<iter_id>/receipt.json.

set -u
set -o pipefail

# ---------------------------------------------------------------------
# Phase 0: Constitutional init
# ---------------------------------------------------------------------

# Load env if present (LLM key, Telegram bot token, llm_call function, etc.)
[ -f ./.env ] && source ./.env

CONSTITUTION="${ADOTOB_CONSTITUTION:-./constitution.yml}"
SENSOR_SCRIPT="${ADOTOB_SENSOR_SCRIPT:-./sensors/collect.sh}"
ACTION_DIR="${ADOTOB_ACTION_DIR:-./actions}"
LEARNING_PROMPT="${ADOTOB_LEARNING_PROMPT:-./learning/prompt.md}"
RECEIPT_DIR="${ADOTOB_RECEIPT_DIR:-./receipts}"
INTERVAL_SEC="${ADOTOB_INTERVAL_SEC:-3600}"
WALL_TIME_BUDGET_SEC="${ADOTOB_WALL_TIME_BUDGET_SEC:-120}"
TOKEN_BUDGET_DAILY="${ADOTOB_TOKEN_BUDGET_DAILY:-50000}"
STOP_FILE="${ADOTOB_STOP_FILE:-./STOP}"
TOKEN_LOG="${ADOTOB_TOKEN_LOG:-./receipts/token_usage.log}"

mode="continuous"
[ "${1:-}" = "--once" ] && mode="once"
[ "${1:-}" = "--dry" ] && mode="dry"

# Init checks
init_checks() {
  local fail=0
  [ -f "$CONSTITUTION" ] || { echo "FAIL: constitution not found: $CONSTITUTION"; fail=1; }
  [ -f "$SENSOR_SCRIPT" ] || { echo "FAIL: sensor script not found: $SENSOR_SCRIPT"; fail=1; }
  [ -f "$LEARNING_PROMPT" ] || { echo "FAIL: learning prompt not found: $LEARNING_PROMPT"; fail=1; }
  type llm_call >/dev/null 2>&1 || { echo "FAIL: llm_call function not defined; wire in .env"; fail=1; }
  command -v jq >/dev/null 2>&1 || { echo "FAIL: jq not installed (required for proposal parsing)"; fail=1; }
  mkdir -p "$RECEIPT_DIR" "$ACTION_DIR"
  [ "$fail" -eq 0 ] || exit 1
}

init_checks

# ---------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------

iso_utc()    { date -u +%Y-%m-%dT%H:%M:%SZ; }
iter_id()    { echo "iter_$(date -u +%Y%m%d_%H%M%S)"; }
today_utc()  { date -u +%Y-%m-%d; }

log_event() {
  # log_event <iter_dir> <event> <key=value>...
  local iter_dir="$1"; shift
  local event="$1"; shift
  local line="{\"at\":\"$(iso_utc)\",\"event\":\"$event\""
  while [ $# -gt 0 ]; do line="$line,\"$1\""; shift; done
  line="$line}"
  echo "$line" >> "$iter_dir/events.log"
}

# Tokens used today (sum of token_log entries for today_utc)
tokens_used_today() {
  [ -f "$TOKEN_LOG" ] || { echo 0; return; }
  awk -v d="$(today_utc)" -F, '$1==d {sum+=$2} END {print sum+0}' "$TOKEN_LOG"
}

record_token_usage() {
  # record_token_usage <count>
  local count="$1"
  mkdir -p "$(dirname "$TOKEN_LOG")"
  echo "$(today_utc),$count" >> "$TOKEN_LOG"
}

token_budget_ok() {
  local used=$(tokens_used_today)
  [ "$used" -lt "$TOKEN_BUDGET_DAILY" ]
}

operator_stop() {
  [ -f "$STOP_FILE" ]
}

# ---------------------------------------------------------------------
# Single iteration
# ---------------------------------------------------------------------

run_iteration() {
  local ITER_ID="$(iter_id)"
  local ITER_DIR="$RECEIPT_DIR/$ITER_ID"
  mkdir -p "$ITER_DIR"

  log_event "$ITER_DIR" iter_started "iter_id":"\"$ITER_ID\""

  # Kill switch checks BEFORE any LLM spend
  if operator_stop; then
    log_event "$ITER_DIR" operator_stop_triggered "stop_file":"\"$STOP_FILE\""
    echo "Operator stop file present; halting." >&2
    return 2
  fi
  if ! token_budget_ok; then
    log_event "$ITER_DIR" token_budget_exceeded "used":"$(tokens_used_today)" "ceiling":"$TOKEN_BUDGET_DAILY"
    echo "Daily token budget exhausted; halting iteration." >&2
    return 3
  fi

  # Stage 1: Sensor
  local SENSOR_JSON="$ITER_DIR/sensor.json"
  if ! timeout "$WALL_TIME_BUDGET_SEC" bash "$SENSOR_SCRIPT" "$SENSOR_JSON" 2> "$ITER_DIR/sensor.stderr"; then
    log_event "$ITER_DIR" sensor_failed "stderr":"\"$ITER_DIR/sensor.stderr\""
    return 4
  fi
  log_event "$ITER_DIR" sensor_collected "bytes":"$(wc -c < "$SENSOR_JSON")"

  # Stage 2: Policy gate (deterministic). For v0.1 the policy IS the constitution;
  # a partner can add a separate ./policy.sh that runs first if richer gating is needed.
  # Smallest viable policy gate: refuse if sensor JSON is empty.
  if [ "$(wc -c < "$SENSOR_JSON")" -lt 2 ]; then
    log_event "$ITER_DIR" policy_gate_rejected "reason":"\"empty sensor\""
    return 0
  fi

  # Stage 3: Tool. LLM call to classify and propose action
  local PROMPT_FILE="$ITER_DIR/prompt.txt"
  {
    cat "$LEARNING_PROMPT"
    echo
    echo "## CONSTITUTION"
    cat "$CONSTITUTION"
    echo
    echo "## SENSOR DATA"
    cat "$SENSOR_JSON"
    echo
    echo "## YOUR TASK"
    echo "Classify the situation. Output a single JSON object with these required fields:"
    echo "  action          one of: update_memory | open_pr | escalate | noop"
    echo "  rationale       one-sentence reason"
    echo "  evidence_paths  array of file paths in the sensor data supporting the action"
    echo "  proposed_diff   for update_memory or open_pr: the change to apply. Omit for escalate / noop."
    echo "  escalation     for escalate: { summary, recommended_next, operator_choice }"
  } > "$PROMPT_FILE"

  local PROPOSAL_FILE="$ITER_DIR/proposal.json"
  if ! timeout "$WALL_TIME_BUDGET_SEC" bash -c 'llm_call "$(cat "$1")"' _ "$PROMPT_FILE" > "$PROPOSAL_FILE" 2> "$ITER_DIR/llm.stderr"; then
    log_event "$ITER_DIR" llm_call_failed "stderr":"\"$ITER_DIR/llm.stderr\""
    return 5
  fi

  # Stage 4: Quality gate
  local ACTION
  ACTION=$(jq -r '.action // "INVALID"' "$PROPOSAL_FILE" 2>/dev/null)
  case "$ACTION" in
    update_memory|open_pr|escalate|noop) ;;
    *)
      log_event "$ITER_DIR" quality_gate_rejected "reason":"\"unknown action: $ACTION\""
      return 0
      ;;
  esac
  log_event "$ITER_DIR" quality_gate_passed "action":"\"$ACTION\""

  # Stage 5: Action router (skipped in --dry mode)
  if [ "$mode" = "dry" ]; then
    log_event "$ITER_DIR" dry_run_action_skipped "would_have_fired":"\"$ACTION\""
  else
    local ACTION_SCRIPT="$ACTION_DIR/${ACTION}.sh"
    if [ -x "$ACTION_SCRIPT" ]; then
      if timeout "$WALL_TIME_BUDGET_SEC" bash "$ACTION_SCRIPT" "$PROPOSAL_FILE" > "$ITER_DIR/action.stdout" 2> "$ITER_DIR/action.stderr"; then
        log_event "$ITER_DIR" action_completed "action":"\"$ACTION\""
      else
        log_event "$ITER_DIR" action_failed "action":"\"$ACTION\"" "stderr":"\"$ITER_DIR/action.stderr\""
      fi
    else
      log_event "$ITER_DIR" action_script_missing "script":"\"$ACTION_SCRIPT\""
    fi
  fi

  # Record token usage if the llm_call function writes a count to .last_token_count
  if [ -f .last_token_count ]; then
    record_token_usage "$(cat .last_token_count)"
    rm -f .last_token_count
  fi

  # Emit receipt
  cat > "$ITER_DIR/receipt.json" <<EOF
{
  "iter_id": "$ITER_ID",
  "completed_at": "$(iso_utc)",
  "action_taken": "$ACTION",
  "dry_run": $( [ "$mode" = "dry" ] && echo true || echo false ),
  "tokens_used_today": $(tokens_used_today),
  "token_budget_daily": $TOKEN_BUDGET_DAILY,
  "evidence": {
    "sensor": "$ITER_DIR/sensor.json",
    "prompt": "$ITER_DIR/prompt.txt",
    "proposal": "$ITER_DIR/proposal.json",
    "events": "$ITER_DIR/events.log"
  }
}
EOF
  log_event "$ITER_DIR" receipt_written "receipt":"\"$ITER_DIR/receipt.json\""
}

# ---------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------

case "$mode" in
  once|dry)
    run_iteration
    exit $?
    ;;
  continuous)
    while true; do
      if operator_stop; then
        echo "STOP file present at $STOP_FILE; exiting loop." >&2
        exit 0
      fi
      run_iteration || echo "Iteration returned non-zero ($?); continuing after sleep." >&2
      sleep "$INTERVAL_SEC"
    done
    ;;
esac
