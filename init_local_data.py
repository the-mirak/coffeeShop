#!/usr/bin/env python3
"""
Initialize local data for testing.
This script creates sample data for local development and testing.
"""

import os
import json
import uuid
import shutil
from decimal import Decimal
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Sample products
SAMPLE_PRODUCTS = [
    {
        "name": "Cappuccino",
        "description": "A classic Italian coffee drink prepared with espresso, hot milk, and steamed-milk foam.",
        "price": 4.99,
        "type": "coffee",
        "image": "cappuccino.jpg"
    },
    {
        "name": "Espresso",
        "description": "A concentrated form of coffee served in small, strong shots.",
        "price": 3.49,
        "type": "coffee",
        "image": "espresso.jpg"
    },
    {
        "name": "Latte",
        "description": "Coffee drink made with espresso and steamed milk.",
        "price": 4.49,
        "type": "coffee",
        "image": "latte.jpg"
    },
    {
        "name": "Chocolate Croissant",
        "description": "Flaky, buttery pastry filled with rich chocolate.",
        "price": 3.99,
        "type": "pastry",
        "image": "chocolate_croissant.jpg"
    },
    {
        "name": "Blueberry Muffin",
        "description": "Moist muffin packed with fresh blueberries.",
        "price": 3.49,
        "type": "pastry",
        "image": "blueberry_muffin.jpg"
    }
]

def ensure_dirs():
    """Ensure local data directories exist."""
    os.makedirs("local_data/images", exist_ok=True)
    os.makedirs("local_data/db", exist_ok=True)
    os.makedirs("sample_images", exist_ok=True)

def copy_sample_images():
    """Copy sample images to local storage."""
    logger.info("Copying sample images to local storage...")
    
    # Check if we have sample images in sample_images directory
    have_samples = False
    for product in SAMPLE_PRODUCTS:
        source = os.path.join("sample_images", product["image"])
        if os.path.exists(source):
            have_samples = True
            destination = os.path.join("local_data", "images", product["image"])
            logger.info(f"Copying {source} to {destination}")
            shutil.copy2(source, destination)
    
    if not have_samples:
        logger.warning("No sample images found in sample_images directory.")
        logger.info("To add sample images, create a 'sample_images' directory and add images with filenames matching the sample data.")

def create_sample_data():
    """Create sample data in local database."""
    logger.info("Creating sample data in local database...")
    
    # Create or truncate the database file
    db_file = os.path.join("local_data", "db", "local-table.json")
    
    # Check if file exists and has data
    if os.path.exists(db_file):
        try:
            with open(db_file, 'r') as f:
                existing_data = json.load(f)
                if existing_data:
                    logger.info("Database already has data. Skipping sample data creation.")
                    return
        except (json.JSONDecodeError, FileNotFoundError):
            pass
    
    # Create sample products
    products = []
    for product in SAMPLE_PRODUCTS:
        product_id = str(uuid.uuid4())
        item = {
            "product_id": product_id,
            "name": product["name"],
            "description": product["description"],
            "price": str(product["price"]),  # Stored as string for JSON
            "image_url": product["image"],
            "type": product["type"]
        }
        products.append(item)
    
    # Write to database file
    with open(db_file, 'w') as f:
        json.dump(products, f, indent=2)
    
    logger.info(f"Created {len(products)} sample products in local database.")

def main():
    """Main function to initialize local data."""
    logger.info("Initializing local data for testing...")
    ensure_dirs()
    copy_sample_images()
    create_sample_data()
    logger.info("Local data initialization complete.")

if __name__ == "__main__":
    main() 