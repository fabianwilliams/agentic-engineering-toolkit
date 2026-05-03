# Hardware

Every benchmark and pattern in this repo was developed and validated on the dev machine documented below. If you are reproducing results, your hardware will affect the numbers — sometimes by a factor of 2-5x. Reading this once will save you from comparing apples to peanuts.

## The dev machine

| Spec | Value |
|---|---|
| Model | MacBook Pro 16-inch (M3 Max, 2023) |
| CPU | Apple M3 Max — 16-core (12 performance + 4 efficiency) |
| GPU | Apple M3 Max — **40-core integrated GPU** |
| Unified memory | **128 GB** |
| Storage | NVMe (configuration-dependent) |
| OS | macOS Sequoia 15.x |
| Inference runtime | [Ollama](https://ollama.com) 0.17.x (Metal backend) |

Three things matter most for the benchmark numbers in this repo:

1. **128 GB of unified memory.** Lets the full model weights stay resident in GPU-accessible memory without paging. A 70 GB gpt-oss:120b model fits with room to spare. Smaller-RAM Macs (16-32 GB) will not be able to hold these models and will swap, often catastrophically. If you are running on 16-32 GB, you need different (smaller) models, not different scripts.
2. **40-core GPU.** This is what does the inference work. CPU near-idle, GPU pinned at 100% — that is the expected state for any model loaded into Metal. Verify with `ollama ps` while a model is hot:
   ```
   NAME                    ID              SIZE     PROCESSOR    CONTEXT
   qwen3.6:35b-a3b-q8_0    0218f872e86b    44 GB    100% GPU     131072
   ```
   If `PROCESSOR` shows anything other than 100% GPU, the model is falling back to CPU and your wall times will be much worse than mine.
3. **NVFP4 quantization on Metal works.** I was skeptical going in — NVFP4 is NVIDIA's FP4 format and Metal has no native FP4 support. Empirically, the qwen3.6:35b-a3b-coding-nvfp4 variant runs at 100% GPU utilization on this machine and outperforms Q8 alternatives at smaller resident size. Whatever Ollama is doing under the hood handles this fine on Apple Silicon.

## What this hardware costs

Roughly $4,500–5,000 (configuration-dependent) when purchased late 2023 / early 2024. Less than a year of cloud inference for an active agent workload at frontier-API rates. The fixed-cost flip is the entire economic argument behind owning the hardware vs. renting cloud inference.

## What this hardware is NOT

- **Not the production hardware** for the OpenClaw three-box agent fleet I run. That is a separate cluster of Mac mini / Surface Laptop class machines (~16 GB unified RAM, no dedicated GPU). Those boxes can NOT run the models in this repo at speed — they call frontier-cloud APIs for the agent workloads. The dev machine documented here is where benchmarks and toolkit work is done; production inference for the regulated-buyer market is a separate architecture problem (see the blog post linked below).
- **Not the only platform this should work on.** The Bash scripts assume Bash 3.2+, awk, and Ollama on the host PATH. They should run on Linux with an NVIDIA GPU + Ollama, and on Apple Silicon Macs with similar memory profiles. I have not tested on those, so the numbers will differ.

## Why the spec matters for reproducibility

If your numbers differ from what this repo's READMEs claim, check in this order:

1. Are you on Apple Silicon? (Different Metal driver, different speed.)
2. How much unified memory? (< 64 GB will struggle with anything 70B+ in Q8.)
3. How many GPU cores? (8-core, 16-core, 30-core, 40-core, 76-core all exist in M-series — bigger = faster, with diminishing returns past ~40-core for these models.)
4. Is Ollama actually using the GPU? (Run `ollama ps` mid-inference and verify 100% GPU.)
5. What Ollama version? (0.17.x as of these benchmarks — newer may differ.)

## Related context

- [Replacing gpt-oss:120b With Qwen3.6 on a MacBook Pro](https://www.fabswill.com/blog/replacing-gpt-oss-with-qwen3-6-on-macbook-pro/) — the long-form blog post that produced the numbers in this repo.
- [r/ollama discussion](https://www.reddit.com/r/ollama/comments/1t27p6s/) where the spec question was raised, if you want to see the original conversation.
