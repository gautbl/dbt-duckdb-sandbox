# 04: README states what CI runs

**What to build:** The README states what continuous integration runs and states the one command for the full check. A reviewer reads the README and the workflow and finds the same words and the same commands.

The README also states the docs publish gate, so a reader knows the site follows a green build. The pattern table in the README gains the build and test path beside the existing patterns, because the workflow now shows a pattern.

Change no other section beyond what this ticket names.

If the workflow changes later, the README line changes in the same commit. State that rule in the README.

**Blocked by:** 01, 02, 03

**Status:** ready-for-agent

- [ ] The README states what continuous integration runs, with the same commands as the workflows.
- [ ] The README states the one command that a contributor runs for the full check.
- [ ] The README states that the docs publish follows a green build.
- [ ] The README states that a workflow change and its README line change in the same commit.
- [ ] The words in the README match the workflow files.
