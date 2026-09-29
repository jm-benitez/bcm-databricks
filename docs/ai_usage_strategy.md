# AI usage strategy — BCM CDR pipeline

Followed by: data engineers and QA.
Reviewed by: the solutions architect and the project manager.
Pipeline repository: GitLab project `bcm`. It already exists and is not in use yet.
Existing enrichment and stitching: the Nectar realtime database (`realtimedb`), a separate codebase. Read it for patterns. Do not change it.
Target architecture: Real Time CDR Enrichment, Stitching & Analytics Architecture, v3.2-A.
Schedule, scope, and acceptance: BCM One — Nectar DXP project plan, 14 Sep 2026 – 25 Jan 2027.

Data engineers and QA follow this document on every `bcm` change. It says which tool does which job, which logic in the realtime database Claude may learn from, and which rules apply from the first merge request. The solutions architect and the project manager review it, including the two decisions in the next section.

## Decisions still open

Two items are proposed below. They stay as written until the solutions architect and the project manager accept or replace them with the engineers and QA.

1. **What may be sent to a model.** Proposed default in [Data boundary](#data-boundary).
2. **Whether the automated review blocks a merge.** Proposed default: it comments only. A human approval is still required. The job does not reject the pipeline by itself.

## What this covers

Data engineers and QA use three tools while building the v3.2-A pipeline in `bcm`:

| Tool | Where it runs | What it is for |
|---|---|---|
| Claude Code | The `bcm` repo on a laptop, connected to Databricks | Discovery notes, design, pipeline code, tests |
| Claude review job | GitLab CI on `bcm` merge requests | A written review against the rules in this document |
| Notebook assistant | Databricks SQL editor and notebooks | One-off SQL while exploring dev tables |

The engineering Genie Agent is the data side of that workflow. Claude Code reaches it through Databricks’ Genie connector. People also open the same agent in the workspace and ask questions directly.

Operator-facing Genie, the box already drawn on the architecture, is a later product task. This strategy does not define it.

## Glossary

- **Genie Agent.** A saved Databricks chat aimed at a fixed list of Unity Catalog tables, plus written instructions and example questions. Databricks used to call this a Genie space. The engineering agent for this project sees dev tables only.
- **Claude Code.** Anthropic’s coding agent, run in the `bcm` checkout. It edits files and opens the work as a merge request.
- **Notebook assistant.** The chat inside the Databricks SQL editor and notebooks. Databricks places developer code help under Genie Code. For this strategy it is only an ad-hoc SQL aid.
- **MCP.** The connector protocol. Claude Code uses Databricks’ managed Genie connector to ask the engineering agent, and the Unity Catalog connector to read table and column comments. The agent runs the SQL. Claude does not receive a warehouse password.
- **Unity Catalog.** The permission layer. A Genie answer can only use tables attached to that agent, and only rows the asking identity is allowed to see.

## Source of truth

The design and architecture kept in `bcm` is the source of truth. The project plan and architecture v3.2-A are not added to that repo.

Claude still reads the realtime database procedures. They are the evidence of how Nectar stitches and enriches today, and the new pipeline should mirror that behavior where the design carries it forward. When a procedure and the design disagree, the design wins.

The plan and v3.2-A are how this strategy was scoped. The design in `bcm` is where that scope is written down for Claude. Until the design records them, Claude does not invent them:

- Producers and schemas. The diagram names Sonus SBC, CoreConnect, and Nectar Diagnostics. The plan names SkyConnect (NetSapiens), CoreConnect (Asterisk), and Sonus SBC, with a connector gate that all three are writing to Kafka with `customer_id` and `datacenter_id` (Sonus: tenant context fields) and schemas confirmed in Schema Registry. Bronze work on the plan is SkyConnect reduced to 85 hot-store fields, CoreConnect at 37 fields with multi-leg dedup, and a Sonus timestamp parser that normalizes to UTC.
- Correlation. Silver on the plan assembles SkyConnect with CoreConnect, and correlates Sonus with a synthetic `correlation_id`.
- Tenancy. Unity Catalog is three levels, L0/L1/L2, for about 2,700 partners and 90,000 customers. Row filters follow that hierarchy, not a single `tenant_id` check.
- Enrichment. The plan’s enrich list is hierarchy, geo, carrier, and codec, with hot reload. Carrier is on the plan and absent from the realtime database.
- Acceptance. Cross-source stitching has signed test scenarios. Phase 2 QA covers schema mapping for all three CDRs, stitching, alert types 1–3, L0/L1/L2 isolation, a 48-hour run at 35 million records a day, and an end-to-end pass. Phase 3 adds live completeness, leg counts, and correlation rates. Lakebase is a 60-second SLA and 90-day partitions.

Until the producer list is confirmed, Claude may discuss the pipeline shape and may extract patterns from the realtime database. It may not invent field mappings, the 85-field or 37-field cut, correlation keys, or Genie instructions for a named producer.

## What Claude may learn from the realtime database

The realtime database is Nectar’s current PostgreSQL store. It already implements enrichment, stitching, and analytics for the unified communications platforms it models. It does not contain SkyConnect, CoreConnect, Sonus, carrier tables, or the SIP-leg rules for those feeds. Claude reads it as a pattern library. A human decides which patterns survive for BCM.

| Logic in the realtime database | Pattern worth keeping | Where it lands in v3.2-A | Rule for Claude |
|---|---|---|---|
| `pr_u_dm_build_*` and the dictionary lists on `i_uplatforms` (codec, response codes, geo from IP, users, client version, devices, platform servers) | Enrich by joining a session to reference data, per platform | ENRICH, broadcast / Delta joins | Extract the join list into a design note. Carrier and route are not in the realtime database; do not add them until discovery confirms them. |
| `pr_ncj_build_diagnostics` | Group legs by `correlation_id` (stitching type 1). Merge a single-leg group into another journey on `ucd_correlation_id` (stitching type 3). Skip legs already attached to another journey. | SILVER session assembly, unmatched and late records | Use the two-step shape. The BCM correlation key is a discovery output, not `correlation_ids[1]`. |
| `pr_ncj_build_avaya` (`AVAYA_NECTAR_DIAGNOSTICS`) | Two sources, clock skew (`fn_svc_ncj_avaya_nd_time_shift`), optional stitch by user, a buffer for related sessions | SILVER cross-source correlation. The plan’s version of this task is SkyConnect + CoreConnect assembly, then Sonus joined with a synthetic `correlation_id` | Cite it as the existing cross-source stitch. Do not copy Avaya or Diagnostics keys onto the plan’s sources, and do not invent the synthetic id. |
| `pr_ncj_load`, `pr_ncj_summary_build`, `pr_summary_dm_build` | Build journeys, then a summary grain, on a schedule with chunking and run logs | GOLD. The plan fixes Phase 1 at 4–5 rollup views and 3–4 dashboards, each at L0, L1, and L2 | Draft aggregates only after session 8 signs that grain. |
| Nectar score functions and threshold configuration in the realtime database | A score and a threshold exist as data, not as constants in a query | SCORE, the threshold table, alert type 3 | Implement scoring from a signed threshold spec. |
| QuickSight definitions in the realtime database | Questions the current UI already asks | The engineering Genie prompt pack | Turn a question into a regression prompt. Do not port the SQL dialect unchanged. |

Alert workers, Redis, and EventBridge stay as they are. The plan’s discovery task for that area is a review of the existing Nectar alert worker and a key design (namespaces `device`, per-record, per-session; cooldown; leader election; EventBridge routing by alert type). Claude may draft that design from notes a human took in sessions 3 and 4. It does not redesign the workers in this phase.

## How the three tools split the work

Claude Code writes and changes files in `bcm`. The notebook assistant answers a single SQL question in the workspace and does not commit. The review job reads a merge request and posts one comment.

Genie is how any of them look at rows. An engineer asking “how many device events took the fast path in dev yesterday?” uses the engineering agent, in the workspace or from Claude Code. They do not paste result sets into a Claude chat.

## Lifecycle

### Discovery

This is Phase 1 of the project plan (14–28 Sep 2026). The solutions architect and the project manager run the sessions. Data engineers and QA use Claude to prepare and to file what the session decided. Claude does not attend for them, and it does not close a session.

Each session becomes one decision file in `bcm/docs/decisions/` before any build task that depends on it:

| Plan session | Decision file records | Claude’s preparation |
|---|---|---|
| 1 — Stitching, session definition, SIP leg rules | What a session is, which legs belong, what stays unmatched | Pattern note from `pr_ncj_build_diagnostics` and `pr_ncj_build_avaya` |
| 2 — Enrichment: geo, carrier, codec, tagging | Which reference joins are in Phase 1, including carrier | Join list from `i_uplatforms`, with carrier marked absent from the realtime database |
| 3 — Existing Nectar alert types | What the current worker already fires | Outline of score and threshold functions in the realtime database, for the reviewer to confirm |
| 4 — Thresholds, windows, routing | Threshold table fields, windows, cooldown, EventBridge route per alert type | Empty key-design template: namespace, TTL, idempotency key |
| 5 — L0/L1/L2, partners and customers | The three-level row filter and who sits at each level | Nothing from the realtime database. Tenancy there is one schema per tenant, which is a different model |
| 6 — UI requirements | Owned outside this strategy. The file is an input when it changes a Lakebase query | No Claude session for the UI team under this document |
| 7 — Conversation Journey, cross-source correlation | How SkyConnect, CoreConnect, and Sonus (or the confirmed producer list) become one journey, including the synthetic `correlation_id` | The Avaya + Diagnostics stitch as a pattern, with its keys stripped out |
| 8 — Reporting | The 4–5 rollups and 3–4 dashboards, at L0/L1/L2 | Candidate grains from `pr_ncj_summary_build` and the QuickSight questions, labeled as candidates |

Two plan tasks sit beside the sessions and also need a decision file: the SkyConnect cut from the full feed to 85 hot-store fields (the rest archived cold), and the CoreConnect mediation levels that define the 37-field schema. Schema Registry review of all three CDR schemas is the check that those files match the topics.

Claude Code may:

- Draft the pattern note and the question list for a session before it happens.
- After a human writes the outcome, file it under `bcm/docs/decisions/` and fold it into the design. The design is the source of truth.

Claude Code may not mark a discovery question answered by generalizing from Avaya, Genesys, Webex Calling, or Diagnostics, and it may not pick SkyConnect over Nectar Diagnostics or the reverse.

QA starts the Genie prompt pack in this phase, on paper, from the plan’s acceptance rows: classification and field mapping, enrich, each alert type, stitched session, unmatched legs, late legs, and a second partner invisible at L1/L2. The pack moves into the agent when dev tables exist.

### Design

Claude Code drafts the pipeline layout to match v3.2-A, and only that layout:

- Structured Streaming from Kafka, DLT (SDP), continuous mode, autoscale on consumer lag.
- BRONZE deserializes and classifies CDR, SIP, QoS, and device event.
- Device events take the direct path: device SCORE, then Redis. They do not wait for enrich or stitching.
- CDR, SIP, and QoS go through ENRICH, then alert type 2, then SCORE, then SILVER, then alert type 3.
- SILVER is stateful, with a watermark and a defined home for late and unmatched records.
- SCORE and SILVER reload thresholds from the Delta threshold table. Alert workers reload the same table through Redis.
- Redis writes are idempotent on `batch_id`, with a separate namespace per alert type.
- Lakebase reads Silver through LTAP. There is no JDBC sync job.
- GOLD is the signed rollup grain from session 8: 4–5 rollups, each readable at L0, L1, and L2. ML and the threshold publish path stay downstream of GOLD.
- Reference Delta tables cover carrier, codec, and geo, refreshed on the plan’s pipeline, and broadcast into ENRICH with hot reload.

A human reviews the design note before implementation starts. The notebook assistant can be used here to try a join against dev reference data. The resulting SQL is copied into `bcm` through Claude Code or by hand, in a merge request.

### Development

Phase 2 of the plan (5 Oct – 7 Dec 2026) is the build. Claude Code implements from the signed decision and the design note.

Plan milestones are when the prompt pack for that slice must already pass in dev: week 6 (Bronze for all three confirmed sources, alert type 1), week 9 (enrich, score, Silver assembly), week 11 (cross-source Silver, Gold), week 14 (volume run finished, dashboards and the Lakebase path ready for the UI). Claude does not declare a milestone met. QA does, from the pack and the automated tests.

When a stage is in the dev catalog, the author asks the engineering agent the prompt-pack questions for that stage and pastes the question, the generated SQL, and the result grain into the merge request. QA asks the same questions from their own login. The two answers should match. A mismatch is a defect in the pipeline or in the agent instructions, and someone fixes the instructions in the same request when the instructions were wrong.

### Tests

Acceptance checks come from the signed decisions and from the plan’s QA rows. Claude Code writes the automated tests for the rows that can pass on synthetic data. QA owns the Genie prompt pack and runs it after each dev deploy.

Test inputs checked into `bcm` are synthetic. They cover a multi-leg call, a device event, a registration failure, a late leg, an unmatched leg, a Sonus timestamp that is not UTC, a SkyConnect field that belongs in the cold archive and must be absent from the hot Bronze table, and a second partner that must be invisible at L1 and L2.

These plan checks stay with QA and are not a Claude Code pass:

- Schema mapping against the real Schema Registry subjects, once the connector gate is open.
- Partner isolation across L0/L1/L2, including the penetration pass named on the plan.
- The 48-hour run at 35 million records a day.
- Phase 3 on live producers: completeness, leg counts, correlation rates, and all three alert types on live data.

Claude can draft the validation queries for that last group (counts, unmatched rate, lag versus the 60-second SLA). QA runs them. The review job never sees production rows.

### CI/CD

The `bcm` pipeline, separate from the Claude job, runs the automated tests and the Databricks bundle validation on merge requests.

The Claude review job is described in [Merge request review](#merge-request-review). It is not a substitute for the tests.

Deploy to dev happens from the default branch after human approval. Production deploy is out of scope for the AI tools.

### Code review

Order on every merge request:

1. Automated tests.
2. Claude review comment.
3. Author response: fixed, or a one-line reason the comment does not apply.
4. Human approval from someone who did not write the change.

The author reads the Claude comment before asking for human review, so the human reviews the decision rather than the first-draft mistakes.

## Engineering Genie Agent

Create one agent in the dev workspace.

- Attach it to a serverless SQL warehouse in dev.
- Attach tables only after they exist, in this order: Bronze classified records, enriched records, Silver sessions, Gold rollups, the threshold table, and the reference Delta tables (codec, geo, and the others discovery confirms).
- Do not attach a production catalog. Do not attach Kafka. Do not attach Redis.
- Share it with data engineers and QA. Each person asks as themselves, so Unity Catalog row filters apply to them.
- Instructions live in the agent and are copied into `bcm/docs/genie_agent_instructions.md` so they are reviewed in git. The workspace copy is what Genie runs. The git copy is what the team reviews. They are updated in the same merge request.

Instructions to seed once the producer list is confirmed:

- A record is one of: CDR, SIP, QoS, device event. Device events are not sessions.
- A session is whatever the signed decision says, and only that. Until the decision exists, the agent says it cannot answer session questions.
- Alert type 1 is a device event, counted before enrich. Alert type 2 is a per-record or registration result after enrich and before stitching. Alert type 3 is a session score after Silver.
- Questions are scoped to a named partner and level (L0, L1, or L2). If the question names neither, the agent asks. A query that can see another partner at L1 or L2 is a wrong answer.
- Column meanings for correlation, watermark, and score come from Unity Catalog comments. Those comments are maintained in `bcm` with the table definitions.
- Example questions are the prompt pack. Each example includes the SQL grain that counts as a correct answer.

When an answer is wrong, the person who noticed it updates the instructions or the example SQL in `bcm` and says so in the merge request. That is how the agent improves. Correcting it in the workspace UI alone is not enough, because the next person will not see the change in review.

Claude Code is connected to this agent with the Databricks Genie connector, authenticated as the engineer (`ucode` or a workspace OAuth app, per Databricks’ current Claude Code instructions). Claude may ask the agent about dev data. It may not be given a path that queries production.

## Data boundary

**Proposed default, not yet accepted.**

Claude Code, the review job, and the notebook assistant may receive:

- Pipeline code, design notes, and signed decisions.
- Unity Catalog names, column comments, and table DDL.
- Synthetic rows written for tests.
- Aggregates that contain no phone number, SIP URI, or other subscriber identifier (row counts, error rates, delay distributions).

They may not receive:

- Production CDR, SIP, or QoS payloads.
- Production phone numbers, SIP URIs, IP addresses tied to a subscriber, or tenant names taken from production.
- Contents of Redis, EventBridge payloads, or alert-worker logs from production.
- A warehouse token, GitLab token, or API key pasted into a prompt.

The engineering Genie Agent is the only AI path that runs SQL over stored rows, and only in dev, as the asking user. If discovery needs a real payload shape, a person masks it by hand and checks the masked sample in. The model does not perform that masking.

Whoever owns data handling for BCM accepts or replaces this default before the first dev table is attached to the agent. Until then, the team follows the default.

## Claude Code rules

These rules are an initial suggestion. Adjust them when the final design documents are locked, and polish them during development.

They are copied into `bcm/CLAUDE.md`. Edits to the rules happen in this strategy first, while they are being reviewed, and move to `bcm/CLAUDE.md` once approved. That file is the copy Claude Code loads. This document stays the explanation.

```text
You are working in the bcm repo. The design and architecture in this
repo is the source of truth. The project plan and architecture v3.2-A
are not in this repo.

The realtime database is a separate codebase. Read its procedures as
evidence of how Nectar stitches and enriches today, and mirror that
behavior where the design carries it forward. Do not modify that
database. When a procedure and the design disagree, the design wins.
Do not treat Avaya, Genesys, CUCM, Teams, Zoom, or Diagnostics
procedures as the BCM field mapping.

Implement the path in the design: Kafka
source, Bronze classification, enrich joins, score, Silver stitch,
Gold. Device events skip enrich and Silver. Alert type 2 is
post-enrich. Alert type 3 is post-Silver. Redis writes are idempotent
on batch_id. Lakebase is LTAP, with no JDBC sync. Gold is 4 to 5
rollups at L0, L1, and L2. The 60-second SLA and the 90-day Lakebase
retention are requirements, not tuning knobs.

Do not invent correlation keys, the synthetic correlation id, producer
schemas, the 85-field or 37-field cut, carrier rules, or threshold
numbers. If the decision file for that plan session is missing, stop
and name the session.

Do not print or write production CDR, phone numbers, or SIP URIs.
Dev data questions go to the engineering Genie Agent.

Add or update the automated test and the Genie prompt-pack entry for
the behavior you changed.

Do not commit secrets. Do not weaken a Unity Catalog grant. Do not
query across partners except in a test that asserts the second partner
is absent at L1 and L2. One schema per tenant in the realtime database
is not the L0/L1/L2 model.
```

Practical habits that go with those rules:

- Start a Claude Code session with the decision file and the stage it applies to, not with the whole realtime-database tree.
- Ask for a plan before an edit when the change touches classification, stitching, or Redis.
- Reject a generated join that cites an Avaya or Diagnostics column unless the decision file names that column.

## Claude Code setup

Skills, hooks, permission rules, and MCP server definitions are committed in the `bcm` repository. Every engineer and the GitLab review job load that same set. They are not a private configuration on one laptop. Personal overrides, if any, stay in `.claude/settings.local.json`, which is gitignored, and cannot weaken a committed deny rule. Hooks are `command` hooks. A model call on every tool use is not part of this setup.

### Tools

Claude Code’s built-in tools for this work are Read, Edit, Write, Grep, Glob, and Bash. Bash is for the test command and `databricks bundle validate` against the dev target.

Two MCP servers are connected, using Databricks’ current Claude Code login (`ucode` or the documented OAuth app):

| Server | What Claude may do with it | When |
|---|---|---|
| Engineering Genie Agent | Ask a question about dev tables and read back the SQL and the grain | After a dev table exists. This is the only path to stored rows. |
| Unity Catalog | Read table and column comments, and the list of tables in the dev catalog | Design and development, so names in code match the catalog |

A GitLab server scoped to project `bcm` is connected so Claude can open the merge request the engineer is already making. It cannot approve, merge, or change protected-branch settings.

Permission denies in `.claude/settings.json` refuse, for every engineer:

- Reading or writing `.env`, credential files, and warehouse tokens.
- `databricks bundle deploy` aimed at production.
- Bash that dumps the environment or talks to Redis, EventBridge, or a production catalog.

### Skills

Skills are the extra instructions Claude loads when the task matches. They live under `.claude/skills/` in `bcm`. Five are enough:

| Skill | Loads when | What it tells Claude |
|---|---|---|
| `decision-check` | A change touches classification, enrich, stitching, score, thresholds, or partner filters | The design in this repo is what to implement. A discovery note explains a choice the design has not absorbed yet. Stop and name the gap if neither records it |
| `realtime-patterns` | Someone asks how Nectar does this today | The procedure map in this document: what to copy as a pattern, and which columns stay behind |
| `genie-check` | A change is ready to check against dev data | How to ask the engineering agent, and how to update `docs/genie_prompt_pack.md` and the agent instructions in the same change |
| `bundle-validate` | Tests or the Databricks bundle need a run | The dev-target validate command and the unit-test command. Production deploy is not in the skill |
| `code-review` | A diff is ready to review, on the engineer’s machine or in the GitLab job | Starts the read-only reviewer below, applies the checklist and the test-coverage check in [Merge request review](#merge-request-review), and reports other observations separately. On the machine, findings stay in the terminal. In GitLab, the job posts them on the request |

### Hooks

Hooks in `.claude/settings.json` run even when Claude skips a rule in `CLAUDE.md`.

| Event | What it does |
|---|---|
| `SessionStart` | Adds a short reminder to the session: the design in this repo is the source of truth, the realtime database is evidence to mirror, rows are read through the dev Genie Agent, production payloads stay out of the prompt |
| `UserPromptSubmit` | Blocks the turn when the prompt contains the production catalog name or a pasted CDR extract. The engineer masks the sample and continues |
| `PreToolUse` on Bash | Blocks the permission-deny cases above when a deny rule is not enough |
| `PostToolUse` on Edit and Write | After a pipeline file changes, reminds the engineer to update the matching test and the Genie prompt-pack line. The turn still completes |
| `Stop` | Runs a secret scanner on the diff and blocks the turn on a match. The same scanner runs in the GitLab test pipeline |

`/hooks` shows the merged set. It does not edit it. Changes to hooks go through a merge request.

### Also committed in `bcm`

- `.claudeignore` keeps checkpoint directories, build output, `.databricks/`, large fixtures, and a realtime-database checkout out of Claude’s context.
- `.claude/agents/code-reviewer.md` is a reviewer that can Read, Grep, and Glob, and cannot edit. The `code-review` skill starts it, so the session that wrote the change is not the session that reviews it.
- Bash is allowed for the test command and `databricks bundle validate` on the dev target. Any other shell command asks the engineer first.

Streaming rules stay in `CLAUDE.md` rather than a skill per pipeline stage. There is no SQL warehouse connection, because that would bypass the Genie Agent. Streaming tests are not hooked to the end of every turn. The engineer runs them with `bundle-validate`.

### Where each one is used

| | Discovery | Design | Development | Merge request |
|---|---|---|---|---|
| Tools | Read, Unity Catalog metadata | Read, Write, Unity Catalog metadata | Edit, Write, Bash, Genie, Unity Catalog | GitLab, to open the request. The review job is CI, not these tools |
| Skills | `realtime-patterns`, `decision-check` | `decision-check` | `decision-check`, `genie-check`, `bundle-validate`, then `code-review` before the request is opened | `code-review`, loaded by the CI job from the checkout |
| Hooks | `SessionStart`, `UserPromptSubmit` | Those, plus `PreToolUse` | The full set, including `Stop` | The CI job is comment-only, so `PreToolUse` still blocks a deploy or a secret read if that job’s prompt goes wide |

## Merge request review

The engineer runs `code-review` on the diff before opening the merge request. The skill starts the read-only reviewer, which reads the diff, `CLAUDE.md`, and the decision files the change touches. It has no warehouse connection and does not push. The engineer fixes what they accept, then opens the request.

The same checklist runs again in GitLab CI on project `bcm`, on `merge_request_event` only. Claude Code’s GitLab CI integration is the implementation to follow; it is a vendor beta, so the job is pinned to a known CLI version and treated as replaceable. The CI job and the skill share this list so the two reviews do not drift.

The job is comment-only. It posts one note on the merge request. It does not push commits, open a follow-up branch, or apply suggestions. An `@claude` mention that implements code is a separate, later choice and is not part of this strategy.

The job receives the diff, the list of changed files, `CLAUDE.md`, and the decision files those paths touch. It does not receive a warehouse connection. Diffs over a fixed size, and generated files, are skipped with a note that says the review was skipped.

The review looks for:

- A producer field mapping or correlation key with no decision file.
- Device events sent through enrich or Silver.
- Alert type 2 implemented after Silver, or alert type 3 implemented before Silver.
- A Redis write that can double-count when a batch is retried.
- Silver with no watermark behavior and no unmatched path.
- A JDBC or other copy into Lakebase.
- SQL missing an L0/L1/L2 predicate, or a predicate that treats tenancy as one flat tenant id when the decision file describes three levels.
- A hot Bronze column the SkyConnect decision file assigned to the cold archive, or a CoreConnect column outside the signed 37-field set.
- A Sonus timestamp kept in a local zone, or a synthetic `correlation_id` whose formula is not the session 7 decision.
- A production catalog name, a secret, or a sample that looks like a real phone number or SIP URI.
- A behavior change with no test and no prompt-pack update.
- Logic copied from `pr_ncj_build_avaya` or `pr_u_dm_build_*` column names that the decision file does not adopt.

The reviewer also checks that automated tests exist for the code being changed or added. For each changed path it reports whether a test in the diff covers it, only an untouched existing test covers it, or no test was found. A changed behavior with no test, or an existing test the change has made stale, is blocking.

The reviewer may also flag correctness bugs, unhandled edge cases, and unclear logic that are not on the list above. These go under a separate **Other observations** heading and are never blocking on their own.

The note ends with a short list: blocking issues, questions, test coverage, other observations, and what was not reviewed. “Blocking” here means the human should not approve until it is fixed or answered. The CI job itself stays green so a vendor outage cannot stall the team. Proposed default: the job is `allow_failure: true`.

Human approval remains required in GitLab. The Claude note does not count as that approval.

## Notebook assistant

Use it to draft or explain a single SQL statement against dev tables while exploring. The same data boundary applies.

Pipeline code that will run on a schedule is written in `bcm` and reviewed on a merge request. SQL that the assistant produced is pasted into `bcm` by a person or by Claude Code, with the test and the prompt-pack update. A notebook saved only in the workspace is not the implementation.

## Tests and CI, in one place

| Check | Who writes it | Who runs it | Pass means |
|---|---|---|---|
| Classification, UTC timestamps, 85-field and 37-field scope, correlation, idempotent score, L0/L1/L2 filter | Claude Code from a signed decision; author edits | GitLab CI on the merge request | The synthetic fixtures produce the expected rows |
| Databricks bundle validates | Author | GitLab CI | The asset bundle loads |
| Genie prompt pack | QA, with engineers updating instructions when the answer is wrong | QA, as themselves, after the dev deploy | The SQL grain matches the expected grain for that question |
| Claude review | The review policy in this document | GitLab CI, comment only | Author has answered every item they marked blocking |
| Human review | A data engineer or QA who did not author the change | GitLab approval | The approver accepts the decision and the diff |
| Schema Registry mapping, partner-isolation penetration, 48-hour 35M-record run, Phase 3 live completeness and correlation rates | QA, from the plan’s QA rows | QA on the dev or live workspace, outside Claude | The plan’s milestone can be marked done |

QA’s prompt pack is a file in `bcm`, `docs/genie_prompt_pack.md`. Each line has the question, the partner and level it uses, the table grain, and the decision file it checks. The first entries, to be filled when the decisions exist, are: record-type counts per producer, hot-store field counts, device events absent from Silver, registration alerts present before a session exists, session score absent until Silver, late leg attached or explicitly unmatched, and zero rows for a second partner at L1 and L2.

## Before Phase 2

The plan’s build starts the week of 5 Oct 2026, after the discovery readout. Before the first Bronze merge request, data engineers and QA:

1. Read this document, the v3.2-A diagram, and the project plan’s Phase 1 and Phase 2 rows.
2. Accept or replace the two open defaults (data boundary, non-blocking review).
3. File the producer-list decision. The diagram and the plan disagree, and every later schema task depends on that file.
4. Add `CLAUDE.md`, `.claude/settings.json`, `.claudeignore`, the read-only reviewer, the five skills, the MCP servers, and the review job to the existing `bcm` repository, and turn on branch protection that requires one human approval. Use of the repository starts with that change.
5. Open empty decision files for sessions 1 through 5, 7, and 8, plus the SkyConnect hot/cold cut and the CoreConnect 37-field scope, so a Claude session has somewhere to stop.
6. Create the empty engineering Genie Agent in dev, shared with this group, with no tables attached yet.
7. Connect Claude Code to that agent from one engineer’s machine and confirm a permissions failure on a production catalog, so the boundary is real.
8. Add the prompt-pack headings in [Tests and CI](#tests-and-ci-in-one-place), with the expected grain left as “waiting on decision” until the session file is signed.

Phase 2 merge requests follow the lifecycle above. New people read this document, the plan, and `bcm/CLAUDE.md` before their first Claude Code session. Session 6 and the UI team’s Lakebase work stay outside this strategy. Their written outcome is still an input when it changes a query or a prompt-pack question.
