---
title: Customer Segmentation (RFM)
---

Customers are segmented using a simplified RFM approach based on **recency**
(days since last order) and **frequency** (total orders), calculated relative
to a fixed as-of date. This surfaces the platform's core retention picture.

```sql segment_summary
select
    customer_segment,
    count(*)                                   as customers,
    round(100.0 * count(*) / sum(count(*)) over (), 1) as pct_customers,
    sum(total_gmv)                             as segment_gmv,
    round(100.0 * sum(total_gmv) / sum(sum(total_gmv)) over (), 1) as pct_gmv,
    round(avg(avg_order_value), 2)             as avg_order_value
from warehouse.dim_customers
group by 1
order by customers desc
```

<DataTable data={segment_summary} rows=all>
    <Column id=customer_segment title="Segment" />
    <Column id=customers title="Customers" fmt='#,##0' />
    <Column id=pct_customers title="% of Customers" fmt='0.0"%"' />
    <Column id=segment_gmv title="GMV (BRL)" fmt='$#,##0' />
    <Column id=pct_gmv title="% of GMV" fmt='0.0"%"' />
    <Column id=avg_order_value title="AOV (BRL)" fmt='$#,##0' />
</DataTable>

## Key Finding

The overwhelming majority of customers are **One-Time** buyers, and they account
for the bulk of total revenue. This is the platform's central business problem:
revenue depends on constant new-customer acquisition rather than repeat purchases.
Notably, average order value is roughly flat across segments — repeat customers
don't spend more per order, they simply (rarely) order again.
