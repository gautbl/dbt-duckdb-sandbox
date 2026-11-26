{% docs __overview__ %}
# dbt-duckdb-sandbox

A demonstrable dbt project for the Senior Data Analyst role at Groupe Foyer.
Built with DuckDB, organised in the medallion architecture
(bronze → silver → gold, mapped to staging → intermediate → marts).

## Key design decisions

- **Star schema at gold**: `dim_customers` + `dim_date` foreign-keyed by
  `fct_orders` and `fct_orders_daily`.
- **Incremental facts**: `fct_orders_daily` uses merge strategy for
  idempotent daily rebuilds. 
- **Data quality**: unique and not_null tests on every primary key;
  accepted_values on order `status`; referential integrity from orders → customers.
- **Ingestion seam**: `dbt seed` copies the CSV files under `seeds/` into DuckDB
  tables, and the `raw` sources read those tables. The load happens inside dbt, so a
  fresh clone builds the whole warehouse with no external loader.
- **Continuous integration**: `.github/workflows/build.yml` runs `dbt build` and then
  `dbt test`, on every pull request and every push to `main`. That build runs no
  source freshness check. The docs site publishes only after a green build.

## Links

- [Source freshness](./#!/source/raw.orders) (click through)
{% enddocs %}
