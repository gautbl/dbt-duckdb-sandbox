{{ config(materialized='view') }}

-- Layer 1: staging. One row per customer, straight from the seed,
-- renamed and typed. A view: no data copied, easy to rebuild.
select
    cast(customer_id as integer)   as customer_id,
    trim(customer_name)            as customer_name,
    upper(trim(country))           as country,
    lower(trim(segment))           as segment
from {{ source('raw', 'customers') }}