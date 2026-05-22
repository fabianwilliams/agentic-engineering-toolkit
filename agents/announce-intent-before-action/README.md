# Announce Intent Before Action

> A discipline of the Agent Reliability Kit. Pairs with [`sense-before-act`](../sense-before-act/) (the observation half) and the audit-trail receipt (the after-action artifact). Together the three form the per-iteration arc: observe, announce, verify.

---

> **By the end of this doc you will know how to extend an agent tool's contract from "what to call" to "what will happen" — so the human-in-the-loop can decide whether reality matched the announcement after the fact. The receipt enumerates what happened. This discipline ensures that "what was going to happen" was legible *before* the human approved.**

---

## The discipline

When an agent is about to take a side-effecting action on a human's behalf, the agent's tool contract must enumerate **every server-side effect** the call will produce — not just the input arguments the human is approving.

The two halves of the safety loop:

| Half | Artifact | Question it answers |
|---|---|---|
| **Before action** | Tool description that enumerates side-effects | "What is this agent about to do on my behalf?" |
| **After action** | Public, consumer-readable audit-trail receipt | "What did the agent actually do?" |

Both halves are required. A system with only the after-action receipt makes the human reactive: they only learn the full scope of what happened *after* it happened. A system with only the before-action announcement makes the human credulous: they trust the announcement and have no way to verify the reality.

The pair is what makes agent safety legible.

The broader frame: this discipline pairs with [`sense-before-act`](../sense-before-act/) on the observation side. Sense-before-act forces the agent to ground in real state before any decision (four artifacts emitted every iteration). Announce-intent-before-action then forces the agent to enumerate side effects before the tool fires. The audit-trail receipt closes the loop after action. The full per-iteration arc is observe, announce, act, receipt; this discipline owns the second step.

## Lineage

The discipline is borrowed directly from physical robotics, not invented for agents.

[Caitlin Kalinowski](https://www.linkedin.com/in/caitlin-kalinowski) of OpenAI — formerly head of Orion AR glasses at Meta, prior at Oculus and Apple — articulated this on [Lenny Rachitsky's podcast](https://www.lennysnewsletter.com/) (2026-05-17). Discussing humanoid robot safety, she described the Pixar pattern: a physical robot moving toward a human must **announce its intent** before motion begins — a slight pause, a look, a gesture, a visible orientation — so the human can read the intent and either approve or step back. The motion itself is the same. The announcement is what makes the motion safe.

The lineage is older than Pixar. Stage actors learn this as "telegraphing" — Stanislavski had a name for it; Chekhov refined it. The physical-comedy precedent is older still: vaudeville actors knew that a punch the audience could *see coming* landed better than one that surprised them. Pixar's particular contribution was operationalizing it for animated characters that needed to be readable in milliseconds — Luxo Jr. anticipates before it hops.

What agents do — purchase, transfer, message, ingest — is functionally the same as what robots do, just with different actuators. The actuator is API calls instead of motors. The safety primitive transfers.

See also: <a href="../../obsidian-claude-second-brain">obsidian-claude-second-brain</a> for the broader wiki where this concept is filed as `robot-social-cues-from-pixar`.

## What this looks like in practice (MCP tool contracts)

The pre-fix tool description for `purchase_free_bundle` on the [Adotob MCP storefront](https://github.com/fabianwilliams/adotob-mcp) reads:

> *"Request the Adotob Agent Reliability Kit free-trial bundle. Returns an audit-trail receipt with download URL. Requires first_name and email."*

This is a **terse contract**. It states what to call and what comes back. It does not state what happens between the call and the return.

A reader of the audit-trail receipt afterwards learns that the server actually:

1. Validates input
2. Checks an IP rate-limit
3. Checks a daily cost ceiling
4. Upserts the caller's contact to a Brevo CRM list ("MCP Demo Leads")
5. Mints a 24-hour JOSE HS256 download token
6. Sends a fulfillment email via Brevo transactional API
7. Issues a public, consumer-readable receipt URL with a 30-day TTL

That is seven distinct side-effects. The pre-fix description names zero of them.

The post-discipline description — the one this kit recommends — reads:

> *"Request the Adotob Agent Reliability Kit free-trial bundle. Returns an audit-trail receipt with download URL. Requires first_name and email.*
>
> *Side-effects produced by this call: (1) your contact is upserted into the MCP-Demo-Leads CRM list with source=mcp; (2) a 24-hour download token is minted and signed; (3) a transactional email is dispatched to the address you supply; (4) a public, consumer-readable receipt URL is issued, valid for 30 days. Strongly recommended for production agents: supply idempotency_key so a retry on timeout returns the original receipt instead of double-issuing."*

The post-discipline version is longer. That is fine. **Tokens spent on intent-announcement are not waste — they are the safety budget.**

## The checklist

For any agent tool that takes side-effecting action, the description must enumerate:

1. **Data side-effects.** What does the server *store*? Where? For how long?
2. **Identity side-effects.** Does this call create, update, or delete a customer/contact/account?
3. **Communication side-effects.** Does this send an email, SMS, push notification, or other outbound message?
4. **Issuance side-effects.** Does this mint a token, key, credential, or signed artifact? With what expiry?
5. **Public side-effects.** Does this create a publicly readable URL, post, or record? With what TTL?
6. **Money side-effects.** Does this charge, refund, transfer, hold, or release funds?
7. **Trigger side-effects.** Does this enqueue work in another system that will run later?

If any answer is yes, the description must name it. Generic terms ("processes your request", "completes the transaction") are not announcements — they are evasions.

## Anti-patterns

- **Permission-prompt as the only announcement.** Most MCP clients show the *arguments* before invoking a tool. That is announcing the input, not the side-effects. The argument `{first_name: "Alex", email: "alex@example.com"}` does not tell the human their email will land in a CRM list, an email will be sent, a 24-hour token will be minted.
- **Trust me, see receipt.** Some systems argue the receipt covers everything. It does — *after the fact*. The pre-action announcement is what gives the human the chance to *not* approve.
- **Marketing copy as description.** "Get instant access to your free trial!" is marketing. It is not intent enumeration. Tool descriptions are technical contracts, not landing-page copy.

## The matched pair, again

The discipline is the receipt's twin. Either alone is incomplete:

- **Receipt without announce-intent** = system enforces transparency *only* after the human has already committed.
- **Announce-intent without receipt** = system enforces transparency only at the point of trust, with no audit possible afterward.

Both halves shipped together is the design pattern. The pair is what a procurement reviewer, a CISO, a CFO, or a partner expects when "agent safety" is more than a marketing claim.

## How this maps onto Claire Vo's "types and tests as bookends"

Claire Vo's framework for writing specs in the agentic era: lead with the **types** (what the data looks like, what is in the pipes), close with the **tests** (what success looks like and how to verify it). Everything in the middle is gravy. With both bookends pinned, the implementation details are negotiable, which is exactly what you want the agent to figure out.

The announce-intent-before-action discipline is the same shape applied to side-effects:

| Spec bookend (Claire) | Reliability Kit bookend (this discipline) |
|---|---|
| **Types**: what shape the data has, what is in the pipes, what entities exist | **Side-effect enumeration**: the 7 categories the tool description must address (data, identity, communication, issuance, public, money, trigger) |
| **Tests**: validation criteria, success metrics, acceptance scenarios | **Audit-trail receipt**: every check that fired, in order, with pass/fail/skip/warn status and a timestamp |

Both bookends are pinned; the middle (the implementation between announcement and verification) is, in Claire's phrasing, gravy. The agent runtime, the LLM provider, the orchestration framework, the storage backend, can change. What stays constant is: the tool's contract enumerates side-effects, and the receipt verifies which ones fired.

This vocabulary matters because most product managers and product engineers already speak it. Claire's "types and tests as bookends" framing is a 2026-vintage PM idiom. Naming the announce-intent-before-action discipline as the side-effects-and-receipt version of the same shape makes it immediately recognizable to a wider audience than the security and finance buyers the original framing addressed.

See `concepts/types-and-tests-as-spec-bookends.md` and `people/claire-vo.md` in the upstream knowledge wiki for the full Claire Vo treatment.

## What this discipline contributes

1. **A name for the missing half.** Most discussions of agent safety center on after-action observability (the receipt half). This document names the before-action half and treats them as a pair, not separate concerns.
2. **A checklist for tool descriptions.** Seven side-effect categories the description must address if any apply. Concrete, applicable to any MCP server or function-calling tool today.
3. **A lineage.** The discipline transfers from physical robotics (Kalinowski) and animation (Pixar) — older fields that already solved the human-in-the-loop trust problem at the actuator boundary. Software agents inherit the answer, not just the problem.

## Status

🟡 v1 — discipline written down. The `purchase_free_bundle` tool in [`fabianwilliams/adotob-mcp`](https://github.com/fabianwilliams/adotob-mcp) is the reference fixture; the post-fix tool description is the worked example of applying the discipline.

Future additions to this folder:

- A side-effect-checklist linter that scans MCP `tools/list` responses and flags tool descriptions that fail any of the seven categories.
- Worked examples from other agent tool kits (Stripe Agents, Cloudflare AI Gateway, Anthropic computer use) — pattern-matching their tool contracts against the checklist.

## Credits

Direct intellectual lineage:

- **Caitlin Kalinowski** for the Pixar-robot framing on Lenny Rachitsky's podcast (2026-05-17).
- **Pixar** for operationalizing announce-then-act in animation (Luxo Jr., 1986, and onward).
- **Stanislavski and Chekhov** for telegraphing as a discipline for live stage performers — the older root the Pixar pattern grew from.
