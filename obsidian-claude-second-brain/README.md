# Obsidian + Claude Second Brain

> A working implementation of [Andrej Karpathy's second-brain pattern](https://x.com/karpathy/status/1829395800024674444) on top of an Obsidian vault, driven by Claude Code skills.

If you found this through [the blog post](https://fabswill.com/blog/building-a-second-brain-that-compounds-karpathy-obsidian-claude/), this is the runnable version. Drop the four skills into your `~/.claude/commands/` directory, copy the `knowledge-template/` folder into your Obsidian vault, and the `/ingest-transcript`, `/wiki-compile`, and `/wiki-lint` commands will start working.

## What this gives you

A pipeline that ingests raw content (YouTube transcripts, web articles, papers, notes) into an Obsidian vault and **compiles it into a cross-linked wiki** of concepts, people, tools, research, and decisions — with attribution preserved and no fabrication. Karpathy's idea was that an LLM-powered second brain should *compound*: every new source should make the existing knowledge base more connected, not just bigger. These skills implement that.

## What's in here

| File | Purpose |
|---|---|
| `commands/yt-transcript.md` | Quick one-off — fetch a YouTube transcript to your current working directory. Standalone. |
| `commands/ingest-transcript.md` | Pipeline ingest — fetch a transcript with proper YAML frontmatter and drop it into `knowledge/raw/transcripts/` for downstream compilation. |
| `commands/wiki-compile.md` | Read everything in `knowledge/raw/` and compile cross-linked articles into `knowledge/wiki/`. Idempotent — runs again won't reprocess already-compiled sources. |
| `commands/wiki-lint.md` | Health check on the compiled wiki — broken `[[wikilinks]]`, missing frontmatter, empty sections, stale articles, orphans. |
| `skills/*.md` | Long-form versions of each skill that the short command files reference. |
| `knowledge-template/` | The directory layout `wiki-compile` and `wiki-lint` expect. Copy this into your vault root. |

## Setup (5 minutes)

```bash
# 1. Copy the four short command files into your Claude Code commands dir
cp commands/*.md ~/.claude/commands/

# 2. Copy the four long skill files into your vault somewhere consistent —
# the convention I use is <vault-root>/skills/<skill-name>/<skill-name>.md.
# The short command files reference these, so the path matters.
mkdir -p ~/your-obsidian-vault/skills
cp -r skills/. ~/your-obsidian-vault/skills/

# 3. Copy the knowledge-pipeline directory structure into your vault root
cp -r knowledge-template/. ~/your-obsidian-vault/

# 4. Edit the path references in ~/.claude/commands/*.md
# Each short command file has an absolute path in its first line referencing
# the long skill file. Update those paths to match where you put `skills/`
# in step 2.

# 5. Install the YouTube transcript dependency
pip3 install youtube-transcript-api
```

After setup, in any Claude Code session inside your vault:

```
/ingest-transcript https://www.youtube.com/watch?v=...
/wiki-compile
/wiki-lint
```

The first compiles the new transcript into wiki articles; the second runs a health check on the resulting wiki.

## How it actually works

```
~/your-obsidian-vault/
├── knowledge/
│   ├── raw/                  # Drop zone — articles, transcripts, papers, tweets
│   │   ├── articles/
│   │   ├── transcripts/      # /ingest-transcript drops files here
│   │   ├── papers/
│   │   └── tweets/
│   ├── wiki/                 # Compiled output — DO NOT edit by hand
│   │   ├── concepts/         # Mental models, frameworks, patterns
│   │   ├── people/           # Speakers, authors, thought leaders
│   │   ├── tools/            # Products, libraries, frameworks
│   │   ├── research/         # Research summaries
│   │   ├── decisions/        # ADRs
│   │   ├── _index.md         # Master index — auto-maintained
│   │   └── _stale.md         # /wiki-lint output
│   ├── output/               # Query results filed back
│   │   ├── briefs/
│   │   ├── slides/
│   │   └── analyses/
│   └── sources.md            # Registry of every processed source
└── skills/
    ├── ingest-transcript/
    │   └── ingest-transcript.md
    ├── wiki-compile/
    │   └── wiki-compile.md
    └── wiki-lint/
        └── wiki-lint.md
```

The flow is one direction: content enters via `raw/`, gets compiled by `/wiki-compile` into linked `wiki/` articles, and queries (yours or Claude's) pull from the wiki. Editing wiki articles by hand is fine — the merge logic in `wiki-compile` preserves manual edits when re-running.

## Why these skills, in this order

`/yt-transcript` is the quick-grab — it doesn't enter the pipeline, just dumps a transcript next to wherever you're working. Use it when you want to read a video without going to YouTube.

`/ingest-transcript` is the same fetch but with the YAML frontmatter, source registry update, and pipeline placement that downstream skills need. Use it when you want the transcript to *compound* — to become part of your second brain's connected knowledge.

`/wiki-compile` is the workhorse. It reads everything in `raw/` that doesn't already have `compiled: true` in frontmatter, extracts concepts/people/tools/research/decisions, and writes (or merges into) wiki articles with `[[wikilinks]]`. Karpathy's compounding effect happens here — the second time you run it, today's transcript gets cross-linked to last week's article on the same person/concept.

`/wiki-lint` is the health check. As your wiki grows, links break (someone renames an article), frontmatter drifts, sections go empty, articles age out. Lint catches these without modifying anything — write-only check, output goes to `_stale.md`.

## Constraints I built into wiki-compile

The skill file's "Rules" section is the whole point — these prevent the second brain from becoming an AI-slop dump:

1. **Never fabricate.** Every fact, quote, and claim must come from a source in `raw/`. If a transcript doesn't say it, don't add it.
2. **Merge, don't overwrite.** Re-running on a new source about an existing topic appends — it doesn't replace.
3. **Summarize, don't transcribe.** Wiki articles are scannable; long quotes belong in `raw/`, not `wiki/`.
4. **Use Obsidian wikilinks.** `[[double-bracket]]` format — the whole point is that Obsidian renders them as a graph.
5. **Preserve attribution.** Every wiki article lists its sources in both frontmatter and a `## Sources` section.
6. **One concept per article.** A source covering 5 ideas produces 5 wiki articles, not one combined.
7. **Idempotent.** Running twice on the same `raw/` files does nothing the second time (the `compiled: true` flag prevents reprocessing).

## License & attribution

Apache 2.0. Karpathy gets credit for the original second-brain compounding insight. The implementation here is mine — fork it, modify it, ship it inside your own product, attribution appreciated but not required.

If you publish a variant or improvement, drop a link in [the blog post comments](https://fabswill.com/blog/building-a-second-brain-that-compounds-karpathy-obsidian-claude/) — I'm collecting variants.
