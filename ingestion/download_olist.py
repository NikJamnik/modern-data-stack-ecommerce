"""
Download Olist Brazilian E-Commerce dataset from Kaggle.

This script is the entry point for raw data ingestion. It is idempotent:
re-running it when files are already present is a no-op.

Usage:
    python ingestion/download_olist.py

Required environment variables:
    KAGGLE_USERNAME — Kaggle account username
    KAGGLE_KEY      — Kaggle API key

These are loaded from .env locally and from GitHub Secrets in CI.
"""

import logging
import os
import sys
from pathlib import Path

from dotenv import load_dotenv

# ----------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------

DATASET_SLUG = "olistbr/brazilian-ecommerce"
TARGET_DIR = Path("data/raw/olist")

# Files we expect after a successful download.
# This is our contract with the dataset — if any are missing,
# something went wrong and downstream code will break.
EXPECTED_FILES = [
    "olist_orders_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_customers_dataset.csv",
    "olist_products_dataset.csv",
    "olist_order_payments_dataset.csv",
    "product_category_name_translation.csv",
]

# ----------------------------------------------------------------------
# Logging setup
# ----------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)


# ----------------------------------------------------------------------
# Core functions
# ----------------------------------------------------------------------

def already_downloaded() -> bool:
    """
    Idempotency check: are all expected files already in the target dir?
    Returns True if nothing needs to be done.
    """
    return all((TARGET_DIR / f).exists() for f in EXPECTED_FILES)


def download_dataset() -> None:
    """Authenticate with Kaggle and download the dataset."""
    log.info("Authenticating with Kaggle API...")
    
    # Import inside function: kaggle.api auto-authenticates on import,
    # so we want env vars loaded BEFORE that happens.
    from kaggle.api.kaggle_api_extended import KaggleApi
    
    api = KaggleApi()
    api.authenticate()
    
    log.info("Downloading dataset '%s' to %s ...", DATASET_SLUG, TARGET_DIR)
    TARGET_DIR.mkdir(parents=True, exist_ok=True)
    
    api.dataset_download_files(
        DATASET_SLUG,
        path=str(TARGET_DIR),
        unzip=True,
        quiet=False,
    )
    
    log.info("Download completed.")


def validate_download() -> None:
    """
    Verify that all expected files are present after download.
    Raises RuntimeError if anything is missing — fail loudly, not silently.
    """
    missing = [f for f in EXPECTED_FILES if not (TARGET_DIR / f).exists()]
    
    if missing:
        raise RuntimeError(
            f"Download incomplete — {len(missing)} files missing: {missing}"
        )

    log.info("Validated %d files.", len(EXPECTED_FILES))


# ----------------------------------------------------------------------
# Entry point
# ----------------------------------------------------------------------

def main() -> int:
    """Returns exit code: 0 = success, 1 = error."""
    load_dotenv()
    
    # Verify credentials are present before contacting Kaggle.
    # Better to fail with a clear message than a cryptic API error.
    if not os.environ.get("KAGGLE_USERNAME") or not os.environ.get("KAGGLE_KEY"):
        log.error(
            "Missing Kaggle credentials. "
            "Set KAGGLE_USERNAME and KAGGLE_KEY in .env (local) or "
            "GitHub Secrets (CI). See .env.example for reference."
        )
        return 1
    
    try:
        if already_downloaded():
            log.info("All expected files already present — nothing to do.")
            return 0
        
        download_dataset()
        validate_download()
        log.info("✓ Olist dataset is ready in %s", TARGET_DIR)
        return 0
    
    except Exception as exc:
        log.exception("Failed to download Olist dataset: %s", exc)
        return 1


if __name__ == "__main__":
    sys.exit(main())
