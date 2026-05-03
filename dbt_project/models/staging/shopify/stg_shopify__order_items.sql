-- One row per order line item.
-- Composite primary key: (order_id, order_item_id).
-- Source: Shopify (raw.shopify__order_items).
-- Type-cast: timestamp via try_cast, money via cast to decimal(18,2).

with source as (
    select * from {{ source('shopify', 'shopify__order_items') }}
),

staged as (
    select
        -- Composite key fields
        order_id,
        order_item_id,
        
        -- FKs to other entities
        product_id,
        seller_id,
        
        -- Timestamp
        try_cast(shipping_limit_date as timestamp) as shipping_limit_date,
        cast(price as decimal(18, 2)) as price,
        cast(freight_value as decimal(18, 2)) as freight_value
    
    from source
)

select * from staged
