{{ config(materialized='view') }}

-- Layer 1: staging. One row per order, straight from the seed,
-- renamed and typed. Tests in models/staging/schema.yml run against this.
select
    cast(order_id as integer)      as order_id,
    cast(customer_id as integer)   as customer_id,
    cast(order_date as date)       as order_date,
    lower(trim(status))            as status,
    cast(quantity as integer)      as quantity,
    cast(unit_price as decimal(10, 2)) as unit_price
from {{ source('raw', 'orders') }}