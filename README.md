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