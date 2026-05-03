-- One row per customer-order session (NOT per real person).
-- Source: Shopify (raw.shopify__customers).
-- Note: customer_id is unique per session, customer_unique_id identifies the real person.

with source as (
    select * from {{ source('shopify', 'shopify__customers') }}
),

staged as (
    select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    from source
)

select * from staged
