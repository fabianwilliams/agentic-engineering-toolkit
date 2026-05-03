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
| [`agents`](./agents) | 🟡 placeholder | Reference patterns for small autonomous-agent fleets. Coming soon. |
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
