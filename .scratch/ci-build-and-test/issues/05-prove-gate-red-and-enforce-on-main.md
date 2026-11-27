# 05: Gate proved red, then enforced on `main`

**What to build:** Two steps that a human does in GitHub. A fresh agent cannot do either step, and neither step is code.

**Step 1 — negative control.** Push a deliberately failing data test on a scratch branch. Take the shape from `tests/assert_fct_orders_net_revenue_nonnegative.sql`: a query returns violating rows, and zero rows means a pass. The new test returns rows on purpose, so the gate turns red. Record the run URL as evidence, then delete the branch.

This step proves the gate can fail, not only pass. A local run already showed the red result. The workflow needs the GitHub URL.

**Step 1b — record the first green run.** Open the Actions tab and copy the URL of the first green run on `main`. Paste it under `## Comments` here and in ticket 01. Ticket 01 keeps one box open for this URL.

**Step 2 — enforce the gate on `main`.** Add a branch protection rule or a ruleset on `main` that needs the build workflow check to pass. The gate then blocks a merge instead of advising on it. This is a GitHub repository setting, not a workflow setting, and no workflow file can carry it.

**From the review of tickets 01 and 02.** User story 21 asks for a green first run, and no GitHub run URL exists yet. The local clean run gives 38 of 38 and 30 of 30, and that run does not prove the runner. Step 1b supplies the URL. Ticket 01 keeps one box open until then.

**Blocked by:** 01 (a green run must exist before the gate can turn red)

**Status:** ready-for-human

- [X] A deliberately failing data test turned the build workflow red on a scratch branch.
- [ ] The red run URL is recorded under `## Comments`.
- [ ] The URL of the first green run on `main` is recorded here and in ticket 01.
- [ ] The scratch branch is deleted.
- [ ] `main` has a branch protection rule or a ruleset that needs the build workflow check.
- [ ] A pull request with a red build cannot merge.
