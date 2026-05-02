"""
Load raw Olist CSVs into DuckDB warehouse.

Strategy:
- Read all columns as VARCHAR (preserve source data verbatim).
- Write to schema `raw` with `shopify__<entity>` table names.
- Idempotent: CREATE OR REPLACE on each run.

Usage:
    python ingestion/load_to_duckdb.py
"""

import logging
import sys

import duckdb

from config import OLIST_DIR, OLIST_TABLES, RAW_SCHEMA, WAREHOUSE_PATH

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)


def load_csv_as_varchar(con: duckdb.DuckDBPyConnection, csv_path, table_name: str) -> int:
    """
    Load a single CSV into the raw schema with all columns as VARCHAR.
    Returns the number of rows loaded.
    """
    full_table = f"{RAW_SCHEMA}.{table_name}"
    
    # all_varchar=true forces every column to VARCHAR.
    # CREATE OR REPLACE = idempotent (safe to re-run).
    con.execute(f"""
        CREATE OR REPLACE TABLE {full_table} AS
        SELECT * FROM read_csv(
            '{csv_path}',
            all_varchar=true,
            header=true
        )
    """)
    
    row_count = con.execute(f"SELECT count(*) FROM {full_table};").fetchone()[0]
    
    return row_count


def main() -> int:
    if not OLIST_DIR.exists():
        log.error("Olist directory not found at %s. Run download_olist.py first.", OLIST_DIR)
        return 1
    
    log.info("Connecting to DuckDB at %s", WAREHOUSE_PATH)
    
    con = duckdb.connect(str(WAREHOUSE_PATH))
    con.execute(f"CREATE SCHEMA IF NOT EXISTS {RAW_SCHEMA};")
    
    # ... after this point, normal load loop:
    total_rows = 0
    for csv_filename, table_name in OLIST_TABLES.items():
        csv_path = OLIST_DIR / csv_filename
        
        if not csv_path.exists():
            log.warning("Skipping missing file: %s", csv_path)
            continue
        
        log.info("Loading %s → %s.%s", csv_filename, RAW_SCHEMA, table_name)
        rows = load_csv_as_varchar(con, csv_path, table_name)
        log.info("  loaded %s rows", f"{rows:,}")
        total_rows += rows
    
    con.close()
    log.info("✓ Loaded %s rows total into schema '%s'", f"{total_rows:,}", RAW_SCHEMA)
    return 0


if __name__ == "__main__":
    sys.exit(main())
