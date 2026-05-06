{{ config(
    materialized='incremental',
    unique_key='order_id',
    on_schema_change='fail'
) }}

-- Order-level fact table.
-- Grain: one row per order_id.
--
-- Materialization: incremental with late-arriving fact strategy.
-- On full-refresh: rebuilds entire table.
-- On normal run: re-processes last 7 days of orders to catch late updates
--                (status changes, late-arriving payment data, etc.)
--
-- Denormalizes selected customer attributes for self-service BI:
-- analysts can group revenue by state/segment without joining dim_customers.

with orders as (
    select * from {{ ref('int_orders__with_payments') }}
    
    {% if is_incremental() %}
        where order_purchase_timestamp >= (
            select max(order_purchase_timestamp) - interval '7 days' from {{ this }}
        )
    {% endif %}
),

order_items as (
    select 
        order_id,
        price,
        freight_value
    from {{ ref('int_order_items__enriched') }}
),

-- Aggregate order_items to order-level measures
order_items_summary as (
    select
        order_id,
        sum(price + freight_value) as order_gmv,
        sum(freight_value) as freight_value,
        count(*) as items_in_order
    from order_items
    group by order_id
),

-- Customer attributes for denormalization
customers as (
    select
        customer_unique_id,
        customer_state,
        customer_city,
        customer_segment
    from {{ ref('dim_customers') }}
),

-- Final assembly
final as (
    select
        -- Primary key
        o.order_id,
        
        -- Foreign key
        o.customer_unique_id,
        
        -- Measures from order_items aggregation
        coalesce(ois.order_gmv, 0) as order_gmv,
        coalesce(ois.freight_value, 0) as freight_value,
        coalesce(ois.items_in_order, 0) as items_in_order,
        
        -- Measures from int_orders__with_payments
        o.total_payment_amount as total_paid,
        o.total_installments as installments,
        o.payment_methods_count,
        
        -- Degenerate dimensions (event attributes, no separate dim)
        o.order_status,
        o.has_payment,
        
        -- Event timestamps
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        
        c.customer_state,
        c.customer_city,
        c.customer_segment
    
    from orders o
    left join order_items_summary ois using (order_id)
    left join customers c using (customer_unique_id)
)

select * from final
