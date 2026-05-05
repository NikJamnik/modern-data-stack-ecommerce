-- Customer-level view of unique people, not session-level rows.
-- Grain: one row per customer_unique_id (real person).
--
-- Combines:
--   - stg_shopify__customers (for identity and address)
--   - int_orders__with_payments (for order-level aggregates)
--
-- Address fields use arg_max() to pick value from customer's most recent order
-- (i.e., where the person currently lives, not where they were when they first ordered).

with customers_sessions as (
    select * from {{ ref('stg_shopify__customers') }}
),

orders as (
    select * from {{ ref('int_orders__with_payments') }}
),

-- Join sessions with orders to get order timestamps per session.
-- This lets us pick "latest" address by order date.
sessions_with_orders as (
    select
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp
    from customers_sessions c
    left join orders o using (customer_id)
),

-- Aggregate to one row per real customer.
identity_resolved as (
    select
        customer_unique_id,
        
        -- Address fields: take values from most recent order
        arg_max(customer_zip_code_prefix, order_purchase_timestamp) as customer_zip_code_prefix,
        arg_max(customer_city, order_purchase_timestamp) as customer_city,
        arg_max(customer_state, order_purchase_timestamp) as customer_state,
        
        -- Order timing metrics
        min(order_purchase_timestamp) as first_order_date,
        max(order_purchase_timestamp) as last_order_date,
        
        -- Order count metrics
        count(distinct order_id) as total_orders,
        count(distinct order_id) filter (where order_status = 'delivered') as delivered_orders,
        count(distinct order_id) filter (where order_status = 'shipped') as shipped_orders,
        count(distinct order_id) filter (where order_status = 'canceled') as canceled_orders
    
    from sessions_with_orders
    group by customer_unique_id
)

select * from identity_resolved
