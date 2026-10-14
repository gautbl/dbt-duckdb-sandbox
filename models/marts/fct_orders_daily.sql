{{ config(materialized='incremental', unique_key='order_date', incremental_strategy='merge') }}

-- Layer 3: marts. Daily rollup, incremental: full build on the first run,
-- afterwards only order_dates newer than what {{ this }} already holds.
-- Run `dbt build --select fct_orders_daily` twice to see both paths execute.
select
    order_date,
    count(*)               as orders,
    sum(quantity)           as units_sold,
    sum(gross_revenue)      as gross_revenue,
    sum(net_revenue)        as net_revenue
from {{ ref('fct_orders') }}
{% if is_incremental() %}
where order_date > (select coalesce(max(order_date), date '1900-01-01') from {{ this }})
{% endif %}
group by order_date