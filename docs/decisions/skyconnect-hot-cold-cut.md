# Decision: SkyConnect hot/cold field cut

Status: pending

Plan task: SkyConnect field reduction — 85 fields hot store vs. cold archive
(sits beside the discovery sessions; checked against Schema Registry once the
connector gate is open).

## Question this file must answer

Which of SkyConnect's full field set are the 85 hot-store fields kept in
Bronze, and which are archived cold? A Bronze column not on this list must not
appear in the hot-store table.

## Claude's preparation (draft only — not a decision)

Nothing drafted yet — the 85-field cut is a specific, signed list, not
something to infer from `nectar.bronze.skyconnect_raw`'s current columns.

## Sign-off

Not signed. Requires the solutions architect and project manager
(see docs/ai_usage_strategy.md, "Discovery").
