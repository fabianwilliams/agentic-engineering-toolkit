You are a B2B sales research analyst preparing a prospect brief for an SDR. Read the research notes at the bottom of this message and produce a brief in the EXACT format specified below.

# OUTPUT FORMAT

Use these exact markdown headers, in this order:

## Company: [Name]
**One-line:** [≤ 12 words — what they do and who buys]

### Why now
- [bullet ≤ 18 words, must cite a specific fact from the notes]
- [bullet ≤ 18 words]
- [bullet ≤ 18 words]

### Decision-maker hypothesis
- **Primary:** [Name, title — one short sentence on why]
- **Secondary:** [Name, title — one short sentence on why]

### Outreach hook
[2-3 sentences, ≤ 50 words total. Must reference one specific recent event named in the notes.]

### Risk flags
- [bullet]
- [bullet]
- [bullet — optional]

# CONSTRAINTS

- Use ONLY facts from the research notes below. Do not invent dates, dollar amounts, names, titles, or quotes.
- If a section cannot be supported by the notes, write "Insufficient data" under that header instead of guessing.
- Preserve any hedges in the source ("unverified", "authenticity unconfirmed", "reportedly") rather than asserting rumored facts as confirmed.
- Total output must be ≤ 350 words.
- Do not include a preamble, restatement of these instructions, or any commentary. Output the brief and nothing else.

# RESEARCH NOTES

**Company:** Northwind Routing (northwindrouting.com)

**Founded:** 2021, Seattle WA

**Founders:**
- Maya Okonkwo — CEO. Previously product lead at Convoy (2018–2021). Stanford MBA. LinkedIn shows she has been posting weekly about freight broker workflow pain since Q4 2025.
- Daniel Rey — CTO. Ex-Flexport infrastructure engineer. Personal blog at danielrey.dev, writes mostly about Postgres.

**Funding:**
- Seed: $4.2M led by Bessemer with Susa Ventures participating, March 2022
- Series A: $14M led by Battery Ventures, September 2024
- Total raised: ~$18.2M per Crunchbase

**Headcount:** ~55 (LinkedIn). Reportedly cut 8 people from Customer Success in February 2026 (TheLayoff.com thread, unverified). Hired Marcus Tilden as VP Sales in March 2026 — Tilden was previously Director of Strategic Accounts at Project44.

**Product:**
Northwind sells SaaS to mid-market freight brokers. Core capabilities:
- Carrier qualification & DOT/FMCSA filing automation
- Insurance certificate verification
- Carrier scorecard / risk monitoring

Pricing per their blog post in Q4 2025: "around $2.50 per active carrier record per month." No public per-seat number.

In a Freight Tech Weekly podcast appearance (host: Jim Bartolo, episode 142, aired 2026-02-19), Maya described the legacy competitor Carrier411 as "the product everyone hates but no one has been able to displace at the mid-market layer." She also said: "we're seeing strong displacement traction" — no specific numbers given on the podcast.

**Recent traction signals:**
- Maya posted on LinkedIn 2026-04-08: "Just crossed $6.2M ARR this quarter. Honored to serve 140+ broker teams."
- Customer win announcement, same post: "Welcoming Saia LTL Freight to the Northwind family this week."
- A leaked screenshot from a Q1 2026 board update circulated on freight-tech Twitter (poster: @freightleaks, 2026-04-12). The screenshot shows a slide titled "Win source breakdown — Q1" with "Carrier411 displacement = #1 source (47%)" — authenticity unconfirmed.
- Greenhouse careers page (pulled 2026-04-25) shows three open roles: Senior ML Engineer, Senior Backend Eng (Python), and Customer Success Manager. The ML Engineer JD mentions "experience evaluating LLM frameworks for production deployment" and "comfort with vendor selection (OpenAI, Anthropic, open models)."

**Tech stack signals:**
- Job posts confirm Python + Postgres + AWS
- Daniel's recent blog post (2026-03-03) is titled "Why we moved off pgBouncer to Supavisor"
- A leaked Slack screenshot in the Bartolo podcast (Maya shared it during the interview) referenced the team "evaluating OpenAI Enterprise pricing"

**Customer signals:**
- G2: 11 reviews, avg 4.3
- One review posted 2026-03-22, 3 stars: "Product is great but support response times have noticeably slipped in the last month or two. Hope they staff back up."
- TrustRadius: 7 reviews, avg 4.1, no recent negative reviews

**Competitive landscape:**
- Carrier411 — legacy incumbent, on-prem-feel UX, ~25 years in market
- HighwayLogix — newer competitor, raised $25M Series B in mid-2025, more aggressive on price per industry chatter
- DAT Solutions — large incumbent, compliance is ancillary not primary

**Market context:**
- ~50,000 mid-market freight brokers in US per Armstrong & Associates 2024 report
- 2024 FMCSA "Provider Registration Modernization" rule increased per-broker compliance burden — cited frequently in Maya's content as the wedge for Northwind's growth

**Other notes (lower signal):**
- Maya ran the Seattle Marathon in October 2025, posted her time on Twitter
- Team off-site in Whistler in January 2026 per LinkedIn group photo
- Daniel was a guest on PgWeekly podcast (episode 78, 2025-11) — talked exclusively about connection pooling, no Northwind product detail
- Priya Shah joined as Head of Product in mid-2025 per her own LinkedIn — limited public posting

**Pain signal (highest value):**
The G2 3-star review on support response time, combined with the February CS layoffs and the open Customer Success Manager job posting, all point to a CS staffing gap that is starting to show in customer satisfaction. This is plausibly a moment where a vendor that helps Northwind reduce CS load (e.g., self-serve onboarding, automated carrier vetting, or AI-assisted support) would land.

(End of research notes.)
