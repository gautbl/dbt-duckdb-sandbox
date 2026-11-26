# 04: README states what CI runs

**What to build:** The README states what continuous integration runs and states the one command for the full check. A reviewer reads the README and the workflow and finds the same words and the same commands.

The README also states the docs publish gate, so a reader knows the site follows a green build. The pattern table in the README gains the build and test path beside the existing patterns, because the workflow now shows a pattern.

Change no other section beyond what this ticket names.

If the workflow changes later, the README line changes in the same commit. State that rule in the README.

**Blocked by:** 01, 02, 03

**Status:** ready-for-agent

**From the review of tickets 01 and 02.** The README gap is a medium finding on both axes. The README pattern table lists the patterns this project shows. Continuous integration is now one of them. Two more points sit here:

- `docs/overview.md:19` calls the sources the ingestion seam and says they load outside dbt. `_stg__sources.yml:3` now says `dbt seed` loads them. Align the two docs in this ticket.
- The README walkthrough names the `Source freshness` step, and CI does not run that check. State where CI stops, so a reader does not expect freshness in CI.

- [ ] The README states what continuous integration runs, with the same commands as the workflows.
- [ ] The README states the one command that a contributor runs for the full check.
- [ ] The README states that the docs publish follows a green build.
- [ ] The README states that a workflow change and its README line change in the same commit.
- [ ] The words in the README match the workflow files.
- [ ] `README.md` and `docs/overview.md` agree on how the seed data loads.
- [ ] The README says that CI runs no source freshness check.
