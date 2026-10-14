-- Singular test: any order carrying a negative net revenue is a violation.
-- A test query returns the rows that VIOLATE the assertion; zero rows = pass.
select
    order_id,
    net_revenue
from {{ ref('fct_orders') }}
where net_revenue < 0