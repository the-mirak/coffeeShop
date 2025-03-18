import os
import json
import uuid
import shutil
from typing import Dict, List, Any, Optional
import logging
from datetime import datetime, timedelta
from urllib.parse import urljoin
import urllib.parse

logger = logging.getLogger(__name__)

# Ensure local data directories exist
def ensure_dirs():
    """Ensure the local data directories exist."""
    os.makedirs("local_data/images", exist_ok=True)
    os.makedirs("local_data/db", exist_ok=True)


class LocalS3Client:
    """Local implementation of S3 client for development."""
    
    def __init__(self, bucket_name: str):
        self.bucket_name = bucket_name
        self.base_dir = os.path.join("local_data", "images")
        ensure_dirs()
        
    def upload_file(self, file_path: str, bucket: str, key: str):
        """Copy file to local storage directory."""
        destination = os.path.join(self.base_dir, key)
        shutil.copy2(file_path, destination)
        logger.info(f"Uploaded file to local storage: {destination}")
        return True
        
    def generate_presigned_url(self, operation_name: str, Params: Dict[str, Any] = None, ExpiresIn: int = 3600, **kwargs):
        """Generate a local URL for accessing files.
        
        Note: Parameter names match boto3's generate_presigned_url method:
        - operation_name: The name of the operation to call
        - Params: The parameters to use for the operation (bucket name, object key)
        - ExpiresIn: Time in seconds for the URL to remain valid
        """
        if operation_name != 'get_object':
            raise ValueError(f"Unsupported operation: {operation_name}")
            
        params = Params or {}
        key = params.get('Key')
        if not key:
            raise ValueError("Key is required")
            
        # For local development, just return a direct file URL
        # In production, this would be a presigned S3 URL
        return f"/local_data/images/{urllib.parse.quote(key)}"


class LocalDynamoDBTable:
    """Local implementation of DynamoDB table for development."""
    
    def __init__(self, table_name: str):
        self.table_name = table_name
        self.db_file = os.path.join("local_data", "db", f"{table_name}.json")
        ensure_dirs()
        
        # Initialize the database file if it doesn't exist
        if not os.path.exists(self.db_file):
            with open(self.db_file, 'w') as f:
                json.dump([], f)
                
    def _read_db(self) -> List[Dict[str, Any]]:
        """Read all items from the local JSON database."""
        try:
            with open(self.db_file, 'r') as f:
                return json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            return []
            
    def _write_db(self, items: List[Dict[str, Any]]):
        """Write all items to the local JSON database."""
        with open(self.db_file, 'w') as f:
            json.dump(items, f, default=str, indent=2)
            
    def scan(self) -> Dict[str, Any]:
        """Scan all items from the local database."""
        items = self._read_db()
        return {"Items": items, "Count": len(items)}
        
    def get_item(self, Key: Dict[str, Any]) -> Dict[str, Any]:
        """Get a specific item by key."""
        items = self._read_db()
        
        # Find the matching item
        for item in items:
            match = True
            for key, value in Key.items():
                if key not in item or item[key] != value:
                    match = False
                    break
            if match:
                return {"Item": item}
                
        return {}
        
    def put_item(self, Item: Dict[str, Any]):
        """Add a new item to the database."""
        items = self._read_db()
        
        # Check if item with same key exists and replace it
        key_name = next(iter(Item.keys()))  # Assuming first attribute is the key
        key_value = Item[key_name]
        
        for i, item in enumerate(items):
            if key_name in item and item[key_name] == key_value:
                items[i] = Item
                self._write_db(items)
                return
                
        # Item doesn't exist, append it
        items.append(Item)
        self._write_db(items)
        
    def update_item(self, Key: Dict[str, Any], UpdateExpression: str, 
                    ExpressionAttributeValues: Dict[str, Any],
                    ExpressionAttributeNames: Optional[Dict[str, str]] = None):
        """Update an existing item."""
        items = self._read_db()
        
        # Parse the update expression (simplified implementation)
        if not UpdateExpression.startswith("SET "):
            raise ValueError(f"Unsupported UpdateExpression: {UpdateExpression}")
            
        # Extract set operations
        set_ops = UpdateExpression[4:].split(", ")
        
        # Find the item to update
        for i, item in enumerate(items):
            match = True
            for key, value in Key.items():
                if key not in item or item[key] != value:
                    match = False
                    break
                    
            if match:
                # Apply the update operations
                for op in set_ops:
                    field, value_ref = [x.strip() for x in op.split("=")]
                    
                    # Replace attribute names if needed
                    if ExpressionAttributeNames and field.startswith("#"):
                        field = ExpressionAttributeNames.get(field, field)
                        
                    # Get the actual value from ExpressionAttributeValues
                    if value_ref.startswith(":"):
                        value = ExpressionAttributeValues.get(value_ref)
                        if field in item:
                            item[field] = value
                        else:
                            item[field] = value
                
                # Write the updated items back to the database
                self._write_db(items)
                return
                
        raise ValueError(f"Item with key {Key} not found")
        
    def delete_item(self, Key: Dict[str, Any]):
        """Delete an item from the database."""
        items = self._read_db()
        
        for i, item in enumerate(items):
            match = True
            for key, value in Key.items():
                if key not in item or item[key] != value:
                    match = False
                    break
                    
            if match:
                del items[i]
                self._write_db(items)
                return
                
        # Item not found - in DynamoDB this is not an error
        return


# Helper function to create appropriate clients based on LOCAL_MODE
def get_storage_clients(local_mode: bool, s3_bucket_name: str, dynamodb_table_name: str, aws_region: str):
    """Return either local or AWS clients based on the local_mode flag."""
    if local_mode:
        # Create local implementations
        s3 = LocalS3Client(s3_bucket_name)
        dynamodb_resource = type('obj', (object,), {
            'Table': lambda table_name: LocalDynamoDBTable(table_name)
        })
        table = LocalDynamoDBTable(dynamodb_table_name)
        
        return s3, dynamodb_resource, table
    else:
        # Create actual AWS clients
        import boto3
        s3 = boto3.client('s3', region_name=aws_region)
        dynamodb_resource = boto3.resource('dynamodb', region_name=aws_region)
        table = dynamodb_resource.Table(dynamodb_table_name)
        
        return s3, dynamodb_resource, table 