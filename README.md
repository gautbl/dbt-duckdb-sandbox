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
