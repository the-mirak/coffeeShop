from fastapi import FastAPI, Depends, HTTPException, Request, Form, UploadFile, File
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
from typing import List
import boto3
import os
from dotenv import load_dotenv
import uuid
import logging
from decimal import Decimal

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI()

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Setup Jinja2 templates
templates = Jinja2Templates(directory="templates")

# Setup AWS services
S3_BUCKET_NAME = os.getenv('S3_BUCKET_NAME')
DYNAMODB_TABLE_NAME = os.getenv('DYNAMODB_TABLE_NAME')
AWS_REGION = os.getenv('AWS_REGION')

dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
s3_client = boto3.client('s3', region_name=AWS_REGION)
table = dynamodb.Table(DYNAMODB_TABLE_NAME)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Print current working directory and templates directory
print("Current working directory:", os.getcwd())
print("Templates directory absolute path:", os.path.abspath("templates"))

# Pydantic model for product
class Product(BaseModel):
    product_id: str
    name: str
    description: str
    price: float
    image_url: str = None
    type: str

@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    try:
        return templates.TemplateResponse("index.html", {"request": request})
    except TemplateNotFound:
        raise HTTPException(status_code=404, detail="Template not found: index.html")

@app.get("/menu", response_class=HTMLResponse)
async def menu(request: Request):
    try:
        response = table.scan()
        products = response.get('Items', [])
        return templates.TemplateResponse("menu.html", {"request": request, "products": products})
    except TemplateNotFound:
        raise HTTPException(status_code=404, detail="Template not found: menu.html")

@app.get("/about", response_class=HTMLResponse)
async def about(request: Request):
    try:
        return templates.TemplateResponse("about.html", {"request": request})
    except TemplateNotFound:
        raise HTTPException(status_code=404, detail="Template not found: about.html")

@app.get("/contact", response_class=HTMLResponse)
async def contact(request: Request):
    try:
        return templates.TemplateResponse("contact.html", {"request": request})
    except TemplateNotFound:
        raise HTTPException(status_code=404, detail="Template not found: contact.html")

@app.get("/admin", response_class=HTMLResponse)
async def admin_dashboard(request: Request):
    try:
        response = table.scan()
        products = response.get('Items', [])
        return templates.TemplateResponse("admin.html", {"request": request, "products": products})
    except TemplateNotFound:
        raise HTTPException(status_code=404, detail="Template not found: admin.html")

@app.get("/add", response_class=HTMLResponse)
async def add_product_page(request: Request):
    try:
        return templates.TemplateResponse("add_product.html", {"request": request})
    except TemplateNotFound:
        raise HTTPException(status_code=404, detail="Template not found: add_product.html")

@app.get("/edit/{product_id}", response_class=HTMLResponse)
async def edit_product_page(request: Request, product_id: str):
    try:
        response = table.get_item(Key={'product_id': product_id})
        product = response['Item']
        return templates.TemplateResponse("edit_product.html", {"request": request, "product": product})
    except Exception as e:
        logger.error(f"Error fetching product {product_id}: {e}")
        raise HTTPException(status_code=404, detail="Product not found")

@app.get("/products", response_model=List[Product])
async def get_products():
    response = table.scan()
    products = response.get('Items', [])
    return products

@app.post("/products", response_model=Product)
async def create_product(name: str = Form(...), description: str = Form(...), price: float = Form(...), type: str = Form(...), image: UploadFile = File(...)):
    product_id = str(uuid.uuid4())
    filename = f"{product_id}_{image.filename}"
    file_path = f"/tmp/{filename}"

    os.makedirs("/tmp", exist_ok=True)
    
    with open(file_path, "wb") as f:
        f.write(await image.read())
    
    s3_client.upload_file(file_path, S3_BUCKET_NAME, filename)
    image_url = f"https://{S3_BUCKET_NAME}.s3.{AWS_REGION}.amazonaws.com/{filename}"
    
    item = {
        'product_id': product_id,
        'name': name,
        'description': description,
        'price': Decimal(price),
        'image_url': image_url,
        'type': type
    }
    table.put_item(Item=item)
    
    return item

@app.post("/edit/{product_id}", response_model=Product)
async def update_product(product_id: str, name: str = Form(...), description: str = Form(...), price: float = Form(...), type: str = Form(...), image: UploadFile = File(None)):
    update_expression = "SET name = :name, description = :description, price = :price, type = :type"
    expression_attribute_values = {
        ":name": name,
        ":description": description,
        ":price": Decimal(price),
        ":type": type
    }
    
    if image:
        filename = f"{product_id}_{image.filename}"
        file_path = f"/tmp/{filename}"

        os.makedirs("/tmp", exist_ok=True)
        
        with open(file_path, "wb") as f:
            f.write(await image.read())
        
        s3_client.upload_file(file_path, S3_BUCKET_NAME, filename)
        image_url = f"https://{S3_BUCKET_NAME}.s3.{AWS_REGION}.amazonaws.com/{filename}"
        
        update_expression += ", image_url = :image_url"
        expression_attribute_values[":image_url"] = image_url
    
    table.update_item(
        Key={'product_id': product_id},
        UpdateExpression=update_expression,
        ExpressionAttributeValues=expression_attribute_values
    )
    
    response = table.get_item(Key={'product_id': product_id})
    return response['Item']

@app.post("/delete/{product_id}", response_model=dict)
async def delete_product(product_id: str):
    try:
        table.delete_item(Key={'product_id': product_id})
        return {"message": "Product deleted successfully"}
    except Exception as e:
        logger.error(f"Error deleting product {product_id}: {e}")
        raise HTTPException(status_code=500, detail="Error deleting product")

@app.get("/healthz", response_model=dict)
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
