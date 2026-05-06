Fetch the YouTube video transcript for the URL provided: $ARGUMENTS

Steps:
1. Extract the video ID from the URL (the `v=` parameter or the path after youtu.be/)
2. Run this Python script via Bash to fetch the transcript:

```python
python3 << 'PYEOF'
import sys
import re
import urllib.request
from youtube_transcript_api import YouTubeTranscriptApi

video_id = "VIDEO_ID_HERE"
url = f"https://www.youtube.com/watch?v={video_id}"

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

# Build readable markdown
output = f"# {title}\n\n"
output += f"**Channel:** {author}\n"
output += f"**URL:** {url}\n"
output += f"**Video ID:** {video_id}\n\n"
output += "---\n\n## Transcript\n\n"

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

# Save next to wherever user is working
import os
safe_title = re.sub(r'[^\w\s-]', '', title)[:60].strip().replace(' ', '-')
filename = f"{video_id}-{safe_title}.md"
filepath = os.path.join(os.getcwd(), filename)
with open(filepath, 'w') as f:
    f.write(output)

print(f"Title: {title}")
print(f"Channel: {author}")
print(f"Segments: {len(transcript.snippets)}")
print(f"Saved to: {filepath}")
PYEOF
```

Replace VIDEO_ID_HERE with the actual video ID extracted from the URL.

3. Report back: title, channel, segment count, and file path.
4. If the user asks for a summary after fetching, read the saved file and provide a concise summary of the key points.

Important:
- If youtube-transcript-api is not installed, run: pip3 install youtube-transcript-api
- Handle both youtube.com/watch?v=ID and youtu.be/ID URL formats
- Save the transcript as markdown in the current working directory
