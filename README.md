# Modern Data Stack for E-commerce

End-to-end Modern Data Stack portfolio project: dbt + DuckDB + Evidence + Dagster.

## Status

🚧 Work in progress.

## Stack

- **Warehouse:** DuckDB
- **Transformation:** dbt-core
- **BI:** Evidence.dev
- **Orchestration:** Dagster
- **Observability:** Elementary

## Setup

See [SETUP.md](SETUP.md) (coming soon).

### Materialization strategy

| Layer | Default | Rationale |
|-------|---------|-----------|
| staging | view | Always-fresh, lightweight cleanup of source data |
| intermediate | ephemeral | CTE-only building blocks, no warehouse footprint |
| marts (dimensions) | table | Periodic full refresh, change tracking via SCD2 where needed |
| marts (facts) | incremental | Append-only events, scaled growth — only new rows processed |
