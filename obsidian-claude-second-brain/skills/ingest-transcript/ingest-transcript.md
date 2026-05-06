# ingest-transcript — YouTube Transcript to Knowledge Pipeline

Fetch a YouTube transcript and feed it into the knowledge pipeline with proper metadata and source tracking.

## Trigger

When the user types `/ingest-transcript <youtube-url>`, execute all steps below using the provided URL.

## Constants

- **Vault root**: current working directory (the directory you launched Claude Code from)
- **Transcript output dir**: `knowledge/raw/transcripts/` (relative to vault root)
- **Sources file**: `knowledge/sources.md` (relative to vault root)
- **Today's date**: use `date +%Y-%m-%d` to get current date

## Instructions

### Step 1: Extract video ID and fetch transcript

Extract the video ID from the URL. Handle both formats:
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`

Run this Python script via Bash, replacing `VIDEO_ID_HERE` with the actual video ID:

```bash
python << 'PYEOF'
import sys
import re
import os
import urllib.request
from datetime import date
from youtube_transcript_api import YouTubeTranscriptApi

video_id = "VIDEO_ID_HERE"
url = f"https://www.youtube.com/watch?v={video_id}"
today = date.today().isoformat()

# Get metadata
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read().decode('utf-8', errors='ignore')
title_match = re.search(r'<title>(.*?)</title>', html)
title = title_match.group(1).replace(' - YouTube', '').strip() if title_match else 'Unknown Title'
author_match = re.search(r'"author":"(.*?)"', html)
author = author_match.group(1) if author_match else 'Unknown Channel'

# Get transcript
ytt_api = YouTubeTranscriptApi()
transcript = ytt_api.fetch(video_id)

# Build safe filename
safe_title = re.sub(r'[^\w\s-]', '', title)[:60].strip().replace(' ', '-')
filename = f"{today}-{safe_title}.md"

# Build markdown with YAML frontmatter
output = f"""---
title: "{title}"
source: "{url}"
type: transcript
speaker: "{author}"
date_fetched: {today}
compiled: false
tags: []
---

# {title}

**Channel:** {author}
**URL:** {url}
**Video ID:** {video_id}

---

## Transcript

"""

paragraph = []
for snippet in transcript.snippets:
    text = snippet.text.strip()
    if not text:
        continue
    paragraph.append(text)
    if len(paragraph) >= 8:
        output += " ".join(paragraph) + "\n\n"
        paragraph = []
if paragraph:
    output += " ".join(paragraph) + "\n\n"

# Save to knowledge pipeline directory
vault_root = os.getcwd()
transcript_dir = os.path.join(vault_root, "knowledge", "raw", "transcripts")
os.makedirs(transcript_dir, exist_ok=True)
filepath = os.path.join(transcript_dir, filename)

with open(filepath, 'w') as f:
    f.write(output)

# Print metadata for downstream steps
print(f"TITLE={title}")
print(f"AUTHOR={author}")
print(f"DATE={today}")
print(f"FILENAME={filename}")
print(f"FILEPATH={filepath}")
print(f"SEGMENTS={len(transcript.snippets)}")
PYEOF
```

If `youtube-transcript-api` is not installed, run `pip install youtube-transcript-api` first.

### Step 2: Verify the saved file

After the Python script completes, use the Read tool to verify the file was saved correctly at `knowledge/raw/transcripts/YYYY-MM-DD-<safe-title>.md`. Confirm the YAML frontmatter is present and well-formed.

### Step 3: Update sources.md

Read the current contents of `knowledge/sources.md` at the vault root. Append a new row to the table:

```
| YYYY-MM-DD | Video Title | YouTube transcript | raw/transcripts/ | No |
```

Use the actual date and title from Step 1. Use the Edit tool to append the row to the existing table.

### Step 4: Report to user

Print a summary:

```
Transcript saved: knowledge/raw/transcripts/YYYY-MM-DD-<title>.md
  Title: <Video Title>
  Channel: <Channel Name>
  Segments: <count>
  Source registry updated: knowledge/sources.md
```

### Step 5: Ask about compilation

Ask the user:

> Transcript saved. Run `/wiki-compile` to process it into wiki articles?

Wait for the user's response. If they say yes, invoke the `/wiki-compile` skill. If they say no or don't respond, do nothing further.

## Error Handling

- If the YouTube URL is invalid or the video ID cannot be extracted, tell the user and stop
- If the transcript is unavailable (private video, no captions), report the error clearly
- If `sources.md` doesn't exist, create it with the table header:
  ```markdown
  # Source Registry

  | Date | Source | Type | Location | Compiled? |
  |------|--------|------|----------|-----------|
  ```
- If the transcript file already exists at the target path (same date + title), warn the user and ask whether to overwrite

## Differences from /yt-transcript

| Feature | /yt-transcript | /ingest-transcript |
|---------|---------------|-------------------|
| Save location | Current working directory | `knowledge/raw/transcripts/` |
| Frontmatter | None | Full YAML (title, source, type, speaker, date, tags) |
| Source tracking | None | Appends to `knowledge/sources.md` |
| Filename format | `VIDEO_ID-title.md` | `YYYY-MM-DD-title.md` |
| Pipeline integration | Standalone | Feeds into `/wiki-compile` |

Use `/yt-transcript` for quick one-off transcript grabs. Use `/ingest-transcript` when you want the transcript to enter the knowledge pipeline for compilation into wiki articles.
