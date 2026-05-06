# wiki-lint — Knowledge Wiki Health Check

Run health checks on the knowledge wiki and report broken links, stale articles, orphans, and other issues.

## Trigger

When the user types `/wiki-lint`, execute all steps below.

## Constants

- **Vault root**: current working directory (the directory you launched Claude Code from)
- **Wiki directory**: `knowledge/wiki/` (relative to vault root)
- **Output file**: `knowledge/wiki/_stale.md` (relative to vault root)
- **Stale threshold**: 90 days from today

## Instructions

### Step 1: Scan all wiki articles

Use Glob to find all `knowledge/wiki/**/*.md` files under the vault root. Exclude `_stale.md` and `_index.md` from checks (but include them when resolving link targets).

### Step 2: Run health checks

For each article found, perform ALL of the following checks:

#### 2a. Broken wikilinks (ERROR)

- Parse each file for `[[wikilink]]` patterns (including `[[link|display text]]` format — use the part before `|` as the target)
- For each wikilink, check whether a matching `.md` file exists anywhere under `knowledge/wiki/`
- Match rules: the link target should match either the filename (without extension) or a relative path within the wiki directory
- If no matching file exists, report as ERROR: `Broken link: [[Target Name]]`

#### 2b. Missing frontmatter (ERROR)

- Check that each article starts with a YAML frontmatter block (`---` on line 1, fields, then closing `---`)
- Required frontmatter fields: `title`, `type`, `date` (at minimum)
- If frontmatter is missing entirely or required fields are absent, report as ERROR

#### 2c. Empty sections (ERROR)

- Look for markdown headers (`##`, `###`, etc.) that are immediately followed by another header or end-of-file with no content between them
- Ignore headers that contain only whitespace between them and the next header
- Report as ERROR: `Empty section: ## Section Name`

#### 2d. Stale articles (WARNING)

- Use Bash to check each file's last modification time: `stat -c '%Y' <filepath>` (Linux) or `stat -f '%m' <filepath>` (macOS)
- Compare against today's date minus 90 days
- If the file hasn't been modified in over 90 days, report as WARNING with the number of days since last modification

#### 2e. Orphan articles (WARNING)

- An orphan is an article that has NO incoming wikilinks from other wiki articles AND has NO outgoing wikilinks to other wiki articles
- Build a map of all wikilinks across all articles
- Any article that appears in neither the "links to" nor "linked from" sets is an orphan
- Report as WARNING: `Orphan: no incoming or outgoing links`

#### 2f. Duplicate concepts (INFO)

- Compare article titles (from frontmatter `title` field or filename)
- Look for articles whose titles share significant keywords (excluding common words like "the", "and", "of", "in", "for", "a", "an", "to", "with")
- If two articles share 2+ significant title keywords, suggest they might cover similar topics
- Also look for cases where a concept is mentioned (via `[[wikilink]]`) in 3+ articles but has no dedicated wiki page — suggest creating one

### Step 3: Classify and format findings

Group all findings by severity:
- **Errors**: Broken links, missing frontmatter, empty sections
- **Warnings**: Stale articles, orphan articles
- **Suggestions**: Duplicate concepts, new article candidates

### Step 4: Write the report

Write findings to `knowledge/wiki/_stale.md` at the vault root. Use this exact format:

```markdown
# Wiki Health Check — YYYY-MM-DD

**Scanned:** X articles | **Errors:** N | **Warnings:** N | **Suggestions:** N

## Errors
- [article.md] Broken link: [[NonExistent Article]]
- [article.md] Missing frontmatter field: `title`
- [article.md] Empty section: ## Section Name

## Warnings
- [old-article.md] Stale: last modified 95 days ago
- [orphan.md] Orphan: no incoming or outgoing links

## Suggestions
- Consider linking [[Concept A]] and [[Concept B]] — both discuss similar topics
- New article candidate: "Token Budget Patterns" (mentioned in 3 articles but no dedicated page)
```

If a category has no findings, write `None` under it.

### Step 5: Print summary to stdout

After writing the file, print a one-line summary:

```
Wiki lint complete: X errors, Y warnings, Z suggestions. Report: knowledge/wiki/_stale.md
```

## Implementation Notes

- Use the Bash tool for file stat checks (modification times)
- Use the Grep tool to search for wikilink patterns: `\[\[.*?\]\]`
- Use the Read tool to inspect frontmatter and section structure
- Use the Glob tool to enumerate all wiki files
- All paths should be absolute using the vault root constant
- If the wiki directory is empty or doesn't exist, report that and exit gracefully
- This skill does NOT modify any wiki articles — it only reads and reports
