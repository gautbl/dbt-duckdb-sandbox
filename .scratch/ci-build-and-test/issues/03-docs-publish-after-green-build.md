# 03: Docs publish only after a green build

**What to build:** The documentation workflow names the build workflow as a prerequisite. The site then publishes only after a green build, so it never shows a warehouse that failed its tests.

The build workflow and the docs workflow keep separate verdicts. The build verdict must not hide the docs verdict, and the docs verdict must not hide the build verdict. A red build gives a red build check, and the docs deploy does not start.

The documentation workflow keeps its own permissions block. Pages deployment writes to the repository, and the build workflow must not carry that write access.

**From the review of tickets 01 and 02.** Spec decision 9 and user story 11 name this edge. It is the one medium finding on the spec axis. Two smaller points sit here:

- `docs.yml` installs dbt on each run and caches nothing. Add the same pip cache as `build.yml:35-38` if the docs job earns it. One run per push to `main` makes the gain small, so this part is optional.
- Both workflows pass `--profiles-dir .`. Keep the two step shapes alike so a later reader sees one pattern, not two.

**Blocked by:** 01

**Status:** resolved

- [x] The documentation workflow waits for the build workflow.
- [x] A red build stops the docs deploy.
- [x] The two workflows report separate verdicts.
- [x] The documentation workflow keeps its Pages write permission, and the build workflow has no Pages write permission.
- [x] The two workflow files present one install-and-run shape, not two.

## Comments

`docs.yml` now triggers on `workflow_run`, not on `push`. The edge names the
build workflow, takes `types: [completed]`, and filters `branches: [main]`.
That `branches` filter reads the branch of the run that triggered it. The job
then reads `github.event.workflow_run.conclusion`.

The `if:` guard is one expression, and it covers every event shape:

| Event that ends the build | Deploy |
|---|---|
| push to `main`, green | yes |
| push to `main`, red | no |
| push to `main`, cancelled | no |
| pull request, green | no |
| manual dispatch of `build.yml`, green | no |

The first version of this ticket let a manual dispatch of `docs.yml` deploy
with no build verdict. Review rejected that path. Decision 9 says the site
shows no warehouse that failed its tests, and a dispatch reads no build at
all. So `docs.yml` now carries no `workflow_dispatch` trigger. To redeploy the
site, dispatch the build workflow: a green run starts this workflow in turn.

**Two verdicts, two checks.** Each workflow keeps its own file, its own name
and its own check on the commit. The docs job reports `skipped` when it does
not deploy, or absent when the trigger does not fire. That verdict shows
beside the build verdict, and neither one masks the other.

**Permissions stay split.** `build.yml` holds `contents: read` only. `docs.yml`
keeps `contents: read`, `pages: write` and `id-token: write`. A build run
cannot write to Pages.

**One install shape.** The two files share four steps word for word:
`actions/checkout@v4`, `actions/setup-python@v5` with CPython `3.13`, the pip
cache keyed on `requirements.txt`, and `pip install -r requirements.txt`. Both
dbt commands pass `--profiles-dir .`. The ticket called the docs pip cache
optional. It went in, because the shape argument is the stronger one.

**The checkout ref.** The docs job checks out
`github.event.workflow_run.head_sha`, so the site shows the commit that the
green build tested. A plain checkout reads `main` when the job starts, and a
new push can change that commit.

**Evidence, local:**

- `dbt build --profiles-dir .` gives PASS=38, ERROR=0.
- `dbt test --profiles-dir .` gives PASS=30, ERROR=0.
- `dbt docs generate --profiles-dir .` writes `catalog.json`.
- Both files parse with `yaml.safe_load`. The parse confirms the trigger, the
  two permission blocks and the job names.

**Two doc statements, checked before the design was set:**

- `on.workflow_run.branches` filters the branch of the *triggering* run. That
  filter alone does not stop a pull request run: a pull request into `main`
  can carry `main` as its base branch.
- A `workflow_run` workflow runs the copy of the file on the default branch,
  whatever branch triggered it.

**Review fixes.** The first version of the comments in `docs.yml` had two
false claims, and both now read true:

- It said that the `branches` filter stops a pull request build from reaching
  Pages. That claim was false. The `event == 'push'` term in the guard does
  the work.
- The checkout comment claimed the `head_sha` fix in all cases. The
  `|| github.sha` fallback broke that claim. The fallback is gone, so the
  comment now reads true.

**Left for later tickets:**

- The README states nothing about the docs gate. Ticket 04 adds the line.
- Ticket 05 records the GitHub run URLs. No runner ran this edge yet.

## Answer

The docs site now follows a green build through one edge. `docs.yml` triggers
on `workflow_run` of the build workflow, filtered to `branches: [main]` and
`types: [completed]`. The deploy job reads
`github.event.workflow_run.conclusion == 'success'` and
`github.event.workflow_run.event == 'push'`. A red, cancelled or pull request
run stops the deploy. The two workflows keep separate verdicts, and
`build.yml` holds no Pages write permission. Both files share one install
shape.

No trigger reaches the deploy without a green build. A manual dispatch of
`build.yml` starts the docs workflow only when its run is green.

Deploy evidence from a real runner is still open, under ticket 05.
