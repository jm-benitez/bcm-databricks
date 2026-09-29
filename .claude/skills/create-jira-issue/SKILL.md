---
name: create-jira-issue
description: Use when asked to create, draft, or write a Jira issue or ticket, so every issue has the same structure.
---

Every issue has exactly these five parts, in this order: **Title**, **What?**,
**Why?**, **Technical Tasks**, **Acceptance Criteria**. Jira is a shared system,
so draft first, show the draft, and create the issue only after the engineer
agrees.

## Structure

**Title** — the Jira summary. One line, imperative, and specific to one piece of
work ("Add watermark handling to Silver stitching"), not a topic ("Silver").

**Description** — markdown with these headings, verbatim:

```markdown
## What?
One to three sentences: the change or result this issue delivers.

## Why?
The reason, with its source: the decision file (e.g. session-7), the design
note, or the parent ticket. If there is no source, say so instead of inventing
one.

## Technical Tasks
- [ ] One concrete step per line, in build order.
- [ ] Include the automated test as its own task.

## Acceptance Criteria
- [ ] One observable, checkable condition per line.
- [ ] QA can verify each one by asking the engineering agent a question about
      the tables this issue produced, or by running a test.
```

## Rules

- **Do not invent.** Correlation keys, the synthetic correlation id, producer
  schemas, the 85-field and 37-field cuts, carrier rules, and thresholds come
  from signed decision files (`decision-check` skill). If the issue touches
  one and its decision file is missing or unsigned, put "Blocked by: decision
  for session N" in **Why?** and do not write tasks that assume an answer.
- **Acceptance criteria are testable.** "Late legs are attached or explicitly
  unmatched" is checkable; "stitching works well" is not. Use counts, grains
  and named tables, never specific subscriber values.
- **Data boundary.** No production CDR, phone numbers, SIP URIs, secrets, or
  Genie result rows in any part. Aggregates and decision-file names only
  (`jira-guard.sh` blocks a call that contains them).
- **Only set what was asked.** Do not set assignee, priority, or labels unless
  the engineer named them.

## Steps

1. Get the cloud id with `getAccessibleAtlassianResources` and confirm the
   project (`BCM` unless told otherwise).
2. Look up the project's issue types with `getJiraProjectIssueTypesMetadata`
   and choose the one that matches the work (for example Spike for
   discovery). If it is unclear, ask.
3. Call `getJiraIssueTypeMetaWithFields` for that type and fill any required
   field it lists. Do not guess a required field's value; ask.
4. Draft the five parts and show them to the engineer. Ask before creating.
5. Create with `createJiraIssue`, passing the description as markdown. The
   call asks for approval on its own.
6. Report the issue key and link. Do not transition, assign, or link the issue
   unless asked.
