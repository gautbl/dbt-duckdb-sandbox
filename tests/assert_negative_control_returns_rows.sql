-- Negative control for the build gate. This test MUST fail.
--
-- It proves that the gate can turn red, not only green. A singular test
-- returns the rows that VIOLATE its assertion, so zero rows is a pass.
-- This query returns rows on purpose, by inverting the predicate that
-- tests/assert_fct_orders_net_revenue_nonnegative.sql uses.
--
-- Scratch branch only. Delete this file with the branch. Never merge it.

select
    order_id,
    net_revenue
from {{ ref('fct_orders') }}
where net_revenue >= 0
