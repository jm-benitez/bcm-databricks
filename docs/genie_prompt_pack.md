# Genie prompt pack

Each row: the question, the partner and level it's scoped to, the table grain
that counts as a correct answer, and the decision file it checks. Ask these
through the `genie-check` skill's `databricks genie` commands against the
Space ID in `docs/genie_agent_instructions.md`, not through a direct SQL
command.

| Question | Partner + level | Table grain | Decision file checked | Status |
|---|---|---|---|---|
| Record-type counts per producer (SkyConnect, CoreConnect, Sonus SBC, Nectar Diagnostics) | — | Bronze, all partners at L0 | session-7 | Verified 2026-09-28 via Genie Space `01f1bb8f773317d18e3dd8177832e6f6`: "How many rows are in the nd_qsr table" → `SELECT COUNT(*) FROM nectar.dev_tqaddoumi_tqaddoumi_bronze.nd_qsr` → 1,167 rows. SkyConnect/Nectar Diagnostics Bronze tables are queryable the same way; CoreConnect/Sonus have no table yet. Genie also confirmed it refuses a table outside its attached set (tested with `samples.nyctaxi.trips`) |
| Hot-store field counts (SkyConnect 85 / CoreConnect 37) | — | Bronze | skyconnect-hot-cold-cut, coreconnect-37-field-scope | waiting on decision |
| Device events absent from Silver | — | Silver | session-1, session-7 | waiting on decision (no Silver table yet) |
| Registration alerts (type 2) present before a session exists | — | per-record | session-1 | waiting on decision |
| Session score (type 3) absent until Silver | — | Silver | session-1 | waiting on decision (no Silver table yet) |
| Late leg attached or explicitly unmatched | — | Silver | session-1 | waiting on decision (no Silver table yet) |
| Zero rows for a second partner at L1 and L2 | named partner, L1/L2 | any Gold rollup | session-5 | waiting on decision (no Gold table yet) |

When an answer is wrong, whoever noticed it updates this file, and
`docs/genie_agent_instructions.md` and the live Space's instructions in the
same change — a fix made only in the workspace UI is invisible to the next
reviewer (see `docs/ai_usage_strategy.md`, "Engineering Genie Agent").
