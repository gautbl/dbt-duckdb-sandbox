# 06: The docs site publishes after a merge to `main`

**What to build:** The docs deploy passes after a green build of a merged pull request. Today every docs run after a merge commit fails at its last step. The site then keeps an old build. The failure reads as an artifact fault, not a docs fault.

Reproduce the fault and find its cause. Then make the deploy stable. Three merges in a row must publish the site.

**Blocked by:** None (can start immediately). Ticket 03 added the green-build edge, and this ticket repairs the deploy leg of that edge.

**Status:** resolved

- [x] A pull request merges with a green build, and the docs run that follows passes its deploy step.
- [x] Two later merges do the same, so the fault does not return in three runs.
- [x] The site at https://gautbl.github.io/dbt-duckdb-sandbox/ serves the latest docs.
- [x] A red build still stops the deploy, as ticket 03 asks.
- [x] A comment in the workflow names the cause, and a reader can tell why the deploy broke.

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

**Cause found, and the lead is false.** Read the section "Cause and fix" under
Comments. Run 46005499345 is a merge commit and it passed. The fault is a race
in the GitHub artifact metadata service, not in the trigger shape. See
actions/deploy-pages issue 451.

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

### First merge after the fix

Pull request 5 merged as `25d00f2`, and the build run passed. The docs run
that followed passed its deploy:

- Run https://github.com/gautbl/dbt-duckdb-sandbox/actions/runs/46013306443,
  `run_attempt` 1, `success`.
- Step 9, try 1 of 3, failed. Step 10 waited 20 s, and step 11, try 2 of 3,
  deployed at `14:10:05Z`. Steps 12 and 13 skipped.
- The race hit the first try on this run. The retry is the step that saved it,
  so the fix earned its place on the first live run.
- The site answers 200 at 1.8 MB, with `Last-Modified: 27 Nov 2026 14:10:01
  GMT`. That time is the deploy of try 2, so the site holds this build.

Open still: two more merges, and one red build to show that the guard holds.
The job guard did not change, so ticket 05 keeps its red evidence.

### The deploy log of the first merge, and the red proof

The log of run 46013306443 shows the race and the save in one page:

- Try 1, `14:09:38Z`: `Found 0 artifact(s)`, then `Error: No artifacts named
  "github-pages-1" were found for this workflow run`.
- Try 2, `14:09:59Z`: `Found 1 artifact(s)`, then the deploy goes through.

So the race hit the first try of the first live run. The retry is the step
that published the site. The name `github-pages-1` also proves the custom
artifact name reaches the action.

**A red build still stops the deploy.** Scratch branch
`scratch/gate-red-proof-2` carried the test
`tests/assert_red_proof_returns_rows.sql`. The test returns rows on purpose.

- Pull request 6, run
  https://github.com/gautbl/dbt-duckdb-sandbox/actions/runs/46014137881,
  event `pull_request`, sha `650fee3`, conclusion `failure`.
- The log gives `FAIL 10 assert_red_proof_returns_rows`, then `Got 10
  results, configured to fail if != 0`, then `PASS=35 WARN=0 ERROR=1 SKIP=3
  TOTAL=39`. Step 6 `Build the warehouse` failed, and step 7 skipped.
- No docs workflow run exists for sha `650fee3`. The build run was red, so
  the edge never fires, and the site keeps its last build.
- Pull request 6 is closed, and the branch is gone from the remote and from
  this clone.

The job guard did not change in this ticket, so a `conclusion` other than
`success` still stops the deploy. Ticket 05 keeps the first red evidence.

### Three merges in a row

The fault does not return in three runs:

| Merge | Commit | Docs run | Deploy |
|---|---|---|---|
| 1 | `25d00f2`, pull request 5 | 46013306443 | try 1 hit the race, try 2 deployed |
| 2 | `284c349`, pull request 7 | 46014566211 | try 1 deployed at once |
| 3 | `ae55639`, pull request 8 | 46014978847 | try 1 deployed at once |

Run 46014566211 and run 46014978847 skipped try 2 and try 3. That shows the
other side: when the artifact is visible at once, the extra steps cost
nothing.

The site at https://gautbl.github.io/dbt-duckdb-sandbox/ answers 200, and its
`Last-Modified` header follows the latest deploy.

## Answer

The deploy fault was a race in the GitHub artifact metadata service, not a
fault in this repository. `actions/deploy-pages` reads the artifact list of
its own run one time, and that list can stay empty for seconds after the
upload. A re-run then showed the second face: two artifacts with one name.

`docs.yml` now meets both faces. The artifact name carries
`github.run_attempt`, so one run never holds two artifacts with one name. The
deploy tries three times, with waits of 20 s and 40 s. The concurrency group
no longer cancels a live deploy. The header comment names the cause, the issue
number and the false merge-commit lead.

A red build still stops the deploy, and pull request 6 shows it. Three merges
in a row published the site.
