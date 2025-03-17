#!/bin/bash

# This script tests the API endpoints to verify the setup is working correctly

echo "Testing Coffee Shop API..."

# Wait for the API to be available
echo "Waiting for API to be available..."
until $(curl --output /dev/null --silent --head --fail http://localhost:8080/healthz); do
    printf '.'
    sleep 5
done

echo -e "\nAPI is available!"

# Test health check endpoint
echo "Testing health check endpoint..."
curl -s http://localhost:8080/healthz | grep "healthy" && echo " ✓ Health check passed" || echo " ✗ Health check failed"

# Test products endpoint
echo "Testing products endpoint..."
curl -s http://localhost:8080/products | grep "product_id" && echo " ✓ Products endpoint passed" || echo " ✗ Products endpoint failed"

# Test home page
echo "Testing home page..."
curl -s http://localhost:8080 | grep "Brew Haven" && echo " ✓ Home page passed" || echo " ✗ Home page failed"

echo "API tests completed!" 