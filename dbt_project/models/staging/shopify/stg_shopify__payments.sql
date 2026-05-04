-- One row per sequential payment for an order.
-- Composite primary key: (order_id, payment_sequential).
-- Source: Shopify (raw.shopify__payments).
-- Type-cast: payment_value via try_cast to decimal(18, 2).

with source as (
    select * from {{ source('shopify', 'shopify__payments') }}
),

staged as (
    select
        order_id,

        try_cast(payment_sequential as int) as payment_sequential,
        payment_type,
        try_cast(payment_installments as int) as payment_installments,
        try_cast(payment_value as decimal(18, 2)) as payment_value

    from source
)

select * from staged
