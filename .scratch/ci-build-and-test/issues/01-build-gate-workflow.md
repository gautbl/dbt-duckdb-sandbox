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

**Status:** resolved

- [x] A new workflow file exists beside the documentation workflow, and it is not part of that file.
- [x] The workflow names its purpose so that the checks list is readable.
- [x] The workflow triggers on push to `main`, on every pull request, and on manual dispatch.
- [x] The workflow installs dependencies from `requirements.txt` and pins no dbt version inline.
- [x] The workflow uses the CPython minor version that the local setup script uses.
- [x] The workflow caches the pip download directory, keyed on `requirements.txt`, and a cache miss does not fail the run.
- [x] The workflow runs `dbt build` with no `--select` and no warehouse artifact restored.
- [x] The workflow runs `dbt test` after the build, as its own step.
- [x] The workflow does not run `dbt source freshness`.
- [x] The workflow uploads `target/` on failure only, and a green run uploads nothing.
- [x] The workflow has no repository secret and no cloud credential.
- [x] A comment in the file states that the missing `--select` is deliberate.
- [x] The log shows seed, model and test counts, so a real build is one click away.
- [ ] The first run on `main` is green.

## Comments

Commit `43a9907` adds the workflow and two repairs that a clean runner forced.

**Evidence, from a clean state** (no `target/`, no `warehouse.duckdb`, no `~/.dbt` profile):

- `dbt build` gives PASS=38, ERROR=0.
- `dbt test` gives PASS=30, ERROR=0.
- A deliberate failing test turned the run red. The log named the test, the row count and the failing SQL. The author then deleted the scratch test.

**Two defects that a populated local warehouse hid:**

1. `models/staging/_stg__sources.yml` named schema `raw`. `dbt seed` puts the tables in `main`. Four source tests failed on a clean build. The declaration now names `main`, and `profiles.yml` states the schema explicitly.
2. The seeds had no tests. `seeds/_seeds.yml` adds key tests, so a duplicate key fails on the seed before any model runs. This is a DAG position choice, not extra coverage. The staging tests already cover the same rows.

**Left for later tickets:**

- The final box needs the GitHub run URL. A human supplies it under ticket 05, once the first push to `main` runs the workflow. Delete this line when the URL is here.
- `docs.yml` uses CPython 3.12 and an unpinned `dbt-duckdb`. Ticket 02 repairs both.
- `docs.yml` does not wait for the build. Ticket 03 adds the edge.
- A stale `target/partial_parse.msgpack` on a developer machine holds an old absolute path. It breaks the build until `target/` goes. CI never hits this, because it starts with no `target/`.
