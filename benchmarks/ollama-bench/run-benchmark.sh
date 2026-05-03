#!/bin/bash
# ollama-bench: structured-output benchmark runner for local LLM stacks
#
# Given a prompt file and a list of model names, this script:
#   1. Creates a strict Modelfile overlay for each model at temperature $TEMP
#      (default 0.2). Disk-free thanks to Ollama's content-addressable layers.
#   2. Runs each strict variant against the prompt with --think=false and
#      times the wall clock.
#   3. Strips thinking-trace bleed if it appears in the output (some models
#      ignore --think=false and dump reasoning to stdout). Detects the
#      "...done thinking." marker and discards everything before it.
#   4. Saves each model's output to a separate file in OUT_DIR.
#   5. Prints a timing summary across the full set.
#
# Usage: ./run-benchmark.sh PROMPT_FILE MODEL [MODEL ...]
# Example: ./run-benchmark.sh ../prompts/sdr-research-brief.md \
#            qwen3.6:35b-a3b-q8_0 gpt-oss:120b
#
# Environment variables:
#   TEMP        Temperature for strict overlays (default: 0.2)
#   OUT_DIR     Output directory (default: /tmp/ollama-bench-out)
#
# Tested on macOS with stock bash 3.2+ and Ollama 0.17+.
# Apache 2.0 — github.com/fabianwilliams/agentic-engineering-toolkit

set -e

if [ "$#" -lt 2 ]; then
  cat <<EOF
Usage: $0 PROMPT_FILE MODEL [MODEL ...]

Example:
  $0 ../prompts/sdr-research-brief.md qwen3.6:35b-a3b-q8_0 gpt-oss:120b

Environment variables:
  TEMP        Temperature for strict overlays (default: 0.2)
  OUT_DIR     Output directory (default: /tmp/ollama-bench-out)
EOF
  exit 1
fi

PROMPT_FILE="$1"
shift
MODELS=("$@")
TEMP="${TEMP:-0.2}"
OUT_DIR="${OUT_DIR:-/tmp/ollama-bench-out}"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: PROMPT_FILE not found: $PROMPT_FILE"
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "=== Creating Modelfile overlays (temp $TEMP) ==="
strict_names=()
for model in "${MODELS[@]}"; do
  # Sanitize model name for use as the strict variant name (replace : / with -)
  safe_name="${model//:/-}"
  safe_name="${safe_name//\//-}"
  strict_name="${safe_name}-strict"
  strict_names+=("$strict_name")

  cat > "/tmp/mf-$strict_name" <<EOF
FROM $model
PARAMETER temperature $TEMP
EOF
  echo "Creating $strict_name <- $model"
  ollama create "$strict_name" -f "/tmp/mf-$strict_name" 2>&1 | grep -E "success|error" || true
done

echo
echo "=== Running benchmark on ${#MODELS[@]} model(s) ==="
echo

times=()

for i in "${!MODELS[@]}"; do
  model="${MODELS[$i]}"
  strict_name="${strict_names[$i]}"
  outfile="$OUT_DIR/$strict_name-out.md"
  raw="$outfile.raw"

  echo "--- $strict_name ---"

  start=$(date +%s)
  cat "$PROMPT_FILE" | ollama run "$strict_name" --think=false > "$raw" 2>/dev/null
  end=$(date +%s)
  duration=$((end - start))
  times[$i]=$duration

  if grep -q '^\.\.\.done thinking\.$' "$raw"; then
    awk '/^\.\.\.done thinking\.$/{f=1; next} f' "$raw" > "$outfile"
    note="(thinking trace stripped)"
  else
    cp "$raw" "$outfile"
    note="(clean stream)"
  fi

  echo "Wall time: ${duration}s ${note}"
  echo "Output:    $outfile"
  echo
done

echo "=== Timing Summary ==="
printf "%-36s %s\n" "Model" "Wall time"
printf "%-36s %s\n" "-----" "---------"
for i in "${!MODELS[@]}"; do
  printf "%-36s %ss\n" "${MODELS[$i]}-strict" "${times[$i]}"
done
