-- One row per product category.
-- Primary key: (product_category_name).
-- Source: Shopify (raw.shopify__product_categories).

with source as (
    select * from {{ source('shopify', 'shopify__product_categories') }}
),

staged as (
    select 
        product_category_name,
        product_category_name_english
    from source
)

select * from staged