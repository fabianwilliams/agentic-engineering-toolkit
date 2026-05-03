# Modelfiles — placeholder

Modelfile overlays tuned for specific Apple Silicon workloads.

Coming soon:

- **`apple-silicon-overlays/`** — strict-mode overlays for structured-output workloads (temp 0.2, thinking off where supported), creative-mode overlays (temp 0.7+, thinking on for reasoning-heavy tasks), and per-model tuning for the Qwen3.6 / gpt-oss / Llama families.

Modelfile overlays are disk-free thanks to Ollama's content-addressable layer storage — you can have ten variants of the same base model and only pay for the base model once on disk. If you have not used `FROM` overlays before, they are one of the most underused features of Ollama.

Status: 🟡 not yet published.
