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

### Cause and fix

The fault is a race in the GitHub artifact metadata service, not a fault in
this repository. `actions/deploy-pages` reads the artifact list of its own run
once. That list can stay empty for seconds after the upload ends. The deploy
then reads `Found 0 artifact(s)` and stops in about 350 ms.

The record is actions/deploy-pages issue 451, open at this writing.

A public probe in that issue measured a hide time of 0.4 s to 6 s. The probe
saw the first lookup miss in 4 runs of 8. One report names a 60 s window.

The same issue names the second face of the fault. A re-run of the failed job
uploads a second `github-pages` artifact into the same run. The deploy then
stops with `Multiple artifacts named "github-pages" were unexpectedly found`.

Both faces appear in the runs of this ticket.

**The merge-commit lead is false.** The run API shows it:

- Run 46005499345 is the merge of pull request 2, sha `c6a7447`. Its job
  `deploy` reports `success`, and step 9 `Deploy to GitHub Pages` reports
  `success`. The ticket listed this run as a failure.
- Run 46007184209, sha `d11941e`, `run_attempt` 1. Step 9 fails 1 s after step
  8. Its artifact exists in the same run: id 15202057895, 706395 bytes, digest
  `sha256:e1f1f2...8efc`, created at `13:27:21Z`, the same second as step 8.
  The run is right and the artifact is right, and the list came back empty.
- Run 46007460191, sha `f487068`, `run_attempt` 2. The run holds two
  artifacts: 15202053382 (706546 bytes) and 15201069691 (706651 bytes). This
  is the duplicate face of the fault.
- Run 45972845303, sha `ef79c0e`, `run_attempt` 2, passed at `13:36:36Z`, one
  minute after the failure at `13:35:07Z`. A plain push fails and passes in
  one window, so the trigger shape does not decide the result.

The first failures followed merges by chance. The sample was small, and the
miss rate is about one half.

### The fix

`.github/workflows/docs.yml` answers both faces:

1. **One artifact name per `github.run_attempt` value.** The job sets
   `PAGES_ARTIFACT: github-pages-${{ github.run_attempt }}`. The upload and all
   deploys read that name. A re-run increments the value, so a run never holds
   two artifacts with one name, and the error that counts 2 cannot occur.
2. **Three tries of the deploy.** Try 1 and try 2 carry
   `continue-on-error: true`, and a wait of 20 s and 40 s sits between them.
   Try 3 sets the job verdict. The tries land near 0 s, 20 s and 60 s after the
   upload, which covers the observed window.
3. **No cancellation of a live deploy.** The concurrency group keeps
   `cancel-in-progress: false`, as the GitHub Pages starter workflow does. A
   cancelled deploy leaves the environment unfinished.

The comment at the top of the workflow names the cause, the issue number and
the false lead. A reader then sees why the deploy broke.

### What the run API shows, and what is still open

`gh` is not installed on this machine, and the environment holds no GitHub
token. The run and artifact facts above come from the anonymous REST API,
which serves the public repository. The step logs do not.

So this diagnosis rests on step timings, artifact metadata and the linked
public issue. These boxes need a human with repository write access:

- Merge three pull requests with a green build, and check the deploy step of
  each docs run. The first merge also proves the fix on this branch.
- Open https://gautbl.github.io/dbt-duckdb-sandbox/ and confirm the site
  serves the latest docs.
- Confirm that a red build still stops the deploy. Ticket 05 already shows the
  red build, and the job guard does not change.

The README line about the docs gate stays correct. The fix changes no trigger
and no guard.

### Two-axis review, and the state of each finding

The review ran on the diff `a8a60a2...HEAD`, with the Standards and the Spec
axes apart.

Standards, hard breaches, all closed:

- Four-sentence paragraphs in the workflow comment and in this file. `c1600af`
  splits them.
- One 30-word instruction with a colon. `c1600af` splits it into two.
- One 26-word sentence. `c1600af` splits it.
- The Comments history was replaced, not appended. `3596ffd` restores the run
  URLs, the symptom block, the rule-outs and the lead.

Standards, judgement calls, kept as they are:

- **Duplicated Code and Repeated Switches.** The deploy block repeats three
  times, and the `if: steps.deployN.outcome == 'failure'` test appears three
  times. YAML has no loop. A retry action would add a third-party dependency,
  and this repo carries first-party actions only.

Spec, open, and why:

- The three-merge evidence needs a human, as the section above says.
- The step log stays unread, because no token exists here. The cause rests on
  step timings, artifact metadata and issue 451.
- The `cancel-in-progress` change is scope creep against the ticket text. The
  workflow says why it is there, and ticket 03 does not record the reversal.

Spec, unproven until one live run:

- The custom artifact name. `deploy-pages` sends the artifact id to Pages, not
  the name, so the change should hold.
- A late failure can stack two deployments on one environment. The artifact
  race fails before that point, so the common case stays safe.
