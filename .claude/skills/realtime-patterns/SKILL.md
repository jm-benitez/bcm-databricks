---
name: realtime-patterns
description: Use when someone asks how Nectar does this today, or wants a pattern from the realtime database before the design docs cover it.
---

The realtime database (`realtimedb/`, a separate, read-only checkout — never
edit it) is Nectar's current PostgreSQL store. It already implements
enrichment, stitching, and analytics for the unified-communications platforms
it models. It does not contain SkyConnect, CoreConnect, Sonus, carrier
tables, or the SIP-leg rules for those feeds — read it as a pattern library,
not as the BCM field mapping.

| Logic in the realtime database | Pattern worth keeping | Where it lands in v3.2-A | Rule |
|---|---|---|---|
| `pr_u_dm_build_*` and the dictionary lists on `i_uplatforms` (codec, response codes, geo from IP, users, client version, devices, platform servers) | Enrich by joining a session to reference data, per platform | ENRICH, broadcast / Delta joins | Extract the join list into a design note. Carrier and route are not in the realtime database; do not add them until the design records them. |
| `pr_ncj_build_diagnostics` | Group legs by `correlation_id` (stitching type 1). Merge a single-leg group into another journey on `ucd_correlation_id` (stitching type 3). Skip legs already attached to another journey. | SILVER session assembly, unmatched and late records | Use the two-step shape. The BCM correlation key is a design output, not `correlation_ids[1]`. |
| `pr_ncj_build_avaya` (`AVAYA_NECTAR_DIAGNOSTICS`) | Two sources, clock skew (`fn_svc_ncj_avaya_nd_time_shift`), optional stitch by user, a buffer for related sessions | SILVER cross-source correlation — the plan's version is SkyConnect + CoreConnect assembly, then Sonus joined with a synthetic `correlation_id` | Cite it as the existing cross-source stitch. Do not copy Avaya or Diagnostics keys onto the plan's sources, and do not invent the synthetic id. |
| `pr_ncj_load`, `pr_ncj_summary_build`, `pr_summary_dm_build` | Build journeys, then a summary grain, on a schedule with chunking and run logs | GOLD | Draft aggregates only after the design records that grain. |
| Nectar score functions and threshold configuration | A score and a threshold exist as data, not as constants in a query | SCORE, the threshold table, alert type 3 | Implement scoring from the threshold spec in the design docs. |
| QuickSight definitions | Questions the current UI already asks | A question to ask the engineering Genie Agent | Turn a question into a regression prompt. Do not port the SQL dialect unchanged. |

Extract a pattern as a note (join list, stitch shape, scoring shape) — never
as a finished field mapping or correlation key for BCM. A human decides which
patterns survive.
