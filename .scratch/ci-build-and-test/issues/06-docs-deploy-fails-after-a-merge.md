# 06: The docs site publishes after a merge to `main`

**What to build:** The docs deploy passes after a green build of a merged pull request. Today every docs run after a merge commit fails at its last step. The site then keeps an old build. The failure reads as an artifact fault, not a docs fault.

Reproduce the fault and find its cause. Then make the deploy stable. Three merges in a row must publish the site.

**Blocked by:** None (can start immediately). Ticket 03 added the green-build edge, and this ticket repairs the deploy leg of that edge.

**Status:** ready-for-agent

- [ ] A pull request merges with a green build, and the docs run that follows passes its deploy step.
- [ ] Two later merges do the same, so the fault does not return in three runs.
- [ ] The site at https://gautbl.github.io/dbt-duckdb-sandbox/ serves the latest docs.
- [ ] A red build still stops the deploy, as ticket 03 asks.
- [ ] A comment in the workflow names the cause, and a reader can tell why the deploy broke.

## Comments

**Failed runs, all after a merge commit:**

- https://github.com/gautbl/dbt-duckdb-sandbox/actions/runs/46005499345 on `c6a7447`
- https://github.com/gautbl/dbt-duckdb-sandbox/actions/runs/46007184209 on `d11941e`
- https://github.com/gautbl/dbt-duckdb-sandbox/actions/runs/46007460191 on `f487068`, two runs

**A run that passes, after a plain push:** https://github.com/gautbl/dbt-duckdb-sandbox/actions/runs/45972845303 on `ef79c0e`. The second run of it also passes.

**Symptom:** the step "Deploy to GitHub Pages" fails 350 ms after the artifact upload finalizes.

- The log reads `Fetching artifact metadata for "github-pages" in this workflow run`.
- Then it reads `Found 0 artifact(s)`.
- Then it reads `No artifacts named "github-pages" were found for this workflow run`.
- The artifact exists. The REST API lists `github-pages` at 706395 bytes and 706546 bytes, and marks neither expired.

**What this rules out:**

- An upload fault. The upload finalizes with a digest and an artifact id.
- A Pages source setting. `build_type` reads `workflow`, and the environment allows `main` and `gh-pages`.
- A token scope. The Pages action lists artifacts through the run results service, not the REST API, so `actions: read` does not gate it.
- A stale action. The pass and the fails use the same two action versions, and both warn that Node 24 forces the runner.

**Lead:** the docs runs that follow a merge commit fail. The run after a plain push passes. Start the diagnosis on that difference.
