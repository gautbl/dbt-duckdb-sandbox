{{ config(materialized='ephemeral') }}

-- Layer 2: intermediate. Ephemeral = never built in the warehouse;
-- dbt inlines this as a CTE inside every model that refs() it.
-- See target/compiled/.../fct_orders.sql after `dbt compile`.
select
    order_id,
    customer_id,
    order_date,
    status,
    quantity,
    unit_price,
    quantity * unit_price as gross_revenue,
    case
        when status in ('cancelled', 'returned') then 0
        else quantity * unit_price
    end as net_revenue
from {{ ref('stg_orders') }}