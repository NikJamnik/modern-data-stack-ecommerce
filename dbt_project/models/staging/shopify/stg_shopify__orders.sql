-- One row per order. Source: Shopify (raw.shopify__orders).
-- Staging-level cleanup: type casting only, no business logic.

with source as (
    select * from {{ source('shopify', 'shopify__orders') }}
),

staged as (
    select
        -- IDs (kept as VARCHAR — they're identifiers, not numbers)
        order_id,
        customer_id,
        
        -- Status enum (validated by accepted_values test)
        order_status,
        
        -- Timestamp parsing: try_cast returns NULL on failure
        -- Source format from CSV: 'YYYY-MM-DD HH:MM:SS'
        try_cast(order_purchase_timestamp as timestamp) as order_purchase_timestamp,
        try_cast(order_approved_at as timestamp) as order_approved_at,
        try_cast(order_delivered_carrier_date as timestamp) as order_delivered_carrier_date,
        try_cast(order_delivered_customer_date as timestamp) as order_delivered_customer_date,
        try_cast(order_estimated_delivery_date as timestamp) as order_estimated_delivery_date
    
    from source
)

select * from staged
