# Spec: Continuous integration that builds and tests the warehouse

Status: ready-for-agent
Tracker: local markdown
Source: item 1 of `D:/projects/job-search/docs/project-improvements.md`

## Problem Statement

The repository has one workflow: `.github/workflows/docs.yml`. It runs `dbt docs generate` and publishes the result to GitHub Pages. It never builds a model and never runs a data test.

A broken model or a failing data test can reach `main` unnoticed. A reader who opens the workflow sees a documentation pipeline, not a test pipeline.

The project owner applies for a Staff Analytics Engineer role. The offer asks for CI/CD practice. The repository must show a pipeline that fails when the data is wrong.

## Solution

Add a continuous integration workflow. It builds the whole warehouse from nothing on a clean runner. It fails on any model error and on any data test failure.

The workflow runs the same command a developer runs locally, `dbt build`. Local success and CI success then mean the same thing. The workflow adds no separate test runner and no test harness.

The documentation workflow continues to publish the docs site. It waits for a green build.

## User Stories

1. As the project owner, I want every push to build the warehouse, so that the project works without my local file.
2. As the project owner, I want the workflow to fail on any data test failure, so that a bad seed cannot reach `main`.
3. As the project owner, I want the workflow to fail on any model error, so that a broken `ref()` shows up before review.
4. As the project owner, I want a run with no warehouse file, so that a hidden local dependency cannot pass CI.
5. As the project owner, I want `dbt deps` to run only when packages exist, so that the workflow stays correct later.
6. As the project owner, I want a failure to name the model and the column, so that I know where to look.
7. As the project owner, I want the log to show seed, model and test counts, so that a real build is one click away.
8. As the project owner, I want CI to install from `requirements.txt`, so that local and CI use the same versions.
9. As the project owner, I want CI to cache the Python dependencies, so that a run does not re-download dbt.
10. As the project owner, I want the build verdict separate from the docs verdict, so that neither hides the other.
11. As the project owner, I want the docs workflow to await a green build, so that the site never shows a bad warehouse.
12. As the project owner, I want the workflow name to state its purpose, so that the checks list is readable.
13. As the project owner, I want the build to run on a pull request, so that I get the verdict before the merge.
14. As the project owner, I want a manual trigger, so that I can re-run the build without a new commit.
15. As the project owner, I want a compile error to fail fast, so that I do not wait to learn about a typo.
16. As the project owner, I want CI to reuse my setup script's Python version, so that one environment serves both.
17. As a reviewer, I want a pipeline that runs `dbt build` and `dbt test`, so that the CI/CD claim is verifiable.
18. As a reviewer, I want the README to state what CI runs, so that the README and the workflow agree.
19. As a reviewer, I want no secret or cloud credential in the workflow, so that the project runs on any machine.
20. As a future contributor, I want one documented command for the full check, so that I need not discover the steps.
21. As the project owner, I want the first run to be green, so that the new gate is trusted from day one.
22. As the project owner, I want a red run to print the failing test SQL, so that diagnosis needs no reproduction.
23. As the project owner, I want `target/` uploaded on failure, so that I can read `run_results.json` after a red run.
24. As the project owner, I want the docs workflow to install dbt the same way, so that a dependency change is one edit.
25. As the project owner, I want the build to be a check on `main`, so that the gate is enforced rather than advisory.

## Implementation Decisions

### The seam

One seam, and it is an existing command: a full `dbt build` against a fresh warehouse. The project needs no test harness, no fixture loader and no custom script. CI invokes the same command as a developer.

A second, smaller seam covers the source declarations. A clean runner reproduces a freshness defect that a developer does not see. The developer has a populated local database, so the defect stays hidden.

### Files affected

- A new GitHub Actions workflow for build and test. It is a separate file from the documentation deployment, so the two have independent verdicts.
- The documentation workflow gains a prerequisite on the build workflow.
- `requirements.txt` becomes the single source of the dbt version for local setup and for CI. The workflows install from it rather than pinning a version inline.
- `README.md` gains a line stating what CI runs.
- `dbt_project.yml` gains a `snapshot-paths` entry only if the sibling snapshot feature needs it.

### Decisions

1. **The workflow runs both commands.** The build step runs `dbt build`. That command selects seeds, models, snapshots and tests in dependency order. A separate `dbt test` step then runs the tests again.

   Rationale: the CV claim is "dbt build et dbt test exécutés en intégration continue". The claim is the deliverable. The workflow must match the claim, so it runs both commands even though the second repeats work.

2. **Fresh warehouse per run.** `warehouse.duckdb` is not in version control, so a runner has no database. The build starts from seeds with no cleanup step. The workflow must not restore a warehouse artifact, because the missing database is the check.

3. **Pinned dependencies.** CI installs `requirements.txt`. A version drift between that file and a workflow-level pin is the failure mode to avoid.

4. **No freshness check in CI.** The workflow runs `dbt build` and `dbt test`. It does not run `dbt source freshness`.

   The staging source declarations name a `loaded_at` column that the seed CSV files do not carry. `dbt build` does not run freshness checks, so the build passes. `dbt source freshness` would fail. That is a known defect. Its fix changes the source contract and the docs site, so a separate ticket covers it.

5. **Python version.** CI uses the same CPython minor version as the local setup script. The two environments do not diverge.

6. **Dependency caching.** CI caches the pip download directory, keyed on `requirements.txt`. A cache miss must not fail the run.

7. **Artifacts on failure only.** CI uploads `target/` when a step fails. `run_results.json` and `compiled/` are the diagnosis inputs. A green run uploads nothing, so it stays fast.

8. **Triggers.** Push to `main`, every pull request, and manual dispatch. A pull request run gives the verdict before the merge.

9. **Two workflows, one edge.** The build workflow is separate from the documentation workflow. The documentation workflow names the build workflow as a prerequisite. The docs then publish only after a green build. The docs workflow keeps its own permissions block. Pages deployment needs write access that the build workflow must not have.

10. **No credentials.** CI uses no cloud account and no repository secret. DuckDB runs in-process. An outsider can read the workflow, and any fork can reproduce it.

11. **The check on `main` is manual.** Marking the build workflow as a check on `main` is a repository setting. The ticket records it as a step for a human, not as agent work.

## Testing Decisions

### What makes a good test here

The unit under test is the project as a whole, not a module. A good check asserts an external, observable outcome:

- The command exits zero.
- Every declared model exists in the warehouse after the run.
- Every declared data test passes.

A bad test asserts internal structure, such as the number of CTEs in a compiled model, or the exact SQL text. Those change for reasons unrelated to correctness.

### The seams under test

1. **`dbt build` on a fresh warehouse.** This is the primary seam. Expected behaviour: exit code zero, and `run_results.json` reports zero failures across seeds, models and tests.

2. **`dbt test` after the build.** This is the secondary seam. Expected behaviour: exit code zero, and the summary line reports the same test count as the build run.

3. **Negative control.** A deliberately failing test must turn the workflow red. This proves the gate works rather than merely runs. The ticket does this once by hand on a scratch branch, and records the run URL as evidence.

### Earlier art

- `tests/assert_fct_orders_net_revenue_nonnegative.sql` is the existing singular test. A test query returns violating rows, and zero rows means a pass. The negative control uses the same shape.
- The `schema.yml` files under `models/` declare the generic tests. They need no change for this feature.
- The local command in `README.md`, `dbt build`, is the pattern that the CI command follows. The workflow adds no new interface.

### Coverage

Every model in the DAG is covered, because `dbt build` selects the whole project. The workflow uses no `--select`, so a new model joins CI automatically. That property is deliberate and needs a comment in the workflow file.

## Out of Scope

- The customer country snapshot. That is a separate spec.
- Source freshness in CI.
- A cloud warehouse target such as Snowflake or BigQuery.
- Docker. The project states no Docker, and CI does not add one.
- Deployment of the marts to a serving layer. There is no serving layer.
- Test coverage thresholds. dbt has no such notion.
- Nightly or scheduled runs. The Airflow DAGs in `dags/` illustrate scheduling, and this workflow does not duplicate them.
- Branch protection as code. The check is a manual repository setting.

## Further Notes

- The CV claim this unlocks is "dbt build et dbt test exécutés en intégration continue". It replaces "documentation publiée en CI".
- This is item 1 of the improvement list and carries the most weight for the target offer. A reviewer sees it in one click on the repository's Actions tab.
- README wording must match the workflow. If the workflow changes, the README line changes in the same commit.
- The documentation workflow installs dbt with no version pin. Aligning it with `requirements.txt` is a small, low-risk change, and it belongs to this feature.
- This spec creates no `GLOSSARY.md` and no ADR. The project has neither. The vocabulary here is standard dbt vocabulary, so a glossary adds nothing yet.
