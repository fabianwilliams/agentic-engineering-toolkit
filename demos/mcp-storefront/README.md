# MCP Storefront — Worked Example

A public reference implementation of a **consumer-observable agent receipt**: any MCP-capable client can call the storefront, request a free-trial bundle on behalf of a user, and receive back an audit-trail receipt URL that documents every supervision-layer check that fired.

The full reference source is in a sibling repo: **[github.com/fabianwilliams/adotob-mcp](https://github.com/fabianwilliams/adotob-mcp)** (Apache 2.0). The links below are the *artifacts* — the public URLs that prove it works.

## Two live receipts, two clients, one endpoint

Same `https://mcp.adotob.com/api/a2a/mcp`. Same six supervision checks. Same audit-trail format. Different clients driving the call.

| Client | Receipt | Stack |
|---|---|---|
| Claude Desktop (Anthropic-hosted) | [`rcpt_2026-05-16_0a96ef3d`](https://mcp.adotob.com/a2a/receipt/rcpt_2026-05-16_0a96ef3d) | Hosted frontier model |
| LM Studio + Qwen3.6 27B | [`rcpt_2026-05-16_7f1fd149`](https://mcp.adotob.com/a2a/receipt/rcpt_2026-05-16_7f1fd149) | Fully local open-weights on MacBook Pro M3 Max |

That second row is the one that surprises most readers. A 27B open-weights model running offline on consumer hardware drives the same MCP tool call and produces the same receipt as a frontier-cloud model. The integration surface is the MCP protocol, not any one vendor's SDK.

## Try it yourself

Two-minute walkthrough with all 16 screenshots from the two example runs:

→ **[Happy-Path SOP](https://github.com/fabianwilliams/adotob-mcp/blob/main/docs/HAPPY-PATH-SOP.md)**

The SOP includes a client matrix showing where the "add MCP server" UI lives in Claude Desktop, ChatGPT, LM Studio, Cursor, Windsurf, Cline, and others — plus a raw-API path (Path B) for code that calls the endpoint directly from the OpenAI Responses API, Anthropic Messages API, Bedrock, Azure OpenAI, etc.

## Why this matters

One artifact, two buyer concerns:

- **Security / audit ledger.** "Show me your evals — how do you know the agent did the right thing?" The receipt is the evidence, publicly readable, no privileged access required.
- **Finance / billing ledger.** "When an agent transacts on a user's behalf, what's the proof of what it did?" Every metered action has a corresponding receipt URL — chain-of-custody for billable agent actions.

Both questions resolve to the same URL. That's the property that matters as agent-to-agent commerce moves from demo to production.

## The methodology

The six supervision checks are bucketed into three phases:

1. **Admission gates** — input validation, rate limit, daily cost ceiling
2. **Processing** — lead capture, download token mint
3. **Fulfillment** — fulfillment email dispatch

This is the same Agent Reliability Kit discipline applied across the rest of this repo — wrappers around freelance LLM actions, declarative judge contracts, closed-loop bug protocol, anti-fabrication discipline. The MCP storefront is the public, end-user-facing instance of those patterns running in production. The receipt page is what the patterns *look like* from the consumer side.

## What is here vs in adotob-mcp

| In this folder | In adotob-mcp |
|---|---|
| This README (the cross-link + framing) | The full Next.js reference implementation |
| Pointers to the live receipts + SOP | The 6-check orchestrator (`src/lib/a2a-purchase.ts`) |
| | The receipt page UI (`src/components/receipt-timeline.tsx`) |
| | The rate-limit / cost-ceiling middleware |
| | The 16-screenshot walkthrough (`docs/HAPPY-PATH-SOP.md`) |
| | GitHub Actions deploy pipeline to Azure Static Web Apps |

The implementation is intentionally minimal. The value is the audit-trail shape and the discipline of making it consumer-readable, not framework cleverness. If you fork it for your own agent storefront, the receipt-as-public-URL is the only thing you must preserve.
