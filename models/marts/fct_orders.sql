{{ config(materialized='table') }}

-- Layer 3: marts. One row per order — the fact table for the lesson's
-- `dbt ls --select +fct_orders` / `dbt build --select +fct_orders` exercises.
-- Left join on purpose: an order with an unknown customer must stay visible
-- so the relationships test in models/marts/schema.yml can catch it.
/* select
    o.order_id,
    o.customer_id,
    c.customer_name,
    c.country,
    o.order_date,
    o.status,
    o.quantity,
    o.unit_price,
    o.gross_revenue,
    o.net_revenue
from {{ ref('int_order_totals') }} o
left join {{ ref('stg_customers') }} c
    on o.customer_id = c.customer_id */

-- Lesson 0005
-- Fact table now joins to dim_customers instead of stg_customers.
-- The output columns are identical — but the DAG edge now points
-- to the gold dimension, which is a table (faster for repeated queries).
/* select
    o.order_id,
    o.customer_id,
    c.customer_name,
    c.country,
    o.order_date,
    o.status,
    o.quantity,
    o.unit_price,
    o.gross_revenue,
    o.net_revenue
from {{ ref('int_order_totals') }} o
left join {{ ref('dim_customers') }} c
    on o.customer_id = c.customer_id */

-- Lesson 0006
-- fct_orders: one row per order.
-- Measures: quantity, unit_price, gross_revenue, net_revenue.
-- Degenerate dimensions: order_id, status.
-- Foreign keys: customer_id, order_date.
-- Descriptive columns (customer_name, country) belong in dim_customers,
-- accessed by joining at query time.

select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    o.quantity,
    o.unit_price,
    o.gross_revenue,
    o.net_revenue
from {{ ref('int_order_totals') }} o