#!/bin/bash

# Wait for LocalStack to be ready
echo "Waiting for LocalStack to be ready..."
aws --endpoint-url=http://localhost:4566 --region=us-east-1 s3 ls > /dev/null 2>&1
while [ $? -ne 0 ]; do
  sleep 1
  aws --endpoint-url=http://localhost:4566 --region=us-east-1 s3 ls > /dev/null 2>&1
done
echo "LocalStack is ready!"

# Create S3 bucket
echo "Creating S3 bucket: coffeeshop-bucket-local"
aws --endpoint-url=http://localhost:4566 --region=us-east-1 s3 mb s3://coffeeshop-bucket-local

# Create DynamoDB table
echo "Creating DynamoDB table: coffeeShopDB"
aws --endpoint-url=http://localhost:4566 --region=us-east-1 dynamodb create-table \
  --table-name coffeeShopDB \
  --attribute-definitions AttributeName=product_id,AttributeType=S \
  --key-schema AttributeName=product_id,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Add sample data
echo "Adding sample data to DynamoDB..."
aws --endpoint-url=http://localhost:4566 --region=us-east-1 dynamodb put-item \
  --table-name coffeeShopDB \
  --item '{
    "product_id": {"S": "1"},
    "name": {"S": "Espresso"},
    "description": {"S": "Strong black coffee made by forcing steam through ground coffee beans"},
    "price": {"N": "3.50"},
    "image_url": {"S": "espresso.jpg"},
    "type": {"S": "coffee"}
  }'

aws --endpoint-url=http://localhost:4566 --region=us-east-1 dynamodb put-item \
  --table-name coffeeShopDB \
  --item '{
    "product_id": {"S": "2"},
    "name": {"S": "Cappuccino"},
    "description": {"S": "Coffee made with milk that has been frothed up with pressurized steam"},
    "price": {"N": "4.50"},
    "image_url": {"S": "cappuccino.jpg"},
    "type": {"S": "coffee"}
  }'

aws --endpoint-url=http://localhost:4566 --region=us-east-1 dynamodb put-item \
  --table-name coffeeShopDB \
  --item '{
    "product_id": {"S": "3"},
    "name": {"S": "Green Tea"},
    "description": {"S": "Tea made from Camellia sinensis leaves that have not undergone oxidation"},
    "price": {"N": "3.00"},
    "image_url": {"S": "green_tea.jpg"},
    "type": {"S": "tea"}
  }'

echo "AWS resources initialization completed!" 