# 03: Docs publish only after a green build

**What to build:** The documentation workflow names the build workflow as a prerequisite. The site then publishes only after a green build, so it never shows a warehouse that failed its tests.

The build workflow and the docs workflow keep separate verdicts. The build verdict must not hide the docs verdict, and the docs verdict must not hide the build verdict. A red build gives a red build check, and the docs deploy does not start.

The documentation workflow keeps its own permissions block. Pages deployment writes to the repository, and the build workflow must not carry that write access.

**From the review of tickets 01 and 02.** Spec decision 9 and user story 11 name this edge. It is the one medium finding on the spec axis. Two smaller points sit here:

- `docs.yml` installs dbt on each run and caches nothing. Add the same pip cache as `build.yml:35-38` if the docs job earns it. One run per push to `main` makes the gain small, so this part is optional.
- Both workflows pass `--profiles-dir .`. Keep the two step shapes alike so a later reader sees one pattern, not two.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The documentation workflow waits for the build workflow.
- [ ] A red build stops the docs deploy.
- [ ] The two workflows report separate verdicts.
- [ ] The documentation workflow keeps its Pages write permission, and the build workflow has no Pages write permission.
- [ ] The two workflow files present one install-and-run shape, not two.
