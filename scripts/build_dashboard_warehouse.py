"""
Build a lightweight DuckDB file containing only the mart tables,
for bundling with the Evidence dashboard on deploy.

Attaches the full warehouse and copies the three marts into a fresh file
at dashboard/sources/duckdb/warehouse.duckdb (committed to git for Vercel).
"""
import duckdb
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
FULL = ROOT / "data" / "warehouse.duckdb"
LITE = ROOT / "dashboard" / "sources" / "duckdb" / "warehouse.duckdb"

MARTS = ["dim_customers", "dim_products", "fct_orders"]

# Start clean so the file only ever contains current marts
if LITE.exists():
    LITE.unlink()

# Connect to the destination (lightweight) file, attach the full warehouse read-only
con = duckdb.connect(str(LITE))
con.execute(f"attach '{FULL}' as full_wh (read_only)")
con.execute("create schema if not exists main_marts")

for table in MARTS:
    print(f"Copying main_marts.{table} ...")
    con.execute(
        f"create table main_marts.{table} as "
        f"select * from full_wh.main_marts.{table}"
    )
    n = con.sql(f"select count(*) from main_marts.{table}").fetchone()[0]
    print(f"  -> {n:,} rows")

con.execute("detach full_wh")
con.close()

size_mb = LITE.stat().st_size / 1024 / 1024
print(f"\nLightweight warehouse written: {LITE}")
print(f"Size: {size_mb:.1f} MB")
