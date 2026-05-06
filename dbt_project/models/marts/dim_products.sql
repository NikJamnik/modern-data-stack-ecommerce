-- One row per product (product_id).
-- Combines product identity and computed metrics.
-- Adds computed product segmentation for analytics.

with order_items as (
    select * from {{ ref('int_order_items__enriched') }}
),

orders_with_payments as (
    select * from {{ ref('int_orders__with_payments') }}
),

final as (
    select
        -- Identity
        oi.product_id,
        max(oi.product_category_name) as product_category_name,
        max(oi.product_category_name_english) as product_category_name_english,
        max(oi.product_weight_g) as product_weight_g,

        -- Computed metrics
        count(distinct (oi.order_id, oi.order_item_id)) as times_ordered,
        count(distinct owp.customer_unique_id) as unique_buyers,
        sum(oi.price) as total_revenue,
        avg(oi.price) as avg_price,
        min(owp.order_purchase_timestamp) as first_sold_date,
        max(owp.order_purchase_timestamp) as last_sold_date,

        -- Computed segmentation
        case
            when count(distinct (oi.order_id, oi.order_item_id)) >= 50 then 'Top Seller'
            when count(distinct (oi.order_id, oi.order_item_id)) >= 5 then 'Regular'
            when count(distinct (oi.order_id, oi.order_item_id)) >= 1 then 'Slow Mover'
        end as product_status

    from order_items oi
    left join orders_with_payments owp using (order_id)
    group by oi.product_id
)

select * from final
