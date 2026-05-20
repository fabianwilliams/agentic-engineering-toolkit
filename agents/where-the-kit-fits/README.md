# Where the Agent Reliability Kit Fits

> An architectural map. The Kit is the **observability control point** that pairs with whichever runtime, identity, data, and write-access stack a partner has already chosen.

---

> **By the end of this doc you will know which production-agent decisions the Kit replaces, which it complements, and which it leaves to the partner. The point is to stop selling "buy our methodology" and start positioning as "your stack plus our control point equals production-ready."**

---

## The five-control-point landscape

Per Nate B Jones's 2026-05-20 framework (see `knowledge/wiki/concepts/five-agent-control-points.md` in the upstream wiki), every production-shipping agent workflow has to answer for five infrastructure layers, plus a kill switch that crosses all of them:

| Layer | Question it answers | Operators in 2026 |
|---|---|---|
| **Runtime** | Where does the agent live and run? | Cloudflare Agents SDK (Durable Objects), AWS Bedrock AgentCore, Vercel AI Gateway |
| **Identity** | Who is the agent acting for? | Auth0 / Okta for AI Agents, WorkOS, Microsoft Entra Agent ID, AWS AgentCore Identity |
| **Data** | What can the agent know? | Snowflake Cortex Agents, Databricks, governed semantic layers |
| **Tool / write access** | What can the agent change, with what blast radius? | (cross-cutting; lives in tool registries and MCP tool descriptions) |
| **Observability** | What did the agent actually do? | Datadog LLM, Arize, custom audit-trail patterns |

The kill switch is multilayer (runtime cancel + identity revoke + gateway block + payment freeze + workflow interrupt). Most teams ship with one layer and call it "human in the loop." Per the `multilayer-kill-switch` discipline, that is not a kill switch; it is a prompt.

## Where the Kit sits

The Agent Reliability Kit sits on the **observability control point**. It does not compete with the other four layers; it sits underneath whichever choices the partner has already made.

| Layer | Kit's role | What the partner chooses |
|---|---|---|
| Runtime | none | Cloudflare / AWS / Vercel / custom |
| Identity | none directly; the Kit's `announce-intent-before-action` discipline references the scopes the identity layer enforces | Auth0 / Okta / WorkOS / Entra / AgentCore Identity |
| Data | none | Snowflake Cortex, Databricks, etc. |
| Tool / write access | the Kit defines the **side-effect-enumeration discipline** the tool description must follow (see `agents/announce-intent-before-action`) | partner's tool registry |
| **Observability** | **the audit-trail receipt + the announce-intent-before-action discipline are the Kit's contribution at this layer** | partner picks whether to use the Kit or a competing approach |
| Kill switch (cross-cutting) | the Kit's six runtime checks (input validation, rate limit, daily cost ceiling, lead capture, download token, fulfillment dispatch) participate in the workflow-interrupt and spend-ceiling layers of the multilayer kill switch | the other kill-switch layers live in the partner's runtime + identity + payment choices |

This positioning is intentional. The methodology compounds the partner's existing stack instead of asking them to rip and replace.

## How the Kit pairs with each layer

### Runtime

The Kit's reference implementation (`fabianwilliams/adotob-mcp`) runs on Azure Static Web Apps. That is one runtime choice; it is not a recommendation. Partners running on Cloudflare Agents SDK will gain Durable Objects' stateful execution; partners on AWS Bedrock AgentCore will gain bundled memory, identity, and observability primitives. Either way, the audit-trail receipt shape and the six-check pattern travel.

**What does not travel**: the Azure-specific code (`@azure/data-tables`, `@azure/storage-blob`). Partners port the receipt-store and rate-limit modules to their chosen runtime's equivalents.

### Identity

The Kit does not ship an identity layer. The reference implementation has zero auth on the free-trial bundle endpoint. That is fine for a public demo with rate-limit + cost-ceiling gating; it is *not* production-ready for a partner deploying the Kit on top of their client engagements.

For production deployments, the Kit pairs with [[Delegated Authority with Constraints]] (the Auth0 / Okta pattern). See `samples/auth0/` in the `adotob-mcp` repo for a reference integration. The pattern:

- User authentication establishes the human principal
- OAuth-based API access with scoped tokens (not session cookies)
- Token vault keeps secrets out of the agent context
- Asynchronous authorization for sensitive operations
- Fine-grained authorization for RAG (if the partner has retrieval)

The Kit's **announce-intent-before-action** discipline (`agents/announce-intent-before-action`) names the side-effects the identity layer's scopes need to enforce. The 7 categories the discipline enumerates (data, identity, communication, issuance, public, money, trigger) map cleanly onto Auth0's per-scope permission grants.

### Data

The Kit has no opinion on the data layer. Partners running on Snowflake Cortex Agents or Databricks already have governed semantic layers; the Kit's tool descriptions document which data the agent reads or writes, in compliance with the partner's data-governance rules.

### Tool / write access

This is where the Kit's **announce-intent-before-action** discipline does its primary work. The 7-category side-effect checklist (data, identity, communication, issuance, public, money, trigger) IS the tool-write-access discipline. Every tool description in the Kit must enumerate every side-effect or fail the checklist.

### Observability

The Kit's audit-trail receipt is the deliverable at this layer. A consumer-readable, public, JOSE-signed receipt URL that shows every supervision check that fired, with timestamps and pass/fail/skip/warn status. This is the property a CISO or CFO can forward to their compliance team without privileged access.

The receipt format is intentionally portable. Partners porting the Kit to Cloudflare or AWS keep the receipt JSON shape and the public-URL pattern; only the storage backend changes (Cloudflare R2 instead of Azure Blob, S3 instead of Azure Blob, etc.).

### Kill switch participation

The Kit's six runtime checks each contribute to the multilayer kill switch:

| Kit check | Kill-switch layer it participates in |
|---|---|
| `input_validation` | workflow interrupt (refuse the run before any side-effect fires) |
| `rate_limit` | workflow interrupt + spend ceiling (refuse the call when over budget) |
| `cost_ceiling` | spend ceiling (refuse when daily cap hit) |
| `brevo_contact_upsert` | identity-layer revoke point (Brevo's API can revoke the contact) |
| `download_token_mint` | identity-layer revoke point (token can be revoked or expired) |
| `fulfillment_dispatch` | last-line-of-defense layer (Brevo can suspend the sender) |

The other kill-switch layers (runtime cancel, gateway block, payment freeze) live in the partner's choice of runtime + gateway + payment stack. The Kit does not provide them; it documents how to slot the Kit's checks into the partner's existing layers.

## What this means for partner conversations

The pitch is not "buy our methodology." The pitch is:

> Whichever runtime you picked, whichever identity provider you picked, whichever data platform you picked, your agents need a consumer-readable audit trail that satisfies both security review and finance review. The Agent Reliability Kit ships that observability primitive in a way that ports across your stack. You keep your runtime, identity, data, and gateway choices. We add the receipt.

That positioning collapses three procurement objections at once:

1. **"We are not a Claude shop."** The Kit is protocol-neutral; the storefront proves it (hosted Claude + local Qwen 27B both produce the same receipt). Your model choice is yours.
2. **"We already use Auth0 / Okta / Entra."** The Kit slots under your identity layer; the announce-intent discipline names the scopes your identity layer enforces.
3. **"We are on Cloudflare Agents / Bedrock AgentCore / Vercel AI Gateway."** The Kit ports across runtimes; only the storage backend module changes.

## Status

v1, written 2026-05-20 in response to Nate B Jones's `Five Agent Control Points` framework. Positions the Kit explicitly as the observability layer that pairs with the partner's stack.

## Credits

- **Nate B Jones**: Five Agent Control Points + multilayer kill switch + the seven production-agent questions diagnostic, 2026-05-20 video "These 5 Companies Secretly Control AI." His framework is the architectural map this doc sits on top of.
- **Auth0 / Ozero**: the delegated-authority-with-constraints pattern this doc cites at the identity layer. Their AI Agents docs are the canonical reference.
