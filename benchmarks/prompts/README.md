# Benchmark prompts

Real prompts I have used to benchmark structured-output workloads. Each prompt is designed to surface multiple axes of model behavior — speed, format adherence, source faithfulness, hedge preservation, synthesis quality — so a single run gives you signal on all of them at once.

## Available prompts

| Prompt | Workload | Status |
|---|---|---|
| [`sdr-research-brief.md`](./sdr-research-brief.md) | B2B prospect research dump (~1500 words) → 350-word structured outreach brief, with three planted traps for hallucination, hedge-preservation, and synthesis | ✅ tested |

More prompts coming as I run more benchmarks. If you want a specific workload class added, file an issue.

## How the prompts are designed

Each prompt has at least three quiet traps planted in the input that distinguish good from bad model behavior:

1. **A thin-information detail** — a name or fact mentioned with minimal context, to test whether the model invents scope around it.
2. **A hedged claim** — something explicitly marked "unverified" or "authenticity unconfirmed" in the source, to test whether the model carries the hedge through to customer-facing copy.
3. **A multi-input pain pattern** — a high-signal observation that requires synthesizing 2-3 separate inputs, to test whether the model surfaces the connection.

You will not see the traps unless you read the prompt with that frame in mind. That is intentional — the model should not see them either, but a model that handles structured-output well will navigate them correctly without being told they are there.
