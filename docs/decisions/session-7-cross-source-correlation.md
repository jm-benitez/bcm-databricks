# Decision: Conversation Journey, cross-source correlation

Status: **SIGNED — TEST EXERCISE ONLY**

> This signature exists to rehearse this repo's AI usage strategy
> (`docs/ai_usage_strategy.md`). It is **not** a decision made by the actual
> BCM solutions architect or project manager. Before real Phase 2 development
> starts on the real `bcm` pipeline, this file must be re-signed by them.

Plan session: 7 — Conversation Journey, cross-source correlation

## Question this file must answer

How do SkyConnect, CoreConnect, and Sonus (or the confirmed producer list)
become one journey, including the synthetic `correlation_id`?

## Producers (reconciled)

The architecture diagram (Sonus SBC, CoreConnect, Nectar Diagnostics) and the
project plan (SkyConnect (NetSapiens), CoreConnect (Asterisk), Sonus SBC) are
not actually a conflicting producer list — they describe two layers. The
plan's subtitle ("SkyConnect · CoreConnect · Sonus SBC") names only the three
full-pipeline CDR/SIP/QoS sources and never names a fourth device-event
source. The diagram is the only place "Nectar Diagnostics" appears, and it's
explicit that its role is the DIRECT / Alert-Type-1 path, not the
enrich→stitch pipeline. So: the plan's three sources are the full-pipeline
session data, and the diagram's Nectar Diagnostics is a fourth,
device-event-only source layered on top. All four are real for this design.

| Producer | Feed | Cut / scope | Path |
|---|---|---|---|
| SkyConnect (NetSapiens) | CDR · SIP · QoS | 85 hot-store fields, rest cold-archived (see `skyconnect-hot-cold-cut.md`, still pending) | Full: enrich → score → stitch |
| CoreConnect (Asterisk) | CDR · SIP · QoS | 37-field mediation schema, multi-leg dedup (see `coreconnect-37-field-scope.md`, still pending) | Full: enrich → score → stitch |
| Sonus SBC | CDR · SIP · QoS | Bespoke timestamp parser, normalized to UTC | Full pipeline; joined into the SkyConnect+CoreConnect Silver session via a synthetic `correlation_id` |
| Nectar Diagnostics | Endpoint/device health, device events embedded in the feed | n/a | DIRECT — Alert Type 1 only. Does **not** go through enrich, score-for-Silver, or Silver stitching |

Corroboration found in the live dev workspace: `nectar.bronze` already has
tables named `skyconnect_raw` and `nectar_da_avro_raw` ("Nectar Diagnostics
Avro raw"), and `nectar.dev_tqaddoumi_tqaddoumi_bronze` has `nd_qsr`. That's
consistent with SkyConnect and Nectar Diagnostics both already landing data
under this reconciliation — it isn't proof the reconciliation is correct, but
it's evidence in its favor.

## Synthetic correlation_id

Formula: **not specified here.** This file signs the producer list and each
producer's role only. The correlation-key formula itself is a genuine
discovery output (see `docs/ai_usage_strategy.md`: "The BCM correlation key is
a discovery output, not `correlation_ids[1]`") and is not invented in this
file. Any code that needs it must stop and name this gap until a follow-up
decision fills it in.

## What is still open

- The synthetic `correlation_id` formula.
- Both field-scope decisions (`skyconnect-hot-cold-cut.md`,
  `coreconnect-37-field-scope.md`) — still pending.
- CoreConnect and Sonus Bronze tables don't exist yet in `nectar.bronze`
  today; only SkyConnect and Nectar Diagnostics data has landed so far.

## Sign-off

Signed for this test exercise by the repo owner, 2026-09-28. Not a substitute
for the real solutions architect / project manager sign-off required before
Phase 2 (see `docs/ai_usage_strategy.md`, "Discovery").
