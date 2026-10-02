# Architecture and design choices

This is the running record of the architecture and design choices for the BCM
CDR pipeline. It is updated before and during development, in the same pull
request as the change that depends on a choice. A choice is usable once it is
written here; it can be revised here as development teaches the team more.

Claude Code treats this file and the other design docs under `docs/` as the
source of truth (see `CLAUDE.md`). Where a choice is not recorded, Claude stops
and says what is missing instead of filling the gap.

## Producers and pipeline paths

This section records only what the architecture diagram (`docs/cdr_architecture_V1.html`, v3.2-A) shows. The rest is in Open design topics until it is confirmed.

Producers in the diagram:

| Producer | What the diagram shows it sending |
|---|---|
| Sonus SBC | CDR · SIP · QoS per leg per call |
| CoreConnect | CDR · SIP · QoS per leg per call |
| Nectar Diagnostics | Endpoint session · device health · QoS. Device events are embedded within the existing feed |

Kafka topics in the diagram: `cdr_sbc`, `cdr_uc`, `sip_messages`, `qos_streams`, `nd_sessions`. Device events are embedded within the existing topics, with no separate feed.

Paths, which Bronze assigns by **record type**, not by producer:

- **Device events** take the direct path (alert type 1): no enrichment or stitching, then device SCORE, then Redis.
- **CDR, SIP and QoS records** go through ENRICH → SCORE → SILVER.
- **Nectar Diagnostics sessions** are not excluded from enrich and Silver. Only device-event records take the direct path, wherever they come from.

Not yet confirmed, and not recorded as design: the full producer list (`docs/ai_usage_strategy.md` says the plan names SkyConnect (NetSapiens), CoreConnect (Asterisk) and Sonus SBC, which has not been checked against the plan here), how that list reconciles with the diagram, and which producers have Bronze tables today.

## Open design topics

These are the topics the design still has to record. Add each one to this file
(or to its own doc under `docs/`) when it is made, and remove it from this list.
"Claude's preparation" is what Claude may draft beforehand; it is a draft, not
a choice.

| Topic | What the design needs to record | Claude's preparation |
|---|---|---|
| Stitching, session definition, SIP leg rules | What a session is, which legs belong, what stays unmatched | Pattern note from `pr_ncj_build_diagnostics` and `pr_ncj_build_avaya` |
| Enrichment: geo, carrier, codec, tagging | Which reference joins are in Phase 1, including carrier | Join list from `i_uplatforms`, with carrier marked absent from the realtime database |
| Existing Nectar alert types | What the current worker already fires | Outline of score and threshold functions in the realtime database, for the reviewer to confirm |
| Thresholds, windows, routing | Threshold table fields, windows, cooldown, EventBridge route per alert type | Empty key-design template: namespace, TTL, idempotency key |
| L0/L1/L2, partners and customers | The three-level row filter and who sits at each level | Nothing from the realtime database. Tenancy there is one schema per tenant, which is a different model |
| Conversation Journey, cross-source correlation | How SkyConnect, CoreConnect, and Sonus become one journey, including the synthetic `correlation_id` formula (not specified yet; code that needs it stops and says so) | The Avaya + Diagnostics stitch as a pattern, with its keys stripped out |
| Reporting | The 4–5 rollups and 3–4 dashboards, at L0/L1/L2 | Candidate grains from `pr_ncj_summary_build` and the QuickSight questions, labeled as candidates |
| SkyConnect hot/cold cut | Which of SkyConnect's full field set are the 85 hot-store fields kept in Bronze, and which are archived cold. A Bronze column not on the list must not appear in the hot-store table. Checked against Schema Registry | None. The cut is a specific list, not something to infer from the current columns of `nectar.bronze.skyconnect_raw` |
| CoreConnect 37-field scope | Which 37 fields make up the CoreConnect (Asterisk) mediation schema, and the multi-leg dedup rule. Checked against Schema Registry | None. No CoreConnect table exists in `nectar.bronze` yet |
| UI requirements | Owned outside the AI usage strategy. Becomes an input when it changes a Lakebase query | None |
