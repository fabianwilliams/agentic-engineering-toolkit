# Agentic Engineering Toolkit

```
╭───────────────────────────────────────────────╮
│                                               │
│   AGENTIC  ENGINEERING  TOOLKIT               │
│                                               │
│   tools · prompts · patterns                  │
│   for real local-AI workloads                 │
│                                               │
│   fabswill.com  ·  Apache 2.0                 │
│                                               │
╰───────────────────────────────────────────────╯
```

Tools, prompts, and patterns I use when building real local-AI workloads. Verified on my own hardware before they show up here. Apache 2.0, no roadmap, no announcements — I add things as I ship them.

If you found this through one of my blog posts, a Reddit thread, or just by searching, welcome. Star or watch if you want updates; the repo grows when there is something worth adding, not on a schedule.

> **Reproducing the benchmarks?** The numbers in this repo's READMEs were produced on a specific machine — MacBook Pro M3 Max, 128 GB unified memory, **40-core GPU**, Ollama 0.17.x on Metal. If your hardware differs, your numbers will differ. See [HARDWARE.md](./HARDWARE.md) for the full dev-machine spec, the production-vs-dev architecture, and the verification steps to confirm Ollama is actually running on GPU.

## What is here

| Folder | Status | What it is |
|---|---|---|
| [`benchmarks/ollama-bench`](./benchmarks/ollama-bench) | ✅ working | Bash benchmark runner for local LLM stacks. Modelfile overlays, thinking-trace strip, timing summary. |
| [`benchmarks/prompts`](./benchmarks/prompts) | ✅ 1 prompt | Real benchmark prompts for structured-output workloads. Start with `sdr-research-brief.md`. |
| [`obsidian-claude-second-brain`](./obsidian-claude-second-brain) | ✅ working | Karpathy-pattern second brain on Obsidian + Claude Code. Four skills (`/yt-transcript`, `/ingest-transcript`, `/wiki-compile`, `/wiki-lint`) plus a knowledge-pipeline directory template. Companion to [the blog post](https://fabswill.com/blog/building-a-second-brain-that-compounds-karpathy-obsidian-claude/). |
| [`demos/mcp-storefront`](./demos/mcp-storefront) | ✅ live | Public MCP-callable storefront. Two worked examples — hosted Claude AND fully local Qwen3.6 27B — produce the same audit-trail receipt from the same endpoint. Full source at [`fabianwilliams/adotob-mcp`](https://github.com/fabianwilliams/adotob-mcp). |
| [`agents/announce-intent-before-action`](./agents/announce-intent-before-action) | ✅ v1 | Reliability Kit discipline. The matched pair to the audit-trail receipt: agent tools must enumerate every server-side effect *before* the human approves the call. Lineage traced from Caitlin Kalinowski (Lenny's podcast 2026-05-17), Pixar's announce-then-act, Stanislavski's telegraphing. |
| [`agents/sense-before-act`](./agents/sense-before-act) | ✅ v1 | Reliability Kit discipline. The observation half of every agent iteration: four required artifacts (Sensor Roll Call, Conflict Receipt, Gap Map, Cross-Source Dedup) the agent must emit before the policy stage runs. Pairs with `announce-intent-before-action` as the matched before/at-action primitives. Convergent with the human-knowledge-work patterns surfacing across operator writing in 2026; applied at agent runtime where humans cannot inspect every iteration. |
| [`agents/where-the-kit-fits`](./agents/where-the-kit-fits) | ✅ v1 | Architectural map. Positions the Kit as the **observability control point** that pairs with Cloudflare / AWS Bedrock / Auth0 / Snowflake instead of competing with them. Uses a five-control-point lens (runtime, identity, data, tool-write, observability) for partner conversations. |
| [`agents/self-improving-fleet-loop`](./agents/self-improving-fleet-loop) | ✅ v1 | The 5-stage agentic loop (sensor → policy → tool → quality gate → learning) applied to a small autonomous-agent fleet on consumer-tier hardware. Names the gap most fleets stall on (the learning stage) and the discipline that closes it. |
| [`agents/adotob-loop`](./agents/adotob-loop) | 🟡 v0.1 spec + skeleton | **Always On, Time On, Budget.** A constitutional bash-loop runtime that implements the self-improving-fleet-loop discipline. Ships the loop runtime, constitution schema, learning-agent prompt, and operator-approval surface. Sensor / action wiring is per-deployment. Apache 2.0. First dogfood: MACONA. |
| [`agents`](./agents) | 🟡 placeholder | More reference patterns for small autonomous-agent fleets. Coming soon. |
| [`modelfiles`](./modelfiles) | 🟡 placeholder | Modelfile overlays tuned for Apple Silicon workloads. Coming soon. |
| [`corpus`](./corpus) | 🟡 placeholder | Tools for capturing and analyzing your own public posts and reception data. Coming soon. |
| [`methodology`](./methodology) | 🟡 placeholder | Longer-form methodology PDFs. Premium versions live at [estore.adotob.com](https://estore.adotob.com/store). |

## What this is not

- A framework. There is no abstraction layer here, no plugin API, no opinionated stack you have to adopt.
- A course. There is no narrative arc, no "lesson 1 of 12."
- A product. The free pieces will always be free. The premium PDFs in the eStore are an upgrade, not a paywall on the working code.

Each folder is self-contained. Read the folder's README, copy the script, run it on your hardware. If you want the long-form methodology behind a piece, that is what the eStore link is for.

## Author

[Fabian Williams](https://fabswill.com) — building in public from a MacBook Pro M3 Max in suburban Maryland. Day job is product management at Microsoft. Nights and weekends are local AI, the OpenClaw three-box agent fleet, and writing about both.

- Blog: <https://fabswill.com>
- Reddit: u/AIForOver50Plus

## License

Apache 2.0. Use it commercially, fork it, modify it, ship it inside your own product. Attribution appreciated but not required.
