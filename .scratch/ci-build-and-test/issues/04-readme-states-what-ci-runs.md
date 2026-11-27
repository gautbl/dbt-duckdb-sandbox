# 04: README states what CI runs

**What to build:** The README states what continuous integration runs and states the one command for the full check. A reviewer reads the README and the workflow and finds the same words and the same commands.

The README also states the docs publish gate, so a reader knows the site follows a green build. The pattern table in the README gains the build and test path beside the existing patterns, because the workflow now shows a pattern.

Change no other section beyond what this ticket names.

If the workflow changes later, the README line changes in the same commit. State that rule in the README.

**Blocked by:** 01, 02, 03

**Status:** resolved

**From the review of tickets 01 and 02.** The README gap is a medium finding on both axes. The README pattern table lists the patterns this project shows. Continuous integration is now one of them. Two more points sit here:

- `docs/overview.md:19` calls the sources the ingestion seam and says they load outside dbt. `_stg__sources.yml:5` now says `dbt seed` loads them. Align the two docs in this ticket.
- The README walkthrough names the `Source freshness` step, and CI does not run that check. State where CI stops, so a reader does not expect freshness in CI.

- [x] The README states what continuous integration runs, with the same commands as the workflows.
- [x] The README states the one command that a contributor runs for the full check.
- [x] The README states that the docs publish follows a green build.
- [x] The README states that a workflow change and its README line change in the same commit.
- [x] The words in the README match the workflow files.
- [x] `README.md` and `docs/overview.md` agree on how the seed data loads.
- [x] The README says that CI runs no source freshness check.

## Comments

Four commits hold this ticket: `2b374d0` (the docs change), `5791a7c` (the
close-out), `705d9df` (the first review fold), and `5f3e7c0` (the review
fixes).

**Scope.** `README.md` gains a `## Continuous integration` section and a
`## The full check` section. The pattern table gains one row. The layout block
gains one entry. The walkthrough stays as the base file. `docs/overview.md`
gains an ingestion-seam bullet and a continuous-integration bullet.

**The seed load.** The ticket named `docs/overview.md:19`, but that file held
no statement about loading. The only seam sentence lived in
`models/staging/_stg__sources.yml`, and it already named `dbt seed`. The gap
was silence in the overview, so this ticket adds the statement there.

**Evidence.** `dbt build --profiles-dir .` gives PASS=38, ERROR=0.
`dbt test --profiles-dir .` gives PASS=30, ERROR=0. `dbt docs generate
--profiles-dir .` writes `catalog.json` and parses the `__overview__` block.
Both workflow files load with `yaml.safe_load`, which confirms the triggers
and the deploy guard that the README names.

### How each box closes

Commands: the README quotes `dbt build --profiles-dir .` then
`dbt test --profiles-dir .`, and those are the two `run:` lines in `build.yml`
word for word.

One command: `## The full check` gives `dbt build --profiles-dir .` alone,
then states that CI adds the test step. A developer runs bare commands,
because the setup scripts copy the profile to `~/.dbt`.

Green gate: the README names two guards, a green run and a push event, and
says why the branch filter alone is not enough.

Same commit: the README states that rule in its own words.

Words match the workflows: the build gate runs on pull request, push to
`main`, and dispatch, on CPython 3.13, from `requirements.txt`. A newer run on
the same ref cancels an older one. A failure or cancel uploads `target/`, and
a green run uploads nothing. No workflow runs `dbt source freshness`, because
the source declarations name a `loaded_at` column that no seed CSV carries.
The docs job checks out the tested commit, and it has no dispatch trigger.

Seed load: the overview says `dbt seed` copies the CSV files into DuckDB
tables, and the `raw` sources read those tables. That matches the source
declaration.

No freshness in CI: the README states the limit, and its reason.

### Review findings, and what changed

A two-axis review ran against base `93b1ade`. Every hard finding is closed.

**The workflow does not name the failing model and column.** dbt writes the
name to its log and to `target/`. The README now puts the naming on dbt and
the upload on the workflow.

**The docs trigger has two guards.** The deploy needs a green run and a push
event. A pull request into `main` can carry `main` as its base, so the branch
filter alone lets it through.

**The walkthrough gained an unnamed clause.** The ticket names no such
section, so I reverted it. The clause was also false: the docs job generates
on a clean tree, so the published site carries no freshness result. Reverting
closed both faults at once.

**The Comments carried drifting line numbers.** They came from a
working-tree diff. This section cites only the three that resolve:
`build.yml:57` and `build.yml:60` for the two commands, and
`models/staging/_stg__sources.yml:5` for the seam sentence.

**Left open on purpose.** The README omits the pip cache step, because this
ticket states what CI runs, not how it caches. `Status: resolved` is not one
of the five strings in `docs/agents/triage-labels.md`, but tickets 01 to 03
already use it, so that file holds the gap.
