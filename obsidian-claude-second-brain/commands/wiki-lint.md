Run a health check on the knowledge wiki. Follow ALL instructions in `<vault-root>/skills/wiki-lint/wiki-lint.md` exactly.

Summary of what to do:

1. Scan all `knowledge/wiki/**/*.md` files under the vault root
2. Check for:
   - Broken `[[wikilinks]]` — links pointing to articles that don't exist (ERROR)
   - Missing frontmatter — articles without YAML frontmatter or missing required fields: title, type, date (ERROR)
   - Empty sections — headers with no content before the next header (ERROR)
   - Stale articles — not modified in >90 days (WARNING)
   - Orphan articles — no incoming or outgoing wikilinks (WARNING)
   - Duplicate concepts — articles with overlapping title keywords, or concepts mentioned in 3+ articles with no dedicated page (INFO)
3. Write a structured report to `knowledge/wiki/_stale.md` grouped by severity (Errors, Warnings, Suggestions)
4. Print a one-line summary: `Wiki lint complete: X errors, Y warnings, Z suggestions. Report: knowledge/wiki/_stale.md`

Read the full skill file for detailed implementation instructions before starting.

> **Setup note:** Replace `<vault-root>` above with the absolute path to your Obsidian vault before using this command.
