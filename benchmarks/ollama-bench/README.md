# ollama-bench

A Bash benchmark runner for local LLM stacks on Ollama. Built while benchmarking Qwen3.6 against gpt-oss:120b on a MacBook Pro M3 Max — the script is the same one I used to produce [these numbers](https://www.fabswill.com/blog/replacing-gpt-oss-with-qwen3-6-on-macbook-pro/).

## What it does

Given a prompt file and a list of model names, the script:

1. **Creates a strict Modelfile overlay** for each model at temperature 0.2 — disk-free thanks to Ollama's content-addressable layer storage.
2. **Runs each strict variant against the prompt** with `--think=false` and times the wall clock.
3. **Strips thinking-trace bleed** if it appears in the output (some models, notably gpt-oss, ignore `--think=false` and dump their reasoning to stdout). The script detects the `...done thinking.` marker via `awk` and discards everything before it.
4. **Saves each model's output** to a separate file in the configured output directory.
5. **Prints a timing summary** at the end so you can compare wall-clock performance across the full set in one glance.

Three minutes of work tells you which model gives the best speed-quality balance for your actual workload, on your actual hardware, without trusting anyone else's marketing numbers.

## Why it exists

Hello-world tests do not tell you what you need to know about local LLMs. The actual differences between models — speed, output discipline, hedge preservation, format adherence — only show up when you run a real workload through real output constraints.

This script gives you the reproducible-test infrastructure to do that comparison on your own hardware. The companion prompt at [`../prompts/sdr-research-brief.md`](../prompts/sdr-research-brief.md) is the structured-output workload I used; you can substitute your own.

## Requirements

- macOS or Linux with Bash 3.2+ (works on stock macOS bash)
- [Ollama](https://ollama.com) 0.17+ installed and running
- The models you want to benchmark already pulled (`ollama pull MODEL` for each)
- `awk`, `grep`, `cat`, `time` — standard Unix utilities

## Quick start

```bash
# Pull whatever models you want to compare
ollama pull qwen3.6:35b-a3b-q8_0
ollama pull gpt-oss:120b

# Run the benchmark
./run-benchmark.sh ../prompts/sdr-research-brief.md \
  qwen3.6:35b-a3b-q8_0 \
  gpt-oss:120b
```

The script defaults the output directory to `/tmp/ollama-bench-out`. Set `OUT_DIR=./my-outputs` to point somewhere else. Set `TEMP=0.4` to override the default temperature.

## Example output

```
=== Creating Modelfile overlays (temp 0.2) ===
Creating qwen3.6-35b-a3b-q8_0-strict <- qwen3.6:35b-a3b-q8_0
success
Creating gpt-oss-120b-strict <- gpt-oss:120b
success

=== Running benchmark on 2 model(s) ===

--- qwen3.6-35b-a3b-q8_0-strict ---
Wall time: 22s (clean stream)
Output:    /tmp/ollama-bench-out/qwen3.6-35b-a3b-q8_0-strict-out.md

--- gpt-oss-120b-strict ---
Wall time: 61s (thinking trace stripped)
Output:    /tmp/ollama-bench-out/gpt-oss-120b-strict-out.md

=== Timing Summary ===
Model                            Wall time
-----                            ---------
qwen3.6:35b-a3b-q8_0-strict      22s
gpt-oss:120b-strict              61s
```

## How to grade the outputs

Speed is one axis. There are at least four others worth grading on for any structured-output workload:

1. **Format adherence** — does the output match the exact format you asked for (headers, word caps, bullet counts)?
2. **Source faithfulness** — does the model invent facts that were not in the input? Plant a "thin information" detail in the prompt and see if the model fabricates context for it.
3. **Hedge preservation** — does the model carry forward source uncertainty ("unverified", "reportedly", "authenticity unconfirmed")? Watch especially for hedges that survive in the analytical sections but disappear in customer-facing copy.
4. **Synthesis quality** — does the model connect a high-signal pain pattern across multiple inputs and surface it in the output? Plant a multi-input pain signal in the prompt and see whether each model picks it up.

The `sdr-research-brief.md` prompt has three quiet traps planted for exactly these axes. The longer-form grading rubric is one of the things I will eventually publish in the eStore methodology PDF.

## Known limitations

- **Not all models honor `--think=false`.** Qwen3.x family does. gpt-oss does not in current Ollama versions; the script's awk strip handles the bleed. If you find a model that produces neither a clean stream nor a `...done thinking.` marker, the strip will not work and you will need to write your own filter.
- **Modelfile parameter coverage.** The strict overlay only sets `temperature`. If you want to benchmark with different `top_p`, `top_k`, `num_ctx`, etc., edit the heredoc in `run-benchmark.sh`.
- **No GPU verification.** The script assumes you have already confirmed Ollama is running on the GPU (use `ollama ps` while a model is loaded to check `PROCESSOR  100% GPU`). If your stack is falling back to CPU, the wall-time numbers tell you nothing useful.
- **Apple Silicon emphasis.** Tested on a MacBook Pro M3 Max with 128 GB unified memory. Should work on any Ollama-supported platform but I have not run it elsewhere.

## License

Apache 2.0. See the repo root [LICENSE](../../LICENSE).
