---
name: design-check
description: Use when a change touches classification, enrich, stitching, score, thresholds, or partner filters.
---

The design in this repo — the architecture and design docs under `docs/`,
starting with `docs/architecture_and_design_choices.md` — is what to
implement. Those docs are updated before and during development, so a choice
may be recorded after the first draft of a change.

Before writing or changing classification, enrich, stitching, score,
threshold, or partner-filter logic:

1. Find the design doc that covers this change: `docs/architecture_and_design_choices.md`
   and any other doc under `docs/` that names the stage.
2. If it covers the change, implement what it says — no generalizing from a
   realtime-database procedure that the doc does not cite.
3. If it does not cover the change, stop. Say what is missing (for example the
   correlation key, a field list, or a threshold) and propose the text to add
   to the design docs. The engineer decides what is recorded; do not fill the
   gap yourself.

Never mark a design question answered by generalizing from Avaya, Genesys,
Webex Calling, or Diagnostics procedures, and never pick SkyConnect over
Nectar Diagnostics (or the reverse) to fill a gap. What the architecture diagram
shows about producers and paths is in `docs/architecture_and_design_choices.md`.
