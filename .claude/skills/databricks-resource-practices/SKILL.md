---
name: databricks-resource-practices
description: Use when creating or changing a Databricks resource (job, pipeline, schema, table, volume, grant, secret reference, Genie Space, app) or running a similar workspace action.
---

Resources are code. Claude writes the bundle config and validates it; it does
not create resources by hand, and it does not deploy. Load the `databricks`
plugin skill that matches the resource (`databricks-dabs`, `databricks-jobs`,
`databricks-pipelines`, `databricks-unity-catalog`, and so on) for the CLI and
YAML mechanics. This skill only adds this repo's rules on top of them.

## Rules

- **Declare it in the bundle.** Every job, pipeline, volume, schema, app and
  permission is a resource in the bundle config, reviewed on a merge request.
  Do not create one with an ad-hoc `databricks ... create` call, the SDK, or the
  workspace UI, because nobody can review or recreate it. The one named
  exception is the Genie Space (`genie-check` skill), which asks first.
- **Dev target only, and Claude does not deploy.** Validate with
  `databricks bundle validate --target dev` (`bundle-validate` skill). Deploy to
  dev happens from the default branch after human approval. Never pass another
  target, and never run `bundle destroy`. `pretool-guard.sh` blocks both.
- **Small, focused bundles.** One team's resources in one bundle, changed in
  small steps, so a rollback is a revert of one change. Do not add a resource
  to an unrelated bundle to save a file.
- **Stay inside the dev scope.** Write only to `nectar.bronze`, `nectar.silver`,
  `nectar.gold` and `nectar.ops`. Do not create a catalog or schema, and do not
  touch anyone's personal schema. If the work needs one, stop and ask.
- **Unity Catalog governance.**
  - Prefer managed tables and volumes. An external location is a human decision.
  - Grant to groups, never to individual users, and grant the least that works
    (`SELECT` for readers; `MODIFY` only for the service principal that runs the
    job). Do not grant `ALL PRIVILEGES` or `MANAGE` to make an error go away.
  - Never weaken a grant or a row filter, and never add one that lets a partner
    see another partner (L0/L1/L2 as the design docs define them, not a flat
    `tenant_id`).
  - Table and column comments are part of the table definition in the repo, not
    edited in the UI. The Genie Agent depends on them.
- **Identity.** Jobs and pipelines run as a service principal, not as an
  engineer. Deployment and runtime identities are separate and configured in CI,
  not in files Claude writes. Do not put a user name or email in a bundle.
- **Secrets.** Reference a secret scope key (`{{secrets/scope/key}}`) and never
  a value. Do not run `databricks secrets` commands (they ask first, and the
  answer is almost always no). Do not put a token, host credential or
  connection string in config, tests or a comment.
- **Compute.** Use serverless unless the design docs say otherwise.
  Pipelines follow the design (Lakeflow Spark Declarative Pipelines, continuous,
  autoscale on lag). The 60-second SLA and the 90-day Lakebase retention are
  requirements, so a cost or size change that threatens them is not a tuning
  choice Claude makes.
- **Thin notebooks.** Business logic goes in `.py` or `.sql` modules with a
  test. A notebook only calls it. A resource that exists only in the workspace
  is not the implementation.
- **Parameterize, don't fork.** One resource definition with per-target
  overrides, not a copy per environment. Names, paths and catalogs come from
  bundle variables, not literals.
- **Tag and name consistently.** Follow the names and tags on the resources
  already in the repo. Include the layer and the bundle name so a run can be
  traced to its source. Do not invent a new naming scheme.
- **Data boundary.** A resource definition, test fixture or comment holds no
  production CDR, phone number, SIP URI or production catalog name.

## Steps

1. Name the resource, the layer it belongs to, and the design doc section
   that asks for it. If the design docs do not cover it, stop and say what is
   missing (`design-check` skill).
2. For a change to classification, stitching, Redis or a grant, present a plan
   and wait for the engineer before editing.
3. Load the matching `databricks` plugin skill and write the resource in the
   bundle config.
4. Add or update the automated test, then run `bundle-validate`.
5. Report what was added, which grants it needs and who holds them, and that a
   human deploys it. Do not deploy, run, or transition anything.
