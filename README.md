# dbt + DuckDB sandbox

A demonstrable dbt project for the **Senior Data Analyst** role at Groupe Foyer (Luxembourg).
Built with DuckDB — no Docker, no cloud account. Every file is small on purpose: you can read
all of it and explain every piece.

## What this project demonstrates

| Pattern | Where to find it |
|---|---|
| **Medallion architecture** (bronze → silver → gold) | `seeds/` → `models/staging/` → `models/intermediate/` → `models/marts/` |
| **Star schema at gold layer** | `dim_customers` + `dim_date` foreign-keyed by `fct_orders` and `fct_orders_daily` |
| **Incremental facts with merge strategy** | `fct_orders_daily` — only processes new `order_date`s on each run |
| **Data tests** | `unique`, `not_null`, `accepted_values`, `relationships` on every key column |
| **Source freshness** | Declared on `raw.orders` and `raw.customers` with warn/error thresholds |
| **Ephemeral models** | `int_order_totals` — inlined as CTE into each `ref()` caller |
| **Browsable documentation site** | `dbt docs generate` → `dbt docs serve` (see lesson 0008) |

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
```

## Quick start

Requires [uv](https://docs.astral.sh/uv/) (it manages a 64-bit Python 3.13 — the system
Python here is 32-bit, which has no DuckDB wheel).

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

Done when it ends with a `dbt --version` block naming dbt-core and dbt-duckdb. It wipes and
rebuilds `.venv`, then syncs the sandbox block between the `>>> dbt-duckdb-sandbox >>>`
markers in `%USERPROFILE%\.dbt\profiles.yml` — so plain `dbt <command>` works from the
project root. Edit connections only in `profiles.yml` here; the copy in `~/.dbt` is derived,
never hand-edited.

## Daily use

```powershell
.venv\Scripts\activate
dbt build                    # seeds + models + tests in one ordered run
```

## Generate the documentation site

```powershell
dbt docs generate
dbt docs serve               # opens localhost:8080
```

The site includes an interactive DAG viewer, model descriptions, column types, and test
results. See [lesson 0008](../../lessons/0008-dbt-docs-and-portfolio.html) for the full walkthrough.

## Course map

These lessons build on each other toward the target role. Each is a self-contained HTML file
with a quiz and hands-on exercise.

| # | Lesson | Topic |
|---|---|---|
| 0001 | [The dbt core loop](../../lessons/0001-dbt-core-loop.html) | `dbt run`, `dbt build`, `ref()`, project structure |
| 0002 | [Sources, tests & layers](../../lessons/0002-dbt-sources-tests-and-layers.html) | `source()`, generic tests, staging/intermediate/marts |
| 0003 | [Iceberg: what a table really is](../../lessons/0003-iceberg-table-format.html) | Snapshots, hidden partitioning, ACID on object stores |
| 0004 | [Airflow DAGs in practice](../../lessons/0004-airflow-dags-in-practice.html) | Operators, dependencies, scheduling, catchup |
| 0005 | [Medallion architecture](../../lessons/0005-medallion-architecture.html) | Bronze/silver/gold mapping to dbt layers |
| 0006 | [Star schemas & KPI design](../../lessons/0006-star-schemas-and-kpis.html) | Facts vs dimensions, Kimball modelling, interview vocabulary |
| 0007 | [Incremental materializations](../../lessons/0007-incremental-materializations.html) | `is_incremental()`, strategies, filter-on-incremental pattern |
| 0008 | [dbt docs & the portfolio project](../../lessons/0008-dbt-docs-and-portfolio.html) | Generating the docs site, docs blocks, portfolio artifact |

## Agents

Treat `profiles.yml` and `setup.ps1` as the source of truth; `%USERPROFILE%\.dbt\profiles.yml`
is derived (re-run `setup.ps1` to sync). `warehouse.duckdb`, `target/`, `logs/` and `.venv/`
are build artifacts — regenerate, never commit.