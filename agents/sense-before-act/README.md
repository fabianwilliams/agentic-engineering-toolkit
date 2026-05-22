# Sense Before Act

> A discipline of the Agent Reliability Kit. Pairs with `announce-intent-before-action`.

---

> **By the end of this doc you will know what an agent must produce BEFORE it decides anything, so the agent's later actions can be trusted as grounded in real state instead of invented around gaps. `announce-intent-before-action` makes the action half legible. `sense-before-act` makes the observation half legible. Both are required.**

---

## The discipline

When an agent runs an iteration, the agent must FIRST emit a structured snapshot of what it observed about the world, BEFORE choosing a policy or firing any tool. Four artifacts are required per iteration. No artifact is optional. A sensor that returned nothing is still recorded as "checked, returned nothing." A sensor that errored is still recorded as "checked, errored, reason." Silent omission of any sensor is forbidden.

The two halves of the agent's per-iteration arc:

| Half | Artifact | Question it answers |
|------|----------|---------------------|
| **Before action** | Four sensing artifacts (this discipline) | "What does the agent know right now, and where are the gaps?" |
| **At action** | Tool description with enumerated side effects (`announce-intent-before-action`) | "What is the agent about to do on my behalf?" |

Together, the agent's per-iteration arc is: observe with named gaps, declare intent with enumerated side effects, fire the tool, write the receipt. Each half answers a question the operator (or downstream auditor) needs to answer to trust the loop.

## Why this exists

Agents on consumer-tier hardware now run long-horizon work over multiple sources of state. Sensors disagree. Files go missing. Two different reports double-count the same event. Without a forced grounding step, the language model smooths over the mess and produces confident, plausible-shaped outputs that are wrong in ways the operator cannot easily spot.

The failure mode is structural, not a model defect. No prompt instruction prevents it. The only defense is to require the agent to PRODUCE the grounding before policy runs, so the gaps are legible to the operator BEFORE the agent commits to a decision.

This is the runtime form of a discipline the broader practitioner community has been converging on for human-AI collaboration in 2026 (operator podcasts, working-in-public engineers, and product writing have all named related patterns at the human-knowledge-work layer). At the human layer the artifacts are read before drafting. At the agent-runtime layer the artifacts are emitted every iteration, because humans cannot inspect every iteration. Same discipline, two layers.

## The four required artifacts

Each iteration of an agent loop following this discipline must produce all four. Names below are the canonical names used inside the Agent Reliability Kit.

### 1. Sensor Roll Call

Every sensor that was called this iteration, with timestamp, return shape, and outcome.

```json
{
  "sensor_roll_call": {
    "iter_id": "iter_20260522_125600",
    "started_at": "2026-05-22T12:56:00Z",
    "sensors": [
      { "name": "telegram",       "status": "ok",        "items": 0,  "duration_ms": 412 },
      { "name": "brevo_smtp",     "status": "ok",        "items": 17, "duration_ms": 980 },
      { "name": "daily_summary",  "status": "not_found", "items": 0,  "duration_ms": 14 },
      { "name": "rca_files",      "status": "ok",        "items": 2,  "duration_ms": 31 },
      { "name": "openclaw_jobs",  "status": "not_found", "items": 0,  "duration_ms": 8 }
    ]
  }
}
```

Rule: every sensor that the constitution declares as enabled MUST appear in the roll call, even if its status is `not_found` or `errored`. Silent omission of a sensor is a discipline violation that the quality gate must reject.

### 2. Conflict Receipt

Every place where two sensors (or two records from one sensor) disagreed about the same underlying fact, with the policy's resolution.

```json
{
  "conflict_receipt": {
    "iter_id": "iter_20260522_125600",
    "conflicts": [
      {
        "fact": "last_send_to_dr_uzo",
        "sensor_a": { "name": "brevo_smtp",   "value": "2026-05-20T14:11:00Z" },
        "sensor_b": { "name": "rca_files",    "value": "2026-05-19" },
        "resolution": "trust_sensor_a",
        "reason": "brevo_smtp has wall-clock timestamps; rca_files uses calendar date and lags by up to 24h"
      }
    ]
  }
}
```

Rule: if there are no conflicts, the receipt is still emitted with `"conflicts": []`. Empty is a valid state; missing is not. The discipline is "we looked for conflicts and here is what we found," not "we did not see any conflicts so we wrote nothing."

### 3. Gap Map

Every `not_found`, every sensor error, every piece of state the agent decided not to check. The gap map is the agent's confession of what it does NOT know this iteration.

```json
{
  "gap_map": {
    "iter_id": "iter_20260522_125600",
    "gaps": [
      {
        "field": "daily_summary",
        "kind": "not_found",
        "what_we_would_know_if_present": "cron-reasoned end-of-day rollup for prior day",
        "policy_compensation": "downgrade confidence on any inference that depends on prior-day rollup"
      },
      {
        "field": "openclaw_jobs",
        "kind": "not_found",
        "what_we_would_know_if_present": "current scheduled job registry snapshot",
        "policy_compensation": "skip any reasoning about jobs.json drift this iteration"
      }
    ]
  }
}
```

Rule: every gap must name what would be known if the gap were filled, AND how the policy stage compensates. A gap without a named compensation is a discipline violation; the policy is then guessing in the dark.

### 4. Cross-Source Dedup

Every fact that appeared in two or more sensor outputs, with the dedup decision. Two sensors observing the same event is one piece of evidence, not two. Counting it twice biases the policy stage.

```json
{
  "cross_source_dedup": {
    "iter_id": "iter_20260522_125600",
    "dedup_decisions": [
      {
        "fact": "telegram_alert_brevo_bounce_2026_05_22_0712",
        "seen_in": ["telegram", "brevo_smtp"],
        "treated_as": "1x_evidence",
        "primary_source": "brevo_smtp",
        "reason": "brevo_smtp is the originator; telegram is a forwarded copy"
      }
    ]
  }
}
```

Rule: when the same underlying event appears in N sensors, the policy stage MUST receive it as one event with a `seen_in` list, never as N independent events. Failure to dedup inflates evidence weight on whatever the duplicated source happens to repeat most often.

## What you do with the four artifacts

The four artifacts feed forward into the agent's policy stage as a single bundled grounding object. The policy stage receives this bundle and uses it to decide which action to take (in the Adotob 5-stage loop: `noop`, `escalate`, `update_memory`, `open_pr`).

The policy stage MUST NOT see raw sensor output without the four artifacts wrapping it. The artifacts are the schema; raw sensor output is the input from which they are derived.

The quality gate stage (stage 4 of the loop) validates the receipt against this discipline. Receipts that omit any of the four artifacts, or that emit them with shape violations, are rejected at quality-gate time and the iteration is aborted before action.

## Why the four are exactly these four

Each artifact answers a specific failure question that long-horizon agent work tends to fail on:

| Artifact | Failure it prevents | What happens without it |
|----------|---------------------|-------------------------|
| Sensor Roll Call | Silent sensor failure | Agent acts as if a sensor returned clean data when in fact it errored |
| Conflict Receipt | Smoothing over disagreement | Agent picks one source arbitrarily, hides that the other source disagreed |
| Gap Map | Inventing around missing data | Agent confabulates plausible content to fill a hole |
| Cross-Source Dedup | Double-counting evidence | Policy stage over-weights whatever happens to be duplicated |

Three artifacts catch most cases; four catch the realistic span. Fewer than four leaves a known hole; more than four adds ceremony without adding coverage.

## Lineage and convergence

Adotob arrived at this discipline by running multi-agent fleets in production. The 5-stage Self-Improving Fleet Loop was named 2026-05-21; ADOTOB Loop deployed the same evening with all four artifacts built into every iteration receipt. The broader practitioner community is converging on related ideas for human-AI collaboration (visible across the operator podcasts and working-in-public writing of 2026). We ship the engine that runs the same discipline for agents at runtime, where humans cannot inspect every iteration. The vocabulary in this kit is ours.

The principle that prompts cannot enforce truth (no instruction prevents structural failure modes; only structural grounding prevents them) is shared across the convergent thinking. The agent-runtime application is where Adotob lives.

## Live reference

The closest live implementation is ADOTOB Loop running on the MACONA OpenClaw box. The current v0.1 iteration receipts contain the data the four artifacts call for (sensor results with status, the LLM's proposal, the operator-facing summary) inside a consolidated `proposal.json` + `receipt.json` pair. Lifting that consolidated data into four explicitly named files matching the schemas above is the next implementation milestone for the reference runtime:

```
adotob-loop/receipts/iter_<id>/
  sensor_roll_call.json     # planned, currently embedded inside receipt.json
  conflict_receipt.json     # planned, currently absent (no conflict-detection layer yet)
  gap_map.json              # planned, currently inferable from sensor "not_found" returns
  cross_source_dedup.json   # planned, currently absent (no dedup layer yet)
  proposal.json             # exists
  receipt.json              # exists
```

A runtime fully compliant with this discipline emits all four artifacts explicitly. ADOTOB Loop will reach that state in v0.2. Treat the schemas in the previous section as the target; treat the current receipts as v0.1 partial compliance. The discipline doc is the source of truth for what an aligned runtime looks like.

## When this discipline does NOT apply

- Single-shot scripts that read one source and write one output. No grounding step needed; the source is the grounding.
- Tightly bounded mechanical tasks (rename a variable, format a file). The four artifacts would be ceremony.
- Pure inference calls where the agent has zero state to ground in. The grounding is the prompt itself.

## When this discipline IS load-bearing

- Multi-sensor long-running agents (any agent that polls more than one source per iteration)
- High-stakes outputs (anything that goes to external recipients, ships money, modifies durable state)
- Multi-hour or multi-iteration runs where one bad ground-state cascades into many bad actions
- Any time the operator wants to be able to audit "what did the agent see when it made that call"

## Pairs with

- `announce-intent-before-action`: the action half of the same per-iteration arc; mandatory companion
- `self-improving-fleet-loop`: names the 5 stages; this discipline lives at stage 1
- `adotob-loop`: the reference runtime that produces the four artifacts every iteration

## What this discipline is NOT

- NOT a substitute for the action-side discipline (you need both halves)
- NOT a substitute for human review of high-risk actions (the operator-gated actions in `announce-intent-before-action` still apply)
- NOT a prompt instruction (instructions to "be careful about sources" do not produce these artifacts; the runtime must emit them as code)
- NOT optional for production runtimes (a runtime that skips any of the four is failing the discipline regardless of how the iteration looks)

## License

Apache 2.0, as with all Agent Reliability Kit disciplines. Use the names, use the schemas, port them to your own runtime. Attribution to the Agent Reliability Kit is appreciated but not required.

---

_Companion: [announce-intent-before-action](../announce-intent-before-action/README.md). Engine: [adotob-loop](../adotob-loop/README.md). Discipline: [self-improving-fleet-loop](../self-improving-fleet-loop/README.md)._
