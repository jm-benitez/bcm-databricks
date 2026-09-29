---
name: decision-check
description: Use when a change touches classification, enrich, stitching, score, thresholds, or partner filters.
---

The design in this repo — the design note plus `docs/decisions/*.md` — is what
to implement. A discovery note under `docs/decisions/` explains a choice the
design hasn't absorbed yet.

Before writing or changing classification, enrich, stitching, score,
threshold, or partner-filter logic:

1. Find the decision file for the plan session that governs this change (see
   the session table in `docs/ai_usage_strategy.md`, "Lifecycle → Discovery").
2. If it exists and is signed, implement exactly what it says — no
   generalizing from a realtime-database procedure that isn't cited in it.
3. If it exists but is still `Status: pending`, stop and say which decision
   file is pending and what question in it blocks this change.
4. If no file exists for the session, stop and name the missing session by
   number and title instead of proceeding.

The one exception in this repo: `docs/decisions/session-7-cross-source-correlation.md`
is signed as a labeled test-exercise decision, not a real sign-off — treat it
as usable for this practice repo, but say so if asked whether it's final.

Never mark a discovery question answered by generalizing from Avaya, Genesys,
Webex Calling, or Diagnostics procedures, and never pick SkyConnect over
Nectar Diagnostics (or the reverse) to fill a gap — that choice already exists
in the session-7 decision file.
