# ADOTOB Loop

> **Always On, Time On, Budget.** A constitutional bash-loop runtime for self-improving agent fleets. Implements the discipline in [[Self-Improving Fleet Loop]]. Apache 2.0.

```
sensor → policy → tool → quality gate → learning  →  sleep  →  loop
   ▲                                                              │
   └──────────────────────────────────────────────────────────────┘
```

---

## What this is

A tight bash loop, run on cron or as a daemon, that implements the five-stage agentic loop with constitutional gates at iteration start and receipt gates at iteration end. Designed for **small autonomous-agent fleets on always-on consumer-tier hardware** (one Mac mini-class box per fleet member, a couple of LLM API keys, Telegram for the operator surface).

The loop is **dumb-shell-simple by design**. Echoes the original Ralph Wiggum loop pattern: a bash `while :` with the agent making each iteration. The discipline lives in the **constitution**, the **policy**, and the **receipt**, not in the loop runtime itself. The runtime stays under 200 lines so it can be audited in one sitting.

## Why "ADOTOB"

The name is a backronym that mirrors the loop's SLA commitment:

| Letter | Promise |
|---|---|
| **A**lways on | Loop runs continuously (cron tick or daemon), not on operator demand |
| **D**eterministic action steps | Every action goes through a wrapper that emits `summary_lines + verified` (no LLM freelance) |
| **O**bservability per iteration | Every iteration emits a receipt to disk and (optionally) Telegram |
| **T**ime-bounded | Iterations honor a wall-time budget; if a step exceeds it, the loop logs + advances |
| **O**perator-gated for high-risk | Constitution names which actions auto-fire vs require thumbs-up |
| **B**udget-respecting | Daily token budget enforced; kill switch on overrun |

The name also echoes Adotob Solutions (the operator and origin), the way the Ralph loop echoed its origin author.

## What this is NOT

- **Not a project-development framework.** For interactive code development with a Phase 1 clarifications gate, see Ralph v2 (different tool, different problem).
- **Not a multi-agent orchestration framework.** ADOTOB Loop runs one loop per box. Multi-box coordination happens through git (memory updates) and Telegram (operator-mediated), not through agent-to-agent RPC.
- **Not a model framework.** ADOTOB Loop calls a single `llm_call` shell function that you wire to Claude / OpenAI / Ollama / whatever. The framework is LLM-agnostic.
- **Not secret sauce.** The framework is Apache 2.0 and lives publicly. Your per-box constitution, sensor scripts, and policy file are private to your deployment. Same separation as RFC 9728 OAuth metadata vs your tenant config.

## The five stages, in order

### Stage 1: Sensor

A directory of small scripts that collect real-world input into a structured JSON file. The loop calls `sensors/collect.sh`; that script orchestrates the per-sensor calls and emits a single sensor JSON for the iteration.

Reference sensors (you write your own):

- `sensors/telegram.sh`: pull last N hours of operator channel messages
- `sensors/brevo.sh`: pull bounces / spam complaints / opens since last iteration
- `sensors/rca_files.sh`: detect new RCA files in `tasks/<box>/RCAs/`
- `sensors/daily_summary.sh`: read today's cron-reasoned daily summary
- `sensors/openclaw_jobs.sh`: read jobs.json + recent action receipts

### Stage 2: Policy

A per-box machine-readable file declaring what the loop may do. The reference implementation uses YAML:

```yaml
# constitution.example.yml
loop:
  interval_sec: 3600          # one iteration per hour
  token_budget_daily: 50000
  wall_time_budget_sec: 120   # per iteration

actions:
  update_memory:
    auto_fire: false          # always requires operator approval
    approval_channel: telegram
  open_pr:
    auto_fire: false
    approval_channel: telegram
  escalate:
    auto_fire: true           # escalation IS the action
  noop:
    auto_fire: true

quality_gate:
  max_iterations_per_day: 24
  min_receipt_completeness: required_fields_present

kill_switch:
  on_token_budget_exceeded: halt
  on_consecutive_failures: 3
  operator_emergency_stop_file: ./STOP
```

### Stage 3: Tool / LLM call

A single `llm_call` shell function that takes a prompt and returns a structured JSON proposal. The framework ships an interface; you wire the implementation.

```bash
# Example implementation in .env or shell setup
llm_call() {
  local prompt="$1"
  curl -s -X POST https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "content-type: application/json" \
    -d "{
      \"model\": \"claude-sonnet-4-6\",
      \"max_tokens\": 4096,
      \"messages\": [{\"role\": \"user\", \"content\": $(jq -Rs . <<< "$prompt")}]
    }" | jq -r '.content[0].text'
}
```

Wire-once, swap freely. Ollama users wire to `ollama run`; OpenAI users wire to `chat/completions`. The loop never depends on which model is on the other end.

### Stage 4: Quality gate

A receipt-style audit-trail check. Reference quality-gate validates:

- Proposal JSON is well-formed
- Required fields present (action, rationale, evidence_paths)
- Action is one of the four named values (`update_memory`, `open_pr`, `escalate`, `noop`)
- Evidence paths exist on disk
- Token budget for the day has headroom

If the gate fails, the proposal is discarded and an explanatory note is written to the receipt.

### Stage 5: Learning

The action router. For each accepted proposal:

- `update_memory` → call `actions/update_memory.sh` which drafts the `feedback_*.md` change and posts the diff to the operator via Telegram for one-click approval. **The diff is never auto-applied.**
- `open_pr` → call `actions/open_pr.sh` which creates a branch, writes the proposed code change, pushes, opens a draft PR with the receipt linked. Operator merges via GitHub UI.
- `escalate` → call `actions/escalate.sh` which Telegrams the operator with a structured prompt: the incident, the proposed action, the recommended next step, and a one-line "what I need from you."
- `noop` → log and move on.

Every action emits a per-iteration receipt to `receipts/<iter_id>/receipt.json`.

## Files in this folder

| File | What it is |
|---|---|
| [`adotob-loop.sh`](./adotob-loop.sh) | The bash runtime. ~150 lines. Reads constitution + policy, runs sensor → llm_call → quality gate → action router → receipt, in a loop. |
| [`constitution.example.yml`](./constitution.example.yml) | Per-box constitution template. Copy and customize per-deployment. |
| [`learning/prompt.md`](./learning/prompt.md) | The system prompt the LLM sees on each iteration. Wraps the YC 5-stage framing and the action vocabulary. |
| [`sensors/README.md`](./sensors/README.md) | Sensor-script conventions and the reference list. |
| [`actions/README.md`](./actions/README.md) | Action-script conventions and the four named action types. |
| [`.env.example`](./.env.example) | Env-var template for LLM keys, Telegram bot token, etc. |
| `LICENSE` | Apache 2.0. |

## Getting started (sketch)

```bash
git clone https://github.com/fabianwilliams/agentic-engineering-toolkit
cd agentic-engineering-toolkit/agents/adotob-loop

cp constitution.example.yml constitution.yml      # edit per your box
cp .env.example .env                              # add your LLM key + Telegram bot token
mkdir -p sensors actions receipts                 # writable dirs

# Write your sensors (one shell script per data source)
# Write your actions (four named routers)
# Sanity-test once:
./adotob-loop.sh --once

# Deploy as a cron job (one tick per ADOTOB_INTERVAL_SEC) OR as a systemd / launchd service
```

The framework intentionally **does not ship working sensor or action implementations**. Those are per-deployment. The framework ships the loop runtime, the constitution schema, the prompt template, and the operator-approval surface conventions.

## What the framework guarantees

- **Always on**: the loop runs continuously, restartable, idempotent across restarts
- **Time-bounded**: per-iteration wall-time budget enforced, the loop advances on stuck iterations
- **Operator-gated for risk**: actions named in the constitution as `auto_fire: false` cannot land without explicit operator approval
- **Budget-respecting**: daily token budget enforced; soft warn at 80%, hard halt at 100%
- **Receipt-emitting**: every iteration leaves a verifiable artifact
- **LLM-agnostic**: swap models by editing the `llm_call` function
- **Box-portable**: the same framework runs on a Mac mini, a Windows Surface (via WSL or PowerShell port), or a Linux VPS

## What the framework does not do

- **Multi-box coordination.** Boxes share via git memory + Telegram operator + receipts.
- **Auto-merge of PRs.** The operator approval is the gate. YC's example uses an agent reviewer; we do not have that maturity yet, so a human gate is right.
- **Hallway-conversation capture.** The loop only consumes already-legible artifacts. Capturing meatspace conversations is upstream of this framework.
- **Replace your CI / observability stack.** The loop produces receipts; your existing observability stack consumes them.

## Companion patterns in this kit

- [[Self-Improving Fleet Loop]]: the discipline this framework implements
- [[Announce Intent Before Action]]: the discipline the receipt format mirrors
- [[Where the Kit Fits]]: the five-control-point map; ADOTOB Loop lives on the observability + learning rows

## Status

**v0.1 (spec + skeleton).** the runtime loop, the constitution schema, the prompt template, and the README are in place. **The sensors, actions, and llm_call wiring are intentionally stub-shaped pending the first dogfood deployment on the MACONA OpenClaw fleet (Surface .57).** Once stable on MACONA, the reference sensors and actions ship as `examples/` for partners.

If you want to try the framework on your own fleet before we ship `examples/`, the four hooks you must write are:

1. `sensors/collect.sh` (writes the iteration's sensor JSON)
2. `actions/update_memory.sh`, `actions/open_pr.sh`, `actions/escalate.sh`, `actions/noop.sh`
3. The `llm_call` shell function in `.env` or your shell init
4. Your `constitution.yml`

## Why open-source

Two reasons:

1. **Prior-art establishment.** The framework names a discipline that does not yet have a canonical implementation. Publishing it under Apache 2.0 plants the flag and invites contributors.
2. **The framework is not the moat.** The moat is the per-box constitution, the sensor wiring, and the action implementations tuned to a partner's specific fleet. The runtime engine is generic; the deployment is bespoke. Same separation as Linux kernel vs your `/etc/`.

## Credits

- **Y Combinator + Diana Hu**: the 5-stage agentic loop framing the runtime implements (2026 talks + earlier framing)
- **Jack Dorsey**: the tweet thread on recursive AI loops that the YC talk credits
- **Geoffrey Huntley**: the original Ralph Wiggum loop pattern, whose `while :` simplicity this framework preserves
- **Fabian Williams + Adotob Solutions**: the runtime evolution for consumer-tier always-on fleets, the SLA-backronym naming, and the first dogfood deployment

## License

Apache 2.0. Fork, modify, ship inside your product, attribute or do not. The framework is generic on purpose.
