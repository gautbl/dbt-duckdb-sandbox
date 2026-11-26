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
- Permissions and the `github-pages` environment block stay as they were.
- No inline dbt pin survives in either workflow.

### Review, tickets 01 and 02 against `origin/main`

Two-axis review at `5300624`. Standards axis: 6 findings, none hard. Spec axis: 9 findings, 7 of them owned by tickets 03, 04 or 05.

Both axes found tickets 01 and 02 sound. Two findings belonged to this ticket's files and I repaired them in `cd6a9f7`:

- `models/staging/_stg__sources.yml:6` and `profiles.yml:11-14` disagreed in prose. The source comment said "no `schema` here on purpose" directly above `schema: main`. Both comments now name the pair and the prefix rule.
- The two comments repeated the same prefix explanation. They now split the meaning: the source names the match, the profile names the prefix.

### Left open for other tickets

- `docs.yml` does not wait for the build. Ticket 03 adds the edge.
- The README states nothing about CI. Ticket 04 adds the line.
- `docs/overview.md:19` still calls the seeds "ingested outside dbt". `_stg__sources.yml:3` now says `dbt seed` loads them. Ticket 04 aligns the two docs.
- The second workflow still carries no pip cache, so a docs run downloads dbt each time. Ticket 03 can add the cache beside the build edge, or leave it. The docs job is one run per push to `main`, so the gain is small.
