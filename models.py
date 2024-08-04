# models.py
from pydantic import BaseModel

class Product(BaseModel):
    product_id: str
    name: str
    description: str
    price: float
    image_url: str = None
