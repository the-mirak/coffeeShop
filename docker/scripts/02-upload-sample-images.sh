#!/bin/bash

# Create a temporary directory for sample images
mkdir -p /tmp/sample-images

# Create sample image files (1x1 pixel transparent PNGs)
echo "Creating sample image files..."
cat > /tmp/sample-images/espresso.jpg << 'EOL'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==
EOL

cat > /tmp/sample-images/cappuccino.jpg << 'EOL'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==
EOL

cat > /tmp/sample-images/green_tea.jpg << 'EOL'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==
EOL

# Convert base64 to binary
base64 -d /tmp/sample-images/espresso.jpg > /tmp/sample-images/espresso.jpg.bin
base64 -d /tmp/sample-images/cappuccino.jpg > /tmp/sample-images/cappuccino.jpg.bin
base64 -d /tmp/sample-images/green_tea.jpg > /tmp/sample-images/green_tea.jpg.bin

# Upload sample images to S3
echo "Uploading sample images to S3..."
aws --endpoint-url=http://localhost:4566 --region=us-east-1 s3 cp /tmp/sample-images/espresso.jpg.bin s3://coffeeshop-bucket-local/espresso.jpg
aws --endpoint-url=http://localhost:4566 --region=us-east-1 s3 cp /tmp/sample-images/cappuccino.jpg.bin s3://coffeeshop-bucket-local/cappuccino.jpg
aws --endpoint-url=http://localhost:4566 --region=us-east-1 s3 cp /tmp/sample-images/green_tea.jpg.bin s3://coffeeshop-bucket-local/green_tea.jpg

# Clean up
rm -rf /tmp/sample-images

echo "Sample images uploaded to S3!" 