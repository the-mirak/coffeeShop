from flask import Flask, request, jsonify, render_template
import boto3
import os
from dotenv import load_dotenv
from uuid import uuid4

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)

# AWS configuration
S3_BUCKET_NAME = os.getenv('S3_BUCKET_NAME')
DYNAMODB_TABLE_NAME = os.getenv('DYNAMODB_TABLE_NAME')
AWS_REGION = os.getenv('AWS_REGION')

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
s3 = boto3.client('s3', region_name=AWS_REGION)
table = dynamodb.Table(DYNAMODB_TABLE_NAME)

# Routes
@app.route('/')
def index():
    products = get_all_products()
    return render_template('index.html', products=products)

@app.route('/menu')
def menu():
    products = get_all_products()
    return render_template('menu.html', products=products)

@app.route('/admin')
def admin():
    return render_template('admin.html')

@app.route('/health')
def health():
    return "OK", 200

@app.route('/api/products', methods=['GET', 'POST'])
def products():
    if request.method == 'GET':
        return jsonify(get_all_products())
    elif request.method == 'POST':
        data = request.json
        image_url = generate_presigned_url(data['image_key'])
        data['image_url'] = image_url
        add_product(data)
        return jsonify({"message": "Product added successfully"}), 201

@app.route('/api/products/<product_id>', methods=['GET', 'PUT', 'DELETE'])
def product(product_id):
    if request.method == 'GET':
        return jsonify(get_product(product_id))
    elif request.method == 'PUT':
        data = request.json
        image_url = generate_presigned_url(data['image_key'])
        data['image_url'] = image_url
        update_product(product_id, data)
        return jsonify({"message": "Product updated successfully"})
    elif request.method == 'DELETE':
        delete_product(product_id)
        return jsonify({"message": "Product deleted successfully"})

def get_all_products():
    response = table.scan()
    products = response['Items']
    for product in products:
        product['image_url'] = generate_presigned_url(product['image_key'])
    return products

def get_product(product_id):
    response = table.get_item(Key={'product_id': product_id})
    item = response.get('Item', {})
    if 'image_key' in item:
        item['image_url'] = generate_presigned_url(item['image_key'])
    return item

def add_product(data):
    data['product_id'] = str(uuid4())
    table.put_item(Item=data)

def update_product(product_id, data):
    table.update_item(
        Key={'product_id': product_id},
        UpdateExpression="set #name=:n, description=:d, price=:p, image_url=:i",
        ExpressionAttributeNames={
            '#name': 'name'
        },
        ExpressionAttributeValues={
            ':n': data['name'],
            ':d': data['description'],
            ':p': data['price'],
            ':i': data['image_url']
        }
    )

def delete_product(product_id):
    table.delete_item(Key={'product_id': product_id})

def generate_presigned_url(image_key):
    url = s3.generate_presigned_url('get_object',
        Params={'Bucket': S3_BUCKET_NAME, 'Key': image_key},
        ExpiresIn=3600)
    return url

if __name__ == '__main__':
    app.run(debug=True)
