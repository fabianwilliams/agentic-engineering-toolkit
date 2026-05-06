# wiki-compile

> Claude Code skill for compiling raw knowledge sources into structured wiki articles.

## Trigger

Use this skill when the user says any of:
- "compile wiki"
- "wiki compile"
- "process raw sources"
- "update knowledge base"
- "/wiki-compile"

## Prerequisites

The knowledge base must have this directory structure:

```
knowledge/
  raw/           # Uncompiled source files (transcripts, articles, notes)
  wiki/
    concepts/    # Abstract ideas, patterns, frameworks
    people/      # Speakers, authors, thought leaders
    tools/       # Products, libraries, frameworks
    research/    # Research summaries, analysis writeups
    decisions/   # Architecture decision records
    _index.md    # Master index of all wiki articles
  sources.md     # Registry of all processed sources
```

## Execution Steps

### Phase 1: Discovery

1. Use Glob to scan `knowledge/raw/**/*.md` for all markdown files.
2. Read each file's YAML frontmatter. Skip any file where `compiled: true` is set.
3. If no uncompiled files are found, report "All sources already compiled" and stop.
4. List the uncompiled files for the user before proceeding.

### Phase 2: Extract and Classify

For each uncompiled raw file:

1. Read the file fully.
2. Extract the following from the content:
   - **Concepts**: Abstract ideas, patterns, mental models, frameworks, methodologies.
   - **People**: Named individuals — speakers, authors, researchers, thought leaders. Only include people who are substantively discussed or quoted, not passing mentions.
   - **Tools**: Specific products, libraries, frameworks, platforms, services.
   - **Research**: If the source is a research paper, study, or deep analysis — treat the whole source as a research entry.
   - **Decisions**: If the source documents a technical or architectural decision — treat it as a decision record.

3. For each extracted item, determine the target wiki subdirectory:
   - `knowledge/wiki/concepts/` — concepts, patterns, frameworks
   - `knowledge/wiki/people/` — people
   - `knowledge/wiki/tools/` — tools, products, libraries
   - `knowledge/wiki/research/` — research summaries
   - `knowledge/wiki/decisions/` — architecture decision records

4. Generate a filename for each item: lowercase, hyphenated, `.md` extension.
   - Example: "Andrej Karpathy" -> `andrej-karpathy.md`
   - Example: "Retrieval Augmented Generation" -> `retrieval-augmented-generation.md`

### Phase 3: Compile Wiki Articles

For each extracted item:

1. **Check if the article already exists** using Glob to search for the filename in the target directory.

2. **If the article EXISTS** — MERGE new information:
   - Read the existing article.
   - Add new key points that aren't already present.
   - Append the new source to the `sources:` frontmatter list (avoid duplicates).
   - Add any new `[[wikilinks]]` to the `related:` frontmatter list.
   - Update `last_compiled:` date.
   - Use the Edit tool to apply changes — do NOT overwrite the entire file.

3. **If the article does NOT exist** — CREATE it using this format:

```markdown
---
title: "Article Title"
created: YYYY-MM-DD
last_compiled: YYYY-MM-DD
sources:
  - "raw/path/to/source-file.md"
related:
  - "[[Related Article]]"
tags: []
---

# Article Title

## Summary
[2-3 sentence overview compiled from the source material]

## Key Points
- Point 1
- Point 2
- Point 3

## Details
[Expanded content compiled from sources. Organized into logical subsections if needed.]

## Related
- [[Related Concept 1]]
- [[Related Person]]
- [[Related Tool]]

## Sources
- [Source Title](../../raw/path/to/source-file.md)
```

4. **Cross-link articles**: When creating or updating articles, add `[[wikilinks]]` to other wiki articles that are related. Use Obsidian `[[double-bracket]]` syntax. Add these links both:
   - Inline in the Details section where contextually relevant
   - In the Related section at the bottom
   - In the `related:` frontmatter array

### Phase 4: Update Indexes

After all articles are compiled:

1. **Update `knowledge/wiki/_index.md`**:
   - Read the existing index (or create it if missing).
   - Ensure every wiki article appears in the index, organized by subdirectory.
   - Format:

```markdown
---
title: "Wiki Index"
last_updated: YYYY-MM-DD
---

# Knowledge Wiki Index

## Concepts
- [[concept-name]] — one-line description

## People
- [[person-name]] — one-line description

## Tools
- [[tool-name]] — one-line description

## Research
- [[research-name]] — one-line description

## Decisions
- [[decision-name]] — one-line description
```

2. **Update `knowledge/sources.md`**:
   - Read the existing file (or create it if missing).
   - Add an entry for each newly processed source:

```markdown
## Source Title
- **File**: `raw/path/to/file.md`
- **Type**: transcript | article | notes | paper
- **Processed**: YYYY-MM-DD
- **Articles generated**: [[Article 1]], [[Article 2]], [[Article 3]]
```

3. **Mark raw files as compiled**:
   - For each processed raw file, update its YAML frontmatter to add:
     ```yaml
     compiled: true
     compiled_date: YYYY-MM-DD
     ```
   - If the file has no frontmatter, add a frontmatter block.
   - Use the Edit tool to modify the frontmatter — do not rewrite the entire file.

### Phase 5: Report

Output a summary:
```
Wiki Compilation Complete
=========================
Sources processed: N
Articles created:  N (list them)
Articles updated:  N (list them)
Index updated:     yes/no
```

## Rules (MUST follow)

1. **NEVER fabricate content.** Every fact, quote, and claim in a wiki article must come from the raw source files. If a source does not discuss something, do not add it.

2. **MERGE, don't overwrite.** When updating an existing wiki article with new source material, add to what exists. Never delete previously compiled content unless it contradicts a newer, more authoritative source.

3. **Summarize, don't transcribe.** If a raw file is a transcript, extract the key insights, arguments, and takeaways. Do not copy large blocks of transcript text. Keep articles concise and scannable.

4. **Use Obsidian wikilinks.** All cross-references between wiki articles must use `[[double-bracket]]` format. Use the article's title as the link text when possible: `[[Andrej Karpathy]]`, `[[Retrieval Augmented Generation]]`.

5. **Preserve source attribution.** Every wiki article must list its sources in both the frontmatter `sources:` array and the `## Sources` section with relative links.

6. **One concept per article.** Don't combine multiple distinct concepts into one article. If a source discusses 5 different ideas, create 5 separate concept articles.

7. **Idempotent execution.** Running the skill twice on the same raw files should produce no changes the second time (because `compiled: true` is set after the first run).

8. **Today's date** for all `created`, `last_compiled`, and `compiled_date` fields. Use YYYY-MM-DD format.

9. **Relative paths** in source links. Wiki articles link to raw files using relative paths from the wiki subdirectory (e.g., `../../raw/transcripts/file.md`).

10. **Tags are optional.** Only add tags if the source material makes clear categorization obvious. Don't invent tags.
