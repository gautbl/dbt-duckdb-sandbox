{{ config(materialized='table') }}

-- Gold layer: customer dimension.
-- One row per customer. This is what every fact table
-- should join to, not the staging view directly.
select
    customer_id,
    customer_name,
    country,
    segment,
    current_timestamp as dbt_loaded_at
from {{ ref('stg_customers') }}