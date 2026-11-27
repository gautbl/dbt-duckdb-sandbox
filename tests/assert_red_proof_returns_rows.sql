-- Scratch test for ticket 06. It returns rows on purpose, so the gate turns red.
-- Do not merge this file. Delete the branch after the run.
select
    order_id
from {{ ref('fct_orders') }}
where net_revenue >= 0
