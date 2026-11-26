# 01: The build gate exists and is green on `main`

**What to build:** A new continuous integration workflow, in its own file, separate from the documentation workflow. It builds the whole warehouse from seeds on a clean runner and fails on any model error or data test failure. A red run names the model and the column.

It runs the same commands a developer runs locally: `dbt build`, then `dbt test`. The second command repeats work, and it runs anyway so the workflow matches the claim. The workflow adds no test harness and no custom script.

It installs from `requirements.txt` so that local and CI share one dbt version. It uses the same CPython minor version as the local setup script. It caches the pip download directory, keyed on `requirements.txt`, and a cache miss does not fail the run. It uses no secret and no cloud credential, because DuckDB runs in-process.

It triggers on push to `main`, on every pull request, and on manual dispatch. It uploads `target/` when a step fails, so `run_results.json` and `compiled/` are readable after a red run. A green run uploads nothing.

The workflow must not restore a warehouse artifact and must not run a cleanup step before the build. The absent database is the check.

The workflow uses no `--select`, so a new model joins CI with no edit. That property needs a comment in the file.

The workflow does not run `dbt source freshness`. The source declarations name a `loaded_at` column that the seed files do not carry. A freshness check would fail, and its fix is a separate feature.

The first run is green.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] A new workflow file exists beside the documentation workflow, and it is not part of that file.
- [ ] The workflow names its purpose so that the checks list is readable.
- [ ] The workflow triggers on push to `main`, on every pull request, and on manual dispatch.
- [ ] The workflow installs dependencies from `requirements.txt` and pins no dbt version inline.
- [ ] The workflow uses the CPython minor version that the local setup script uses.
- [ ] The workflow caches the pip download directory, keyed on `requirements.txt`, and a cache miss does not fail the run.
- [ ] The workflow runs `dbt build` with no `--select` and no warehouse artifact restored.
- [ ] The workflow runs `dbt test` after the build, as its own step.
- [ ] The workflow does not run `dbt source freshness`.
- [ ] The workflow uploads `target/` on failure only, and a green run uploads nothing.
- [ ] The workflow has no repository secret and no cloud credential.
- [ ] A comment in the file states that the missing `--select` is deliberate.
- [ ] The log shows seed, model and test counts, so a real build is one click away.
- [ ] The first run on `main` is green.
