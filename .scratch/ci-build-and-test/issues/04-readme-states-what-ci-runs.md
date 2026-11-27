# 04: README states what CI runs

**What to build:** The README states what continuous integration runs and states the one command for the full check. A reviewer reads the README and the workflow and finds the same words and the same commands.

The README also states the docs publish gate, so a reader knows the site follows a green build. The pattern table in the README gains the build and test path beside the existing patterns, because the workflow now shows a pattern.

Change no other section beyond what this ticket names.

If the workflow changes later, the README line changes in the same commit. State that rule in the README.

**Blocked by:** 01, 02, 03

**Status:** resolved

## Comments

Commit `2b374d0` adds one `## Continuous integration` section and one
`## The full check` section to `README.md`, one patterns-table row, and one
layout entry. It adds two bullets to `docs/overview.md`.

**Every command in the README comes from a workflow file.** The pair
`dbt build --profiles-dir .` then `dbt test --profiles-dir .` is
`build.yml:57` and `build.yml:60` word for word.

**The ticket line for the seed load was stale.** It named
`docs/overview.md:19`, but the file held no statement about loading. The one
"seam" sentence lived in `models/staging/_stg__sources.yml:5`, and that
sentence already named `dbt seed`. The gap was silence in the overview, so
the fix adds the statement there rather than editing an existing one.

**Review found two false claims, both fixed before the commit landed:**

- The README said a failed run names the model and the column. No workflow
  step does that. dbt writes the name to its log and to `target/`. The
  sentence now puts the naming on dbt and the upload on the workflow.
- The README said a published site shows the freshness result the build
  carried. `docs.yml` runs `dbt docs generate` on a clean tree with no
  freshness step, so the site carries no result. The sentence now says that.

**Evidence:** `dbt build --profiles-dir .` gives PASS=38, ERROR=0.
`dbt test --profiles-dir .` gives PASS=30, ERROR=0. `dbt docs generate
--profiles-dir .` writes `catalog.json` and parses the `__overview__` block.
Both workflow files load with `yaml.safe_load`, which confirms the trigger
sets that the README names.

The full review sits under this ticket, in the independent review section below.

**From the review of tickets 01 and 02.** The README gap is a medium finding on both axes. The README pattern table lists the patterns this project shows. Continuous integration is now one of them. Two more points sit here:

- `docs/overview.md:19` calls the sources the ingestion seam and says they load outside dbt. `_stg__sources.yml:3` now says `dbt seed` loads them. Align the two docs in this ticket.
- The README walkthrough names the `Source freshness` step, and CI does not run that check. State where CI stops, so a reader does not expect freshness in CI.

- [x] The README states what continuous integration runs, with the same commands as the workflows.
- [x] The README states the one command that a contributor runs for the full check.
- [x] The README states that the docs publish follows a green build.
- [x] The README states that a workflow change and its README line change in the same commit.
- [x] The words in the README match the workflow files.
- [x] `README.md` and `docs/overview.md` agree on how the seed data loads.
- [x] The README says that CI runs no source freshness check.

## Comments

Three commits hold this ticket: `2b374d0` (the docs change), `5791a7c` (the
close-out), and a later commit that fixes the review findings.

**Scope.** `README.md` gains a `## Continuous integration` section and a
`## The full check` section. The pattern table gains one row, and the layout
block gains one entry. The walkthrough stays as it was. `docs/overview.md`
gains an ingestion-seam bullet and a continuous-integration bullet.

**Every command in the README comes from a workflow file.** The pair
`dbt build --profiles-dir .` then `dbt test --profiles-dir .` matches the two
`run:` lines in `build.yml` word for word. Neither workflow runs
`dbt source freshness`, and the README states that limit.

**The ticket named a stale line for the seed load.** It cited
`docs/overview.md:19`, but that file held no statement about loading. The only
seam sentence lived in `models/staging/_stg__sources.yml`, and it already
named `dbt seed`. The gap was silence in the overview, so this ticket adds the
statement there.

**Evidence.** `dbt build --profiles-dir .` gives PASS=38, ERROR=0.
`dbt test --profiles-dir .` gives PASS=30, ERROR=0. `dbt docs generate
--profiles-dir .` writes `catalog.json` and parses the `__overview__` block.
Both workflow files load with `yaml.safe_load`.

### Review findings, and what changed

A two-axis review ran against base `93b1ade`. Every hard finding is closed.

**Claim: the workflow names the failing model and column.** No step does. dbt
writes the name to its log and to `target/`. The README now puts the naming on
dbt and the upload on the workflow.

**Claim: the docs trigger filters on `main`.** That is one guard of two. The
deploy also demands `github.event.workflow_run.event == 'push'`, because a
pull request into `main` can carry `main` as its base. The README now names
both guards.

**Scope breach: an edit to walkthrough step 5.** The ticket names no such
section. I reverted it, so the walkthrough matches the base file.

**Seed-load wording.** The overview first said the sources are the CSV files.
After `dbt seed` the sources are DuckDB tables. The bullet now says the seed
copies the CSV into tables, and the sources read those tables.

**Left open on purpose.** The README omits the pip cache step, because this
ticket states what CI runs, not how it caches. `Status: resolved` is not one
of the five strings in `docs/agents/triage-labels.md`, but tickets 01 to 03
already use it, so that file holds the gap.

The first fold of this review copied line numbers from a working-tree diff,
and those numbers drifted. This section cites none, so it cannot go stale the
same way.
