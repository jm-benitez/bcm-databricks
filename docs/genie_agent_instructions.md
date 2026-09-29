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
- Never return a raw phone number, SIP URI, or other subscriber identifier in
  an answer; aggregate or mask it instead.
- Example questions: see `docs/genie_prompt_pack.md`.

<!-- TODO once more Bronze/Silver/Gold tables land in nectar.bronze/silver/gold:
     replace "not yet created" notes above with the real table names, attach
     them to the Space in this order: Bronze classified records, enriched
     records, Silver sessions, Gold rollups, the threshold table, and the
     reference Delta tables — per docs/ai_usage_strategy.md, "Engineering
     Genie Agent". -->

## How to create a Genie Space for the AI setup

The Genie Space is a Databricks workspace object. It is separate from the
`databricks` Claude Code plugin (the CLI AI-tools) — creating one installs
nothing locally, and installing the plugin creates no Space. The plugin's
`databricks-genie-agents` skill is what lets Claude Code manage and query it.

Rules from `docs/ai_usage_strategy.md`, "Engineering Genie Agent", that apply
every time:

- One Space, in the **dev** workspace, on a **serverless SQL warehouse**.
- Attach tables only after they exist, only from the dev scope in `CLAUDE.md`
  ("Databricks dev scope"). No production catalog, no Kafka, no Redis.
- Share it with data engineers and QA. Each person asks as themselves, so
  Unity Catalog row filters apply to them.
- Seed the instructions from the "Instructions" section above. This file is
  the reviewed copy; the workspace Space is what runs.

Steps:

1. **Pick the profile and warehouse.** Pass `--profile <name>` explicitly and
   let the user choose it. List serverless warehouses with
   `databricks warehouses list` and note the warehouse ID.
2. **Confirm the tables exist** and are inside the dev scope, e.g.
   `databricks tables get <catalog.schema.table>`.
3. **Prefer starting from a UI-created Space.** `serialized_space` is not
   documented for hand-authoring. The safest route is to create the Space once
   in the workspace UI, then export its definition with
   `databricks genie get-space <SPACE_ID> --include-serialized-space -o json`
   and reuse that JSON as the template.
   Building it by hand, as below, worked on 2026-09-28 but is unverified
   against the documented schema.
4. **Write the `serialized_space` JSON** to a scratch file outside the repo.
   Shape used for this Space (`version` 2):

   ```json
   {
     "version": 2,
     "config": {"sample_questions": [{"id": "<32 hex chars>", "question": ["…"]}]},
     "data_sources": {"tables": [{"identifier": "<catalog.schema.table>"}]},
     "instructions": {"text_instructions": [{"id": "<32 hex chars>", "content": ["one instruction per string, ending in \\n"]}]}
   }
   ```

   Each `id` is a 32-character hex string, unique within its list. Copy the
   instruction text from the "Instructions" section above.
5. **Create a workspace folder and the Space.** The JSON body carries the
   warehouse, title, folder, and the serialized space as a JSON *string*:

   ```bash
   databricks workspace mkdirs <PARENT_PATH>
   databricks genie create-space --json "{
     \"warehouse_id\": \"<WAREHOUSE_ID>\",
     \"title\": \"<TITLE>\",
     \"description\": \"<scope, e.g. dev tables only; see CLAUDE.md>\",
     \"parent_path\": \"<PARENT_PATH>\",
     \"serialized_space\": $(jq -c '.' space.json | jq -Rs '.')
   }" -o json
   ```

   The response carries the Space ID.
6. **Record it here.** Update the "Genie Space ID" paragraph at the top of this
   file (ID, title, date, warehouse, folder) and the "Tables attached" list.
   The `genie-check` skill has nothing to check against until this is done.
7. **Verify** with the Section 1 steps of
   `docs/databricks_validation_checklist.md`: `get-space` returns the expected
   tables, and a question about an attached table completes.
8. **Share** the Space with the engineers and QA who will ask questions.

Afterwards, change the live Space only through `databricks genie update-space`
in the same PR that changes this file. A fix made only in the workspace UI is
invisible to the next reviewer.

## How this Space was created

Reconstructed on 2026-09-28 from the Claude Code session that created it; the
repo had no record of the steps before this section.

- **When:** 2026-09-28, about 22:53 UTC, in a Claude Code session driven by
  `juan.benitez@dbseer.com`. An earlier `databricks genie list-spaces` call in
  the same session checked what existed first.
- **Method:** the CLI, not the UI, following the steps above with no UI export
  step. The `serialized_space` JSON was written by hand to a scratch file
  (`/tmp/bcm_genie_space.json`, not kept in the repo).
- **Folder:** `/Workspace/Users/juan.benitez@dbseer.com/genie_spaces`, created
  with `databricks workspace mkdirs`. This is a personal path. A shared path
  is a better home before other engineers rely on the Space.
- **Warehouse:** `Serverless Starter Warehouse`, ID `431f6c2d74d114de`.
- **Title / description:** "BCM Engineering (dev)"; "Engineering Genie Agent
  for the BCM CDR pipeline (bcm-databricks practice repo). Scoped to dev tables
  only: nectar.bronze, nectar.dev_tqaddoumi_tqaddoumi_bronze. See CLAUDE.md in
  the repo."
- **Attached tables:** the four listed under "Tables attached" above.
- **Seeded content:** two sample questions (row counts of the SkyConnect and
  Nectar Diagnostics raw tables; the columns and types of `nd_qsr`) and one
  instruction block. That block is a shorter version of the "Instructions"
  section above. It also tells the agent not to answer session, alert-type,
  score, or L0/L1/L2 questions until the matching tables or decisions exist,
  and never to return a raw phone number, SIP URI, or other subscriber
  identifier.

**Instructions synced 2026-09-29:** the live Space's instruction block was
replaced with the "Instructions" section above, via `databricks genie
update-space` with the exported `etag`. Tables, sample questions, title,
warehouse and folder were left unchanged. The live text is that section with
one adaptation, because the agent cannot read the repo: the pointers to
`docs/genie_prompt_pack.md` and `databricks tables get` were dropped. The
identifier rule is now in both copies. Wording may drift again on the next
edit, so diff with `databricks genie get-space <SPACE_ID>
--include-serialized-space` when in doubt.
