# ADOTOB Loop: Actions

> Four named action scripts, one per action type. The loop's stage 5 routes the LLM's proposal to one of these.

## The four named actions

Every iteration ends in exactly one of these. The constitution's `auto_fire` field controls whether the action runs unattended or requires operator approval.

| Action | Auto-fire default | What it does |
|---|---|---|
| `actions/update_memory.sh` | `false` (always operator-gated) | Drafts a `feedback_*.md` rule or update. Posts the diff to the operator. Awaits one-click approval. |
| `actions/open_pr.sh` | `false` (always operator-gated) | Writes the code change, pushes to a feature branch, opens a draft PR with the iteration receipt linked. |
| `actions/escalate.sh` | `true` (the escalation IS the action) | Sends a structured Telegram message to the operator with the choice framed. |
| `actions/noop.sh` | `true` | Logs the decision explicitly. Does nothing else. |

## Invocation contract

The loop calls each action script as:

```bash
bash actions/<action>.sh <path-to-proposal.json>
```

The proposal JSON shape is documented in `learning/prompt.md`. The action script reads the proposal, performs its work, and exits zero on success. Non-zero exits land in the iteration receipt as `action_failed`.

## Per-action contract

### `actions/update_memory.sh`

Inputs:
- `$1` = path to the proposal JSON. `proposed_diff` field contains the new memory file content or unified diff against an existing memory file.

Behavior:
- Resolve the target memory file path (from the proposal or by inference).
- Compute the diff against the current file state.
- Post the diff to the operator via the constitution's `approval_channel` (typically Telegram).
- Wait for an approval reply or time out per the constitution's `operator_approval.expiry_after_hours`.
- On approval: write the new content to disk; commit on the operator's auto-memory git location (or stage for the next session).
- On timeout / decline: log to the iteration receipt; do not apply.

The script must never auto-apply a memory edit. The approval step is binding.

### `actions/open_pr.sh`

Inputs:
- `$1` = path to the proposal JSON. `proposed_diff` field contains either a unified diff or file/content pairs.

Behavior:
- Create a feature branch off the configured default repo (constitution's `actions.open_pr.default_repo`).
- Apply the proposed diff.
- Push the branch.
- Open a **draft** PR with the iteration receipt linked in the body.
- Post the PR URL to the operator's approval channel.

The operator merges via the GitHub UI. The script does not auto-merge under any circumstance.

### `actions/escalate.sh`

Inputs:
- `$1` = path to the proposal JSON. `escalation` field contains `{ summary, recommended_next, operator_choice }`.

Behavior:
- Format the escalation as a single Telegram message (or your chosen approval channel).
- Send it. Do not wait for response (escalation is fire-and-forget; the operator responds when ready).
- Log the message ID / send timestamp to the iteration receipt.

If the constitution names the incident category in `escalate_immediately`, the loop's stage 4 already routes here automatically. This script just handles the messaging.

### `actions/noop.sh`

Inputs:
- `$1` = path to the proposal JSON.

Behavior:
- Read the `rationale` field and append a line to a noop log file (`receipts/noop_log.txt`).
- That is the entire action.

A no-op is explicit, not silent. The operator can grep the noop log to spot patterns (e.g. "the loop has done nothing for 48 iterations; do we have a sensor problem?").

## Reference implementation status

Stub-shaped pending the first dogfood deployment on the MACONA OpenClaw fleet. Once stable on MACONA, the reference actions ship as `examples/` for partners.

## Security notes for action authors

- **Never include secrets in PR diffs.** The `actions/open_pr.sh` script must scrub any secret-looking string before pushing. If your diff touches a config file with a key in it, abort the action and log to receipt instead.
- **Sign the PR commit.** Configure `git config commit.gpgsign true` on the box and verify on first run.
- **Branch-protect main.** The operator's default repo must have branch protection on main that requires PR approval; this script does not enforce that, your GitHub configuration does.
- **Restrict the bot identity.** The Telegram bot used for approvals must accept commands only from the operator's verified chat ID. The script must verify the chat ID on every received reply.

These are operator-deployment responsibilities. The framework names them; it does not enforce them.
