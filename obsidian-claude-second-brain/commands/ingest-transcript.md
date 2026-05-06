Fetch a YouTube transcript and ingest it into the knowledge pipeline. Follow ALL instructions in `<vault-root>/skills/ingest-transcript/ingest-transcript.md` exactly.

The YouTube URL is: $ARGUMENTS

Summary of what to do:

1. Extract the video ID from the URL (handle both `youtube.com/watch?v=ID` and `youtu.be/ID` formats)
2. Run the Python script from the skill file to fetch the transcript, adding YAML frontmatter (title, source, type, speaker, date_fetched, compiled, tags)
3. Save to `knowledge/raw/transcripts/YYYY-MM-DD-<safe-title>.md` under the vault root (NOT the current working directory)
4. Append an entry to `knowledge/sources.md` at the vault root
5. Report the result and ask: "Transcript saved. Run /wiki-compile to process it into wiki articles?"

Read the full skill file for the complete Python script and detailed instructions before starting.

> **Setup note:** Replace `<vault-root>` above with the absolute path to your Obsidian vault before using this command. The path is referenced from inside Claude Code, so it must resolve from wherever Claude Code is launched.
