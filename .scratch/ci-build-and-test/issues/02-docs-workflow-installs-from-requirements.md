# 02: The docs workflow installs the same way as the build workflow

**What to build:** The documentation workflow installs its dependencies from `requirements.txt`. Today it installs the adapter package with no version, so its dbt version can drift from the local setup and from the build workflow.

After this ticket, one file states the dbt version. One edit changes it for local setup, for the build gate and for the docs deploy. A dependency change is one edit, not three.

The documentation workflow keeps its behaviour: it still generates the docs and it still deploys the site.

**Blocked by:** 01 (the build workflow states the pattern to copy)

**Status:** ready-for-agent

- [ ] The documentation workflow installs from `requirements.txt` and pins no version inline.
- [ ] The documentation workflow still generates the docs and deploys the site.
- [ ] A single edit to `requirements.txt` changes the dbt version for local setup and for both workflows.
