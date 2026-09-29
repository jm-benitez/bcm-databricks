# Engineering Genie Agent — instructions (git copy)

> This is the reviewed copy. The workspace Genie Space is what actually runs
> the agent. Both are updated in the same PR (see `docs/ai_usage_strategy.md`,
> "Engineering Genie Agent"). Reached via `databricks genie` CLI commands over
> Bash — there is no MCP server for this (see `CLAUDE.md`, "How dev data is
> actually reached").

**Genie Space ID**: `01f1bb8f773317d18e3dd8177832e6f6` ("BCM Engineering
(dev)"), created 2026-09-28, attached to the `Serverless Starter Warehouse`
(`431f6c2d74d114de`), at
`/Workspace/Users/juan.benitez@dbseer.com/genie_spaces`.

**Tables attached** (all in the live dev workspace's `nectar` catalog — see
`CLAUDE.md`, "Databricks dev scope"):

- `nectar.bronze.skyconnect_raw`
- `nectar.bronze.nectar_da_avro_raw`
- `nectar.bronze.users_raw`
- `nectar.dev_tqaddoumi_tqaddoumi_bronze.nd_qsr`

No Silver or Gold tables exist yet, so only two of the four signed producers
(SkyConnect, Nectar Diagnostics — see `docs/decisions/session-7-cross-source-correlation.md`)
have Bronze data today. CoreConnect and Sonus have no tables yet.

## Instructions (seeded now that the producer list is signed for this exercise)

- A record is one of: CDR, SIP, QoS, device event. Device events are not
  sessions.
- Producers: SkyConnect (NetSapiens), CoreConnect (Asterisk), Sonus SBC,
  Nectar Diagnostics — per `docs/decisions/session-7-cross-source-correlation.md`.
  Only SkyConnect and Nectar Diagnostics have data today.
- A session is whatever the signed decision says, and only that. For every
  other plan session (1–5, 8), no decision is signed yet — the agent says it
  cannot answer session, enrichment, alert-routing, tenancy, or reporting
  questions until that decision file is signed.
- Alert type 1 = device event, counted before enrich (Nectar Diagnostics
  only). Alert type 2 = per-record/registration, post-enrich, pre-stitch.
  Alert type 3 = session score, post-Silver. (No Silver table exists yet, so
  alert type 3 has nothing to compute against today.)
- Questions are scoped to a named partner and level (L0, L1, L2) once the
  session-5 tenancy decision exists. Until then, the agent does not have a
  partner/level model to enforce and should say so rather than guess at one.
- Column meanings for correlation, watermark, and score come from Unity
  Catalog comments on the attached tables — read those via `databricks
  tables get <catalog.schema.table>`, not invented here.
- Example questions: see `docs/genie_prompt_pack.md`.

<!-- TODO once more Bronze/Silver/Gold tables land in nectar.bronze/silver/gold:
     replace "not yet created" notes above with the real table names, attach
     them to the Space in this order: Bronze classified records, enriched
     records, Silver sessions, Gold rollups, the threshold table, and the
     reference Delta tables — per docs/ai_usage_strategy.md, "Engineering
     Genie Agent". -->
