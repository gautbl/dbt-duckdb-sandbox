# 05: Gate proved red, then enforced on `main`

**What to build:** Two steps that a human does in GitHub. A fresh agent cannot do either step, and neither step is code.

**Step 1 — negative control.** Push a deliberately failing data test on a scratch branch. Take the shape from `tests/assert_fct_orders_net_revenue_nonnegative.sql`: a query returns violating rows, and zero rows means a pass. The new test returns rows on purpose, so the gate turns red. Record the run URL as evidence, then delete the branch.

This step proves the gate can fail, not only pass. A local run already showed the red result. The workflow needs the GitHub URL.

**Step 1b — record the first green run.** Open the Actions tab and copy the URL of the first green run on `main`. Paste it under `## Comments` here and in ticket 01. Ticket 01 keeps one box open for this URL.

**Step 2 — enforce the gate on `main`.** Add a branch protection rule or a ruleset on `main` that needs the build workflow check to pass. The gate then blocks a merge instead of advising on it. This is a GitHub repository setting, not a workflow setting, and no workflow file can carry it.

**From the review of tickets 01 and 02.** User story 21 asks for a green first run, and no GitHub run URL exists yet. The local clean run gives 38 of 38 and 30 of 30, and that run does not prove the runner. Step 1b supplies the URL. Ticket 01 keeps one box open until then.

**Blocked by:** 01 (a green run must exist before the gate can turn red)

**Status:** resolved

- [X] A deliberately failing data test turned the build workflow red on a scratch branch.
- [X] The red run URL is recorded under `## Comments`.
- [X] The URL of the first green run on `main` is recorded here and in ticket 01.
- [X] The scratch branch is deleted.
- [X] `main` has a branch protection rule or a ruleset that needs the build workflow check.
- [X] A pull request with a red build cannot merge.

## Comments

**Red run, the negative control.**
https://github.com/gautbl/dbt-duckdb-sandbox/actions/runs/45978807387

- Event `pull_request`, branch `scratch/gate-red-proof`, sha `11b3cec`, conclusion `failure`.
- Test `tests/assert_negative_control_returns_rows.sql` inverts the predicate to `net_revenue >= 0`. It returns rows on purpose, so the gate turns red.
- The check named `build` reports `failure`.
- The log gives `31 of 39 FAIL 10 assert_negative_control_returns_rows`, then `Got 10 results, configured to fail if != 0`, then `PASS=35 WARN=0 ERROR=1 SKIP=3 TOTAL=39`.
- Steps 1 to 5 passed. Step 6 "Build the warehouse" failed. Step 7 skipped. The `dbt-target` artifact uploaded, so a red run keeps its diagnosis inputs.
- The local run agrees: `1 of 1 FAIL 10` and `PASS=0 WARN=0 ERROR=1`.

**First green run on `main`, step 1b.**
https://github.com/gautbl/dbt-duckdb-sandbox/actions/runs/45972752029

- Run 45972752029, event `push` to `main`, sha `ef79c0e`, conclusion `success`.
- This run is the first green run of `build.yml` on `main`. The same URL sits in ticket 01.

**Green pull request, the positive control.**
https://github.com/gautbl/dbt-duckdb-sandbox/pull/3

- Run https://github.com/gautbl/dbt-duckdb-sandbox/actions/runs/46006963360 gives check `build` success on sha `d1f62a5`. Merge state `clean`.
- A pull request with a green `build` check merges. The rule opens for good work.
- So the rule holds red work and passes green work, and the ticket edits reached `main` through the gate.
- Pull request 2 did the same earlier, with run https://github.com/gautbl/dbt-duckdb-sandbox/actions/runs/45987606723.

**Runs on `main` with the rule live.**

- Run https://github.com/gautbl/dbt-duckdb-sandbox/actions/runs/46005417111 is green on sha `c6a7447`, the merge of pull request 2.
- Run https://github.com/gautbl/dbt-duckdb-sandbox/actions/runs/46007112993 is green on sha `d11941e`, the merge of pull request 3.
- Both runs show that a merge through the gate leaves `main` green.

**Rule on `main`.**

- A classic branch protection rule, pattern `main`. No ruleset exists, so `/rules` stays empty.
- Check that must pass: `build`, the job name in `build.yml`. Strict mode off.
- Admins stay exempt, so the owner can still push a hotfix. Force push and branch delete stay off.
- Where to see it: Settings, Branches, "Branch protection rules".
- The rule lives in the repository settings. No workflow file can carry it, and no commit records it.

**Red pull request 1.**
https://github.com/gautbl/dbt-duckdb-sandbox/pull/1

- GitHub reports `mergeable: True`, `mergeable_state: blocked`, `merged: False`. The merge button stays grey.
- The pull request stays closed and unmerged, and it keeps the red URL as evidence.
- The branch `scratch/gate-red-proof` is gone from the remote.

**Method.** The rule went in through the GitHub REST API, on `branches/main/protection` with check `build`. The UI route gives the same result.
