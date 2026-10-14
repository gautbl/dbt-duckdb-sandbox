{{ config(materialized='table') }}

-- dim_date: one row per calendar day.
-- Covers the full date range of the orders data (2024).
-- In production this would cover 10+ years; here we use
-- a dbt macro to generate it inline.

with date_spine as (
    -- DuckDB generates the sequence natively — no dbt macro needed
    select generate_series as days
    from generate_series(
        date '2024-01-01',
        date '2024-12-31',
        interval 1 day
    )
)

select
    days                                          as date_day,
    extract(year from days)                       as year,
    extract(month from days)                      as month,
    monthname(days)                               as month_name,
    extract(week from days)                       as week_of_year,
    extract(dow from days)                        as day_of_week,
    case when extract(dow from days) in (0, 6)
         then true else false end                 as is_weekend,
    current_timestamp                             as dbt_loaded_at
from date_spine