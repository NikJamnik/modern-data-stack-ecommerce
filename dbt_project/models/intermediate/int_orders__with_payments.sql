-- Order header enriched with aggregated payment information.
-- Grain: one row per order_id (same as stg_shopify__orders).
--
-- Logic:
--   1. Aggregate payments per order (one order can have multiple installments)
--   2. Left join onto orders (some orders may have no payments — canceled before payment)

with orders as (
    select * from {{ ref('stg_shopify__orders') }}
),

payments as (
    select * from {{ ref('stg_shopify__payments') }}
),

-- Aggregate payments to order grain
payment_summary as (
    select
        order_id,
        sum(payment_value) as total_payment_amount,
        sum(payment_installments) as total_installments,
        count(distinct payment_type) as payment_methods_count,
        count(*) as payment_records_count
    from payments
    group by order_id
),

-- Enrich orders with aggregated payment data
enriched as (
    select
        o.*,

        -- Aggregated payment fields
        coalesce(p.total_payment_amount, 0) as total_payment_amount,
        coalesce(p.total_installments, 0) as total_installments,
        coalesce(p.payment_methods_count, 0) as payment_methods_count,
        coalesce(p.payment_records_count, 0) as payment_records_count,
        
        case
            when p.total_payment_amount IS NULL then FALSE
            else TRUE
        end as has_payment
    
    from orders o
    left join payment_summary p using (order_id)
)

select * from enriched
