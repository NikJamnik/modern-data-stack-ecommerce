---
title: Product Performance
---

Product-level metrics aggregated from order items. Categories shown in English
(translated from the original Portuguese category names in the source data).

```sql top_categories
select
    product_category_name_english as category,
    count(distinct product_id)    as products,
    sum(times_ordered)            as units_sold,
    sum(total_revenue)            as revenue,
    round(avg(avg_price), 2)      as avg_price
from warehouse.dim_products
where product_category_name_english is not null
group by 1
order by revenue desc
limit 15
```

<DataTable data={top_categories} rows=all>
    <Column id=category title="Category" />
    <Column id=products title="Products" fmt='#,##0' />
    <Column id=units_sold title="Units Sold" fmt='#,##0' />
    <Column id=revenue title="Revenue (BRL)" fmt='$#,##0' />
    <Column id=avg_price title="Avg Price (BRL)" fmt='$#,##0' />
</DataTable>

## Key Finding

The catalog has a **long tail**: the majority of products sell rarely, while a
small number of categories drive most of the revenue. This concentration is
typical of marketplaces and points to clear priorities for inventory and
merchandising focus.
