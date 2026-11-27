# dbt + DuckDB sandbox

A demonstrable dbt project for a **Senior Data Analyst** role.
Built with DuckDB — no Docker, no cloud account.

## What this project demonstrates

| Pattern | Where to find it |
|---|---|
| **Medallion architecture** (bronze → silver → gold) | `seeds/` → `models/staging/` → `models/intermediate/` → `models/marts/` |
| **Star schema at gold layer** | `dim_customers` + `dim_date` foreign-keyed by `fct_orders` and `fct_orders_daily` |
| **Incremental facts with merge strategy** | `fct_orders_daily` — only processes new `order_date`s on each run |
| **Data tests** | `unique`, `not_null`, `accepted_values`, `relationships` on every key column |
| **Source freshness** | Declared on `raw.orders` and `raw.customers` with warn/error thresholds |
| **Ephemeral models** | `int_order_totals` — inlined as CTE into each `ref()` caller |
| **Browsable documentation site** | `dbt docs generate` → `dbt docs serve` |
| **Continuous integration** | `.github/workflows/build.yml` — `dbt build`, then `dbt test`, on every pull request and every push to `main` |

## Layout

```
setup.ps1                   recreates the environment (venv + dbt profile); idempotent
setup.cmd                   the same, callable from cmd.exe / Git Bash
requirements.txt            dbt-core + dbt-duckdb, pinned
dbt_project.yml             project config: name, profile, paths, docs-paths
profiles.yml                the connection profile (source of truth for ~/.dbt)
docs/overview.md            custom landing page for the generated docs site
seeds/raw_*.csv             tiny "ingested" data — the raw / bronze layer
models/staging/             layer 1 (silver): views, one per seed, renamed + typed (+ tests)
models/intermediate/        layer 2 (silver): ephemeral model — never lands in the warehouse
models/marts/               layer 3 (gold): table (dim + fact) + incremental (daily rollup)
tests/                      custom data tests (e.g. assert_fct_orders_net_revenue_nonnegative)
.github/workflows/          build.yml (the build gate) + docs.yml (the docs publish)
```

## Quick start

Needs [uv](https://docs.astral.sh/uv/) (it installs a 64-bit CPython 3.13 with DuckDB wheels).

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

**MacOS / Linux:**
```sh
bash setup.sh
```

Done when it ends with a `dbt --version` block naming dbt-core and dbt-duckdb.

Each script wipes and rebuilds `.venv`. It then syncs the sandbox block between the `>>> dbt-duckdb-sandbox >>>` markers in `~/.dbt/profiles.yml`.

Plain `dbt <command>` works from the project root after that. Edit connections only in `profiles.yml` here. Never hand-edit the copy in `~/.dbt`.

## Daily use

**Windows:**
```powershell
.venv\Scripts\activate
dbt build                    # seeds + models + tests in one ordered run
```

**MacOS / Linux:**
```sh
source .venv/bin/activate
dbt build
```

## Continuous integration

Two workflows run on GitHub Actions. They keep separate verdicts, so neither hides the other.

**Build gate.** `.github/workflows/build.yml` runs on every pull request, on every push to `main`, and on manual dispatch. A newer run on the same ref cancels an older one. The job installs from `requirements.txt` on CPython 3.13. It then runs these two commands:

```
dbt build --profiles-dir .
dbt test --profiles-dir .
```

`dbt build` selects every seed, model and test in dependency order, with no `--select`. A new model joins CI with no edit to the workflow.

The second command repeats work on purpose, so the workflow runs both commands that a developer runs. Only the `--profiles-dir .` flag differs, and a runner needs it. When a run fails, dbt logs the model and the column. The workflow uploads `target/` on a failure or a cancel, so `run_results.json` and `compiled/` stay readable. A green run uploads nothing.

CI does **not** run `dbt source freshness`. The source declarations name a `loaded_at` column that the seed files do not carry, so a freshness check would fail. Freshness stays a local step.

**Docs publish.** `.github/workflows/docs.yml` follows a green build. It triggers on a completed run of the build workflow, and two guards decide the deploy. The run must be green, and its trigger must be a push to `main`. A pull request build never reaches the site, because its base branch can name `main`. The job checks out the commit that the green build tested, so the site shows that commit. There is no dispatch trigger on the docs workflow. To redeploy the site, dispatch the build workflow: a green run starts the docs publish in turn.

The workflow files are the source of truth for these commands. When a workflow changes, change the matching line here in the same commit.

## The full check

One command runs the whole check. After `setup.ps1` or `setup.sh`, a developer
runs it from the project root with no extra flag:

```
dbt build
```

`dbt build` runs every seed, model and test in dependency order, so a green
build is the same verdict that CI reports. CI then repeats the tests as a
second command. That second command takes `--profiles-dir .`, because a runner
has no `~/.dbt` profile:

```
dbt test --profiles-dir .
```

## Generate the documentation site

```powershell
dbt docs generate
dbt docs serve               # opens localhost:8080
```

The site includes an interactive DAG viewer, model descriptions, column types, and test results.

### Walkthrough

1. `dbt docs generate` compiles the project and introspects DuckDB's `information_schema` for column
types, row counts, and catalog metadata. It writes a static site to `target/`.

2. `dbt docs serve` starts a local HTTP server on port 8080. Open `http://localhost:8080`.

3. The landing page shows the custom overview from `docs/overview.md` (a docs block named
`__overview__`). It describes the medallion architecture, key design decisions, and source freshness
links.

4. Use the **DAG view** (View lineage) to see model dependencies. Click any model node to see its
description, columns, tests, and SQL.

5. The **Source freshness** tab shows freshness checks on `raw.orders` and `raw.customers`. Run `dbt
source freshness` to update this data.

6. Share the site as a static artifact: run `dbt docs generate --target-path docs-site`, then publish
the `docs-site/` folder to GitHub Pages, Netlify, or any static host. The site is pure HTML + JSON
(WASM-powered on dbt v2).
