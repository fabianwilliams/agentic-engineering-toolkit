Compile raw knowledge sources into wiki articles. Follow ALL instructions in `<vault-root>/skills/wiki-compile/wiki-compile.md` exactly.

Summary of what to do:

1. Scan `knowledge/raw/` under the vault root for files without `compiled: true` in frontmatter
2. For each uncompiled file: read it, extract key concepts/people/tools/research topics
3. For each extracted item: create or update a wiki article in the appropriate `knowledge/wiki/` subdirectory (`concepts/`, `people/`, `tools/`, `research/`, `decisions/`)
4. Add `[[wikilinks]]` between related articles
5. Update `knowledge/wiki/_index.md` with new/changed articles
6. Update `knowledge/sources.md` with entries for processed sources
7. Mark each processed raw file with `compiled: true` and `compiled_date` in its frontmatter
8. Print a summary: X sources processed, Y articles created, Z articles updated

Read the full skill file for detailed rules (no fabrication, merge-not-overwrite, wikilinks, attribution, etc.) before starting.

> **Setup note:** Replace `<vault-root>` above with the absolute path to your Obsidian vault before using this command.
