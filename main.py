from fastapi import FastAPI, Depends, HTTPException, Request, Form, UploadFile, File
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
from typing import List
import os
from dotenv import load_dotenv
import uuid
import logging
from decimal import Decimal
import random

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")

# Mount local data directory for serving local images in development
LOCAL_MODE = os.getenv('LOCAL_MODE', 'false').lower() == 'true'
if LOCAL_MODE:
    os.makedirs("local_data/images", exist_ok=True)
    app.mount("/local_data/images", StaticFiles(directory="local_data/images"), name="local_images")

templates = Jinja2Templates(directory="templates")

S3_BUCKET_NAME = os.getenv('S3_BUCKET_NAME')
DYNAMODB_TABLE_NAME = os.getenv('DYNAMODB_TABLE_NAME')
AWS_REGION = os.getenv('AWS_REGION')

# Initialize storage clients based on environment
if LOCAL_MODE:
    from local_storage import get_storage_clients
    s3_client, dynamodb, table = get_storage_clients(
        local_mode=True,
        s3_bucket_name=S3_BUCKET_NAME,
        dynamodb_table_name=DYNAMODB_TABLE_NAME,
        aws_region=AWS_REGION
    )
    logger.info("🧪 Running in LOCAL MODE with local storage")
else:
    import boto3
    dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
    s3_client = boto3.client('s3', region_name=AWS_REGION)
    table = dynamodb.Table(DYNAMODB_TABLE_NAME)
    logger.info("🌍 Running with AWS endpoints")

class Product(BaseModel):
    product_id: str
    name: str
    description: str
    price: Decimal
    image_url: str = None
    type: str

# Generate presigned URL
def generate_presigned_url(filename):
    return s3_client.generate_presigned_url(
        'get_object',
        Params={'Bucket': S3_BUCKET_NAME, 'Key': filename},
        ExpiresIn=3600
    )

# Home page
@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    response = table.scan()
    products = response.get('Items', [])
    # Select 10 random products for quick order strip
    quick_order_products = random.sample(products, min(len(products), 10)) if products else []
    # Generate presigned URLs for images
    for product in quick_order_products:
        product['image_url'] = generate_presigned_url(product['image_url'])
    return templates.TemplateResponse("index.html", {"request": request, "quick_order_products": quick_order_products})

# Menu page
@app.get("/menu", response_class=HTMLResponse)
async def menu(request: Request):
    response = table.scan()
    products = response.get('Items', [])
    # Generate presigned URLs for images
    for product in products:
        product['image_url'] = generate_presigned_url(product['image_url'])
    return templates.TemplateResponse("menu.html", {"request": request, "products": products})

# About page
@app.get("/about", response_class=HTMLResponse)
async def about(request: Request):
    return templates.TemplateResponse("about.html", {"request": request})

# Contact page
@app.get("/contact", response_class=HTMLResponse)
async def contact(request: Request):
    return templates.TemplateResponse("contact.html", {"request": request})

# Admin dashboard
@app.get("/admin", response_class=HTMLResponse)
async def admin_dashboard(request: Request):
    response = table.scan()
    products = response.get('Items', [])
    # Generate presigned URLs for images
    for product in products:
        product['image_url'] = generate_presigned_url(product['image_url'])
    return templates.TemplateResponse("admin.html", {"request": request, "products": products})

# Admin products page
@app.get("/admin/products", response_class=HTMLResponse)
async def admin_products(request: Request):
    response = table.scan()
    products = response.get('Items', [])
    # Generate presigned URLs for images
    for product in products:
        product['image_url'] = generate_presigned_url(product['image_url'])
    return templates.TemplateResponse("admin_products.html", {"request": request, "products": products})

# Alternate route for admin products (for AWS compatibility)
@app.get("/admin-products", response_class=HTMLResponse)
async def admin_products_alt(request: Request):
    response = table.scan()
    products = response.get('Items', [])
    # Generate presigned URLs for images
    for product in products:
        product['image_url'] = generate_presigned_url(product['image_url'])
    return templates.TemplateResponse("admin_products.html", {"request": request, "products": products})

# Add product page
@app.get("/add", response_class=HTMLResponse)
async def add_product_page(request: Request):
    return templates.TemplateResponse("add_product.html", {"request": request})

# Edit product page
@app.get("/edit/{product_id}", response_class=HTMLResponse)
async def edit_product_page(request: Request, product_id: str):
    try:
        response = table.get_item(Key={'product_id': product_id})
        product = response['Item']
        product['image_url'] = generate_presigned_url(product['image_url'])
    except Exception as e:
        raise HTTPException(status_code=404, detail="Product not found")
    return templates.TemplateResponse("edit_product.html", {"request": request, "product": product})

# Retrieve all products
@app.get("/products", response_model=List[Product])
async def get_products():
    response = table.scan()
    products = response.get('Items', [])
    return products

# Create a new product
@app.post("/products")
async def create_product(request: Request, name: str = Form(...), description: str = Form(...), price: float = Form(...), type: str = Form(...), image: UploadFile = File(...)):
    logger.info("Received request to create product with data: name=%s, description=%s, price=%f, type=%s", name, description, price, type)
    
    try:
        product_id = str(uuid.uuid4())
        filename = f"{name.replace(' ', '_').lower()}"
        file_path = f"/tmp/{filename}"

        with open(file_path, "wb") as f:
            f.write(await image.read())

        s3_client.upload_file(file_path, S3_BUCKET_NAME, filename)
        image_url = filename  # Store the filename in the table

        item = {
            'product_id': product_id,
            'name': name,
            'description': description,
            'price': Decimal(str(price)),  # Ensure price is stored as Decimal
            'image_url': image_url,
            'type': type
        }
        table.put_item(Item=item)

        logger.info("Successfully created product: %s", item)
        return RedirectResponse(url="/admin/products?msg=Product added successfully", status_code=303)

    except Exception as e:
        logger.error("Error creating product: %s", str(e))
        raise HTTPException(status_code=400, detail=f"Error creating product: {str(e)}")

# Update an existing product
@app.post("/edit/{product_id}")
async def update_product(request: Request, product_id: str, name: str = Form(...), description: str = Form(...), price: float = Form(...), type: str = Form(...), image: UploadFile = File(None)):
    update_expression = "SET #n = :name, description = :description, price = :price, #t = :type"
    expression_attribute_values = {
        ":name": name,
        ":description": description,
        ":price": Decimal(str(price)),  # Ensure price is stored as Decimal
        ":type": type
    }
    expression_attribute_names = {
        "#n": "name",
        "#t": "type"
    }
    
    # Fetch the current item to get the existing image_url
    current_item = table.get_item(Key={'product_id': product_id}).get('Item')
    
    if image:
        # Use the product name as the filename
        filename = f"{name.replace(' ', '_').lower()}"
        file_path = f"/tmp/{filename}"
        
        with open(file_path, "wb") as f:
            f.write(await image.read())
        
        s3_client.upload_file(file_path, S3_BUCKET_NAME, filename)
        image_url = filename  # Store the filename in the table
        
        update_expression += ", image_url = :image_url"
        expression_attribute_values[":image_url"] = image_url
    
    table.update_item(
        Key={'product_id': product_id},
        UpdateExpression=update_expression,
        ExpressionAttributeValues=expression_attribute_values,
        ExpressionAttributeNames=expression_attribute_names
    )
    
    return RedirectResponse(url="/admin/products?msg=Product updated successfully", status_code=303)

# Delete a product
@app.post("/delete/{product_id}")
async def delete_product(request: Request, product_id: str):
    try:
        table.delete_item(Key={'product_id': product_id})
        return RedirectResponse(url="/admin/products?msg=Product deleted successfully", status_code=303)
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error deleting product")

# Health check endpoint
@app.get("/healthz", response_model=dict)
async def health_check():
    return JSONResponse(content={"status": "healthy", "mode": "local" if LOCAL_MODE else "aws"}, status_code=200)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080, reload=True)
