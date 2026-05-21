# ADOTOB Loop: Sensors

> One bash entrypoint (`collect.sh`) that aggregates per-source sensors into a single JSON file consumed by the loop's learning stage.

## Convention

The loop calls `bash sensors/collect.sh <output_json_path>` with a wall-time budget. Your `collect.sh` orchestrates the per-source sensor scripts in this folder and writes a single JSON object to `<output_json_path>`. That JSON is what the LLM sees on every iteration.

The JSON should be a flat object (or shallow-nested object) keyed by sensor source. Example shape:

```json
{
  "collected_at": "2026-05-21T22:00:00Z",
  "telegram": {
    "channel": "MaconaOps",
    "since": "2026-05-20T22:00:00Z",
    "messages": [
      {"at": "...", "type": "summary", "text": "..."},
      {"at": "...", "type": "incident", "text": "..."}
    ]
  },
  "brevo": {
    "since": "2026-05-20T22:00:00Z",
    "bounces": 0,
    "spam_complaints": 0,
    "opens": 12,
    "clicks": 3,
    "details": [...]
  },
  "rca_files_new_today": [
    "tasks/macona/RCAs/2026-05-21-eshe-tag-extraction-fail.md"
  ],
  "daily_summary_today": "tasks/macona/2026-05-21-cron-reasoned-summary.md",
  "openclaw_jobs_last_24h": {
    "total_runs": 18,
    "successful": 17,
    "failed": 1,
    "failure_details": [...]
  }
}
```

The exact keys are partner-specific; the loop does not enforce a schema. The learning prompt does suggest evidence-path conventions (e.g. `sensor.json#brevo.bounces`) so referenced fields must be reachable via dotted-path traversal.

## Reference sensors (write your own)

| Sensor script | What it pulls |
|---|---|
| `sensors/telegram.sh` | Last N hours of operator-channel messages via the Telegram Bot API |
| `sensors/brevo.sh` | Bounces / spam complaints / opens / clicks since last iteration via the Brevo SMTP statistics API |
| `sensors/rca_files.sh` | New files in `tasks/<box>/RCAs/` matching `*.md` since the last iteration |
| `sensors/daily_summary.sh` | The cron-reasoned daily summary file for today (read-only) |
| `sensors/openclaw_jobs.sh` | jobs.json + recent action receipts from the box's agent runtime |
| `sensors/git_diff.sh` | New commits on main since last iteration, for memory updates that may have arrived from another box |

These are not shipped in this folder. They are deployment-specific. The framework intentionally avoids prescribing how to talk to your Telegram bot, your Brevo tenant, your OpenClaw fleet, etc.

## Constraints on collect.sh

- **Exit non-zero on hard failure.** The loop treats a non-zero exit as a sensor failure and short-circuits the iteration (no LLM call). Hard failures = network down, API key invalid, disk full. Soft failures (empty results, partial data) should exit zero and produce a JSON that reflects the partial state.
- **Stay under the wall-time budget.** The loop enforces `ADOTOB_WALL_TIME_BUDGET_SEC`. If your `collect.sh` is slow, parallelize the per-source calls (`&` + `wait`) or split into multiple short scripts.
- **Never block on operator input.** The sensor stage is fully autonomous. If a sensor needs operator input, that is a constitution-level concern, not a sensor concern.
- **Never write secrets into the output JSON.** API keys, tokens, passwords must never appear in `sensor.json`. Use IDs or hashes when referring to credentials.

## Reference implementation status

Stub-shaped pending the first dogfood deployment on the MACONA OpenClaw fleet. Once stable on MACONA, the reference sensors will ship as `examples/` for partners.

If you want to try the framework on your own fleet before then, write your own `collect.sh` against the JSON shape above and the constraints in this doc.
