# 02: The docs workflow installs the same way as the build workflow

**What to build:** The documentation workflow installs its dependencies from `requirements.txt`. Today it installs the adapter package with no version, so its dbt version can drift from the local setup and from the build workflow.

After this ticket, one file states the dbt version. One edit changes it for local setup, for the build gate and for the docs deploy. A dependency change is one edit, not three.

The documentation workflow keeps its behaviour: it still generates the docs and it still deploys the site.

**Blocked by:** 01 (the build workflow states the pattern to copy)

**Status:** resolved

- [x] The documentation workflow installs from `requirements.txt` and pins no version inline.
- [x] The documentation workflow still generates the docs and deploys the site.
- [x] A single edit to `requirements.txt` changes the dbt version for local setup and for both workflows.

## Comments

`docs.yml` now matches `build.yml` on three points: `pip install -r requirements.txt`, CPython `3.13`, and `--profiles-dir .`.

**A defect the ticket did not name.** The old `dbt docs generate` had no `--profiles-dir`. It worked on a developer machine because `~/.dbt/profiles.yml` exists there. A GitHub runner has no such file, so the docs job would fail on a clean runner. The build workflow hit the same trap in ticket 01. Both workflows now pass `--profiles-dir .`.

**Evidence, from a clean state** (no `target/`, no `warehouse.duckdb`, no `~/.dbt` profile):

- `dbt build --profiles-dir .` gives PASS=38, ERROR=0.
- `dbt test --profiles-dir .` gives PASS=30, ERROR=0.
- `dbt docs generate --profiles-dir .` succeeds and writes `target/catalog.json`.
- `dbt docs generate` with no `--profiles-dir` and a clean HOME fails. That confirms the defect above.

**Checked for regression:**

- `upload-pages-artifact` reads `path: target`. `dbt docs generate` writes to `target/`. The paths agree.
- `docs generate` also writes an empty `warehouse.duckdb` to the workspace root. That path sits outside `target`, so the Pages artifact stays clean.
- Permissions and the `github-pages` environment block are unchanged.
- No inline dbt pin survives in either workflow.
