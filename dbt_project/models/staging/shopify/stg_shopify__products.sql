-- One row per product.
-- Primary key: product_id.
-- Source: Shopify (raw.shopify__products).
-- Type-cast: all numerical columns via try_cast to int.

with source as (
    select * from {{ source('shopify', 'shopify__products') }}
),

staged as (
    select
        product_id,
        product_category_name,
        
        try_cast(product_name_lenght as int) as product_name_length,
        try_cast(product_description_lenght as int) as product_description_length,
        try_cast(product_photos_qty as int) as product_photos_qty,
        try_cast(product_weight_g as int) as product_weight_g,
        try_cast(product_length_cm as int) as product_length_cm,
        try_cast(product_height_cm as int) as product_height_cm,
        try_cast(product_width_cm as int) as product_width_cm
    from source
)

select * from staged
