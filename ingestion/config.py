"""
Shared configuration for ingestion scripts.

Single source of truth for paths, schemas, and dataset structure.
Update this file when project layout changes — never hardcode paths in scripts.
"""

from pathlib import Path

# ----------------------------------------------------------------------
# Project root and data paths
# ----------------------------------------------------------------------

# Project root = parent of `ingestion/` directory (two levels up from this file)
PROJECT_ROOT = Path(__file__).resolve().parent.parent

DATA_DIR = PROJECT_ROOT / "data"
RAW_DIR = DATA_DIR / "raw"
OLIST_DIR = RAW_DIR / "olist"

# DuckDB warehouse — single file at data/warehouse.duckdb
WAREHOUSE_PATH = DATA_DIR / "warehouse.duckdb"

# ----------------------------------------------------------------------
# Schemas
# ----------------------------------------------------------------------

RAW_SCHEMA = "raw"

# ----------------------------------------------------------------------
# Olist dataset → table mapping
# ----------------------------------------------------------------------

# Maps source CSV filenames to target table names in `raw` schema.
# Naming convention: <source_system>__<entity>
# This mirrors what dbt sources will reference later.
OLIST_TABLES = {
    "olist_orders_dataset.csv": "shopify__orders",
    "olist_order_items_dataset.csv": "shopify__order_items",
    "olist_customers_dataset.csv": "shopify__customers",
    "olist_products_dataset.csv": "shopify__products",
    "olist_order_payments_dataset.csv": "shopify__payments",
    "product_category_name_translation.csv": "shopify__product_categories",
}
