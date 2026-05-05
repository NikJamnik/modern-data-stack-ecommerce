-- Order items enriched with product and categories data.
-- Grain: one row per order item (order_id, order_item_id).
--
-- Logic:
--   1. From order items
--   2. Left join onto products
--      - Chosen columns: photos quantity and physical parameters of the products for delivery analytics
--   3. Left join onto product categories

with order_items as (
    select * from {{ ref('stg_shopify__order_items') }}
),

products as (
    select
        product_id,
        product_category_name,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    from {{ ref('stg_shopify__products') }}
),

product_categories as (
    select *
    from {{ ref('stg_shopify__product_categories') }}
),

order_items_product_enriched as (
    select
        oi.*,
        p.product_category_name,
        p.product_photos_qty,
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm
    from order_items oi
    left join products p using(product_id)
),

order_items_enriched as (
    select 
        oipe.*,
        pc.product_category_name_english
    from order_items_product_enriched oipe
    left join product_categories pc using(product_category_name)
)

select * from order_items_enriched
