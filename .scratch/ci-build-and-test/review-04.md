# Review 04: README states what CI runs

**Scope reviewed:** uncommitted working-tree diff on `main` in `D:/projects/dbt-duckdb-sandbox`.
**Files in the diff:** `README.md`, `docs/overview.md`.
**Spec:** `.scratch/ci-build-and-test/issues/04-readme-states-what-ci-runs.md`.
**Evidence:** `.github/workflows/build.yml`, `.github/workflows/docs.yml`,
`models/staging/_stg__sources.yml`, `seeds/raw_orders.csv`, `seeds/raw_customers.csv`,
`profiles.yml`, `.scratch/ci-build-and-test/spec.md`.

**Verdict: NEEDS FIXES.** Three hard findings. Two are factual claims that the
workflow files do not support. One is an edit outside the sections the ticket names.

---

## Axis 1 — Spec conformance

| # | Checkbox | Status | Evidence | Severity when wrong |
|---|---|---|---|---|
| 1 | README states what CI runs, with the same commands as the workflows | PASS | `README.md:77-79` holds `dbt build --profiles-dir .` then `dbt test --profiles-dir .`. `build.yml:62` and `build.yml:65` hold the same two commands. | hard |
| 2 | README states the one command for the full check | PASS | `README.md:91-99`, under the new heading `## The full check`. `dbt build --profiles-dir .` is the one command. | hard |
| 3 | README states docs publish follows a green build | PASS | `README.md:87`. `docs.yml:18-19` and `docs.yml:53-56` support the claim. | hard |
| 4 | README states that a workflow change and its README line change in the same commit | PASS | `README.md:89`. | hard |
| 5 | README says CI runs no source freshness check | PASS | `README.md:85` and `README.md:125-126`. `build.yml` holds no `dbt source freshness` step. Spec decision 4 agrees. | hard |
| 6 | README.md and docs/overview.md agree on how the seed data loads | PASS | `README.md:31` (`seeds/raw_*.csv` = the raw layer) and `overview.md:16-18` (`dbt seed` loads a CSV under `seeds/`) agree. `_stg__sources.yml:5` names `dbt seed` as the loader. | hard |
| 7 | The words in the README match the workflow files | **FAIL** | See Standard A1 and A2 below. `README.md:74` overstates a trigger. `README.md:83` claims that a failure names the column. | hard |

All 7 checkboxes have a matching README passage. Checkbox 7 fails on wording, not on
absence.

---

## Axis 2 — Standards and factual accuracy

| # | Finding | File:line | Evidence | Severity |
|---|---|---|---|---|
| A1 | The README says the build gate runs on "manual dispatch". The README names a trigger, but not its limit. The `concurrency` group in `build.yml` cancels a running job on the same ref. A dispatch on `main` cancels a running push build on `main`. The claim is true, so this is a precision gap, not an error. The sentence also leaves out the `concurrency` cancel rule that the same README relies on at `README.md:87` ("A red or cancelled build never reaches the site"). Add the cancel rule, or drop the trigger detail. | `README.md:74` vs `build.yml:20-21`, `build.yml:31-33` | `build.yml:31-33` sets `cancel-in-progress: true` for group `build-${{ github.ref }}`. | soft |
| A2 | The README says "A failed or cancelled run names the model and the column." No workflow step prints a model or a column name. dbt writes the name to the log and to `target/run_results.json`. The workflow only uploads `target/`. The sentence describes a dbt property, not a workflow property, and it puts the claim on the workflow. Reword to "dbt logs the model and the column, and the uploaded `target/` holds them." | `README.md:83` vs `build.yml:67-76` | `build.yml:68-76` uploads `target/` with `if: failure() \|\| cancelled()`. No step parses the log. | soft |
| A3 | The README says CI "installs from `requirements.txt` on CPython 3.13." That is correct (`build.yml:48-52`). But the same README omits the pip cache step, which is spec decision 6. A reader cannot verify decision 6 from the README. Add one clause, or accept the gap on purpose. | `README.md:74` vs `build.yml:42-47` | `build.yml:42-47` holds the cache step, keyed on `requirements.txt`. | soft |
| A4 | The README says the docs job "checks out the commit that the green build tested." Correct (`docs.yml:64-68`). The README omits that the docs workflow has no `workflow_dispatch`, a stated decision (`docs.yml:22-30`, spec decision 9). A reader who wants a redeploy does not learn the documented path. Add the redeploy path in one sentence. | `README.md:87` vs `docs.yml:18-30` | `docs.yml:22-26` records the missing dispatch as a decision. | soft |
| A5 | The new `## Continuous integration` section says "Two workflows run on GitHub Actions." The README layout block at `README.md:33` also names both. That repeated statement is acceptable, but the two lines must stay in step. Note it as a maintenance load, not a defect. | `README.md:72`, `README.md:33` | Both name `build.yml` and `docs.yml`. | soft |
| A6 | **Edit outside the named sections.** The ticket says "Change no other section beyond what this ticket names." The ticket names three places: the pattern table, a new CI statement (README), and the seed-load alignment in `docs/overview.md`. The diff also edits walkthrough step 5 at `README.md:124-126`. The ticket names the freshness point, but it places that point in the CI statement. The walkthrough edit adds a second claim: "a published site shows whatever freshness result the build carried." That claim is also **wrong**. `docs.yml` runs `dbt docs generate` on a clean runner (`docs.yml:71`). The runner has no `manifest.json` freshness result. So the published site carries no freshness result at all, not a carried one. | `README.md:124-126` vs `docs.yml:60-71` | `docs.yml:60-71` checks out a fresh tree, then runs `dbt docs generate`. No freshness step comes before it in the job. | **hard** |
| A7 | `docs/overview.md:16` says the `raw` sources are "the CSV files under `seeds/`". The sources name the tables `main.raw_orders` and `main.raw_customers` (`_stg__sources.yml:11`, `:12`, `:25`, `:26`). After `dbt seed`, the sources are DuckDB tables, not files. The wording passes the ticket's narrow question, but it keeps the old file-seam shape that the ticket asks to remove. State that `dbt seed` copies the CSV into DuckDB tables, and the sources read those tables. | `docs/overview.md:16-18` vs `_stg__sources.yml:5`, `:11` | `_stg__sources.yml:5` says "Ingested CSV files, loaded by `dbt seed`". | soft |
| A8 | `_stg__sources.yml:15` and `:29` set `loaded_at_field: loaded_at`. `seeds/raw_orders.csv` and `seeds/raw_customers.csv` carry no `loaded_at` column. The README claim at `README.md:85` is **correct**. Spec decision 4 records this defect, and a separate ticket covers it. No change here. Cite as a verified claim. | `README.md:85`, `_stg__sources.yml:15`, `:29` | `seeds/raw_orders.csv` header: `order_id,customer_id,order_date,status,quantity,unit_price`. No `loaded_at`. | pass |
| A9 | Spec decision 1 says `dbt build` "selects seeds, models, snapshots and tests". The README at `README.md:81` says "every seed, model and test" and drops snapshots. The README is correct for this repo: there is no `snapshots/` directory and `dbt_project.yml` sets no `snapshot-paths`. The spec wording is the loose one. Keep the README as written. Record the spec wording as an item to fix later. | `README.md:81` vs `spec.md` decision 1 | `ls snapshots` returns nothing. `dbt_project.yml` has no `snapshot-paths`. | soft |
| A10 | The diff adds a whole new `## Continuous integration` section and a `## The full check` section. The ticket asks for a CI statement and a one-command statement, so the content is in scope. However, two top-level headings sit between `## Daily use` and `## Generate the documentation site`. The reader must now pass both to reach the docs steps. Consider one heading with two sub-parts. Structural preference only. | `README.md:70`, `README.md:91` | — | soft |
| A11 | `docs/overview.md:19-21` states the CI facts for the docs site. That site publishes from `docs.yml`, which runs `dbt docs generate` only. The overview does not say that CI runs no freshness check, while `README.md:85` does. The two docs agree on the seed load (checkbox 6) but differ on CI scope. The ticket does not ask for the freshness point in the overview, so this is a consistency gap, not a spec failure. | `docs/overview.md:19-21` vs `README.md:85` | — | soft |

---

## Checkbox 7 detail (words match the workflow)

| README words | Workflow truth | Result |
|---|---|---|
| "runs on every pull request, on every push to `main`, and on manual dispatch" (`README.md:74`) | `on: push: branches: [main]`, `pull_request:`, `workflow_dispatch:` (`build.yml:20-24`) | match |
| "installs from `requirements.txt` on CPython 3.13" (`README.md:74`) | `python-version: "3.13"` (`build.yml:49`), `pip install -r requirements.txt` (`build.yml:56`) | match |
| `dbt build --profiles-dir .` then `dbt test --profiles-dir .` (`README.md:77-79`) | `build.yml:62`, `build.yml:65` | match |
| "with no `--select`" (`README.md:81`) | `build.yml:9-10` comment, `build.yml:62` | match |
| "uploads `target/`" / "A green run uploads nothing" (`README.md:83`) | `if: failure() \|\| cancelled()`, `path: target/` (`build.yml:68-72`) | match |
| "A failed or cancelled run names the model and the column" (`README.md:83`) | No step does this. dbt logs it and `target/` holds it. | **does not match** |
| "follows a green build ... filtered to `main` ... completed run" (`README.md:87`) | `workflow_run: types: [completed], branches: [main]`, guard `conclusion == 'success'` (`docs.yml:18-24`, `:53-56`) | match |
| "checks out the commit that the green build tested" (`README.md:87`) | `ref: ${{ github.event.workflow_run.head_sha }}` (`docs.yml:67`) | match |
| "A red or cancelled build never reaches the site" (`README.md:87`) | `if: conclusion == 'success'` (`docs.yml:55`) | match |
| "CI runs no freshness check" (`README.md:85`, `:125`) | No freshness step in `build.yml` or `docs.yml` | match |
| "a published site shows whatever freshness result the build carried" (`README.md:126`) | `docs.yml` runs `dbt docs generate` on a clean tree with no freshness step. The site carries no result. | **does not match** |

---

## Findings summary

**Hard (block approve):**

1. **A6** — `README.md:124-126` is an edit outside the named sections. It also makes a false claim about the published site's freshness data. `docs.yml` has no freshness step, so the deployed site shows no freshness result. Fix: revert step 5 to its original one-line form. Or replace the added clause with "the published site carries no freshness result".
2. **A2** — `README.md:83` claims the workflow names the model and the column. No step does. Fix: attribute the naming to dbt and to `target/run_results.json`.
3. **Checkbox 7** — fails on the two claims above. It passes once A2 and A6 are fixed.

**Soft (fix or accept with a note):**

- A1 `README.md:74` — state the `concurrency` cancel rule, or drop the trigger detail.
- A3 `README.md:74` — the pip cache step is absent from the README. Spec decision 6 is not visible.
- A4 `README.md:87` — the docs redeploy path is not in the README. `docs.yml:22-30` records it as a decision.
- A5 `README.md:72` and `README.md:33` — two statements of the workflow list. Keep them in step.
- A7 `overview.md:16-18` — "CSV files under `seeds/`" keeps the file-seam wording. The sources are DuckDB tables after the seed.
- A9 spec decision 1 names snapshots. The README correctly drops them. Fix the spec, not the README.
- A10 `README.md:70`, `README.md:91` — two new top-level headings. Consider one heading with sub-parts.
- A11 `overview.md:19-21` — the overview does not state the freshness scope. `README.md:85` does.

**Verified correct (no change):**

- A8 — the `loaded_at` claim at `README.md:85` matches `_stg__sources.yml:15` and `:29`. Both seed CSV files lack the column.
- Checkboxes 1 to 6 all hold: the command match, the one command, the green-build gate, the same-commit rule, and the seed-load agreement.

---

## Verdict

**Needs fixes.** Reject the diff until A6 and A2 change.

Edits that must go in:

1. `README.md:124-126` — remove the added clause, or correct it to say that the site carries no freshness result.
2. `README.md:83` — move the "names the model and the column" claim from the workflow to dbt and `target/`.
3. Optional but recommended: A1, A3, A7. Each is one clause.

No edit was made to `README.md` or `docs/overview.md` in this review.
