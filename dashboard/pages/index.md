---
title: Brazilian E-Commerce Analytics
---

Analysis of an online marketplace with **~96K orders** placed between 2016 and 2018.
Data modeled with dbt into a star schema (staging → intermediate → marts) and
visualized here with Evidence. All figures are deterministic, calculated relative
to a fixed "as-of date" (latest order in the dataset).

## Key Metrics

```sql kpis
select
    sum(order_gmv)                     as total_gmv,
    count(distinct order_id)           as total_orders,
    count(distinct customer_unique_id) as unique_customers,
    sum(order_gmv) / count(distinct order_id) as avg_order_value
from warehouse.fct_orders
```

<BigValue data={kpis} value=total_gmv fmt='$#,##0' title="Total GMV (BRL)" />
<BigValue data={kpis} value=total_orders fmt='#,##0' title="Total Orders" />
<BigValue data={kpis} value=unique_customers fmt='#,##0' title="Unique Customers" />
<BigValue data={kpis} value=avg_order_value fmt='$#,##0' title="Avg Order Value (BRL)" />

## Revenue Trend

```sql revenue_monthly
select
    date_trunc('month', order_purchase_timestamp) as month,
    sum(order_gmv) as gmv
from warehouse.fct_orders
where order_purchase_timestamp is not null
group by 1
order by 1
```

<LineChart data={revenue_monthly} x=month y=gmv title="Monthly GMV (BRL)" />

## Customers by Segment

```sql segments
select
    customer_segment,
    count(*) as customers
from warehouse.dim_customers
group by 1
order by customers desc
```

<BarChart data={segments} x=customer_segment y=customers title="Customers per Segment" />

## Explore Further
- [Customer Segmentation (RFM)](/rfm)
- [Product Performance](/products)
