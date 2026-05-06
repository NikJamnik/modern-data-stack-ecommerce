-- One row per real customer (customer_unique_id).
-- Combines identity, order metrics, and revenue.
-- Adds business segmentation (RFM-style) for analytics.
--
-- "As-of date" pattern: recency calculated relative to the latest order in data,
-- not current_date(). This makes the dashboard deterministic and reproducible
-- regardless of when it's queried.

with customers as (
    select * from {{ ref('int_customers__identity_resolved') }}
),

orders as (
    select 
        order_id,
        customer_unique_id
    from {{ ref('int_orders__with_payments') }}
),

order_items as (
    select 
        order_id,
        price,
        freight_value
    from {{ ref('int_order_items__enriched') }}
),

-- Revenue per customer: sum item price + freight across all their orders
customer_revenue as (
    select
        o.customer_unique_id,
        sum(price + freight_value) as total_gmv
    from orders o
    inner join order_items oi using (order_id)
    group by o.customer_unique_id
),

-- "As-of date" for analysis: latest order in data + 1 day.
-- This makes the analysis deterministic regardless of when it runs.
analysis_as_of as (
    select max(last_order_date) + interval 1 day as as_of_date
    from customers
),

-- Final: combine all sources and add segmentation
final as (
    select
        -- Identity
        c.customer_unique_id,
        c.customer_state,
        c.customer_city,
        c.customer_zip_code_prefix,
        
        -- Order timing
        c.first_order_date,
        c.last_order_date,
        date_diff('day', c.last_order_date, a.as_of_date) as days_since_last_order,
        
        -- Order count metrics
        c.total_orders,
        c.delivered_orders,
        c.shipped_orders,
        c.canceled_orders,
        
        -- Revenue
        coalesce(r.total_gmv, 0) as total_gmv,
        case
            when c.total_orders > 0 then coalesce(r.total_gmv, 0) / c.total_orders
            else 0
        end as avg_order_value,
        
        case
            when c.total_orders >= 2 and date_diff('day', c.last_order_date, a.as_of_date) <= 30 then 'Champion'
            when c.total_orders = 1 and date_diff('day', c.last_order_date, a.as_of_date) <= 30 then 'New Customer'
            when c.total_orders >= 2 and date_diff('day', c.last_order_date, a.as_of_date) > 30 then 'At Risk'
            when c.total_orders = 1 and date_diff('day', c.last_order_date, a.as_of_date) > 30 then 'One-Time'
            else 'Unknown'
        end as customer_segment,
        
        -- Reference: as-of date used for this calculation (helpful for debugging)
        a.as_of_date as analysis_as_of_date
    
    from customers c
    cross join analysis_as_of a
    left join customer_revenue r using (customer_unique_id)
)

select * from final
