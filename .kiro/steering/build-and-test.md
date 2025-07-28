# Build and Test Instructions - Brew Haven

## Local Development Setup

### Prerequisites
- Docker and Docker Compose
- Python 3.9+ (for local development without Docker)

### Quick Start with Docker
```bash
# Copy environment configuration
cp .env.example .env

# Build and start the application
docker-compose up --build

# Access the application
# - Customer interface: http://localhost:8080
# - Admin interface: http://localhost:8080/admin
# - Health check: http://localhost:8080/healthz
```

### Local Python Development
```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export LOCAL_MODE=true
export S3_BUCKET_NAME=local-bucket
export DYNAMODB_TABLE_NAME=local-table
export AWS_REGION=local

# Initialize sample data
python init_local_data.py

# Run the application
uvicorn main:app --host 0.0.0.0 --port 8080 --reload
```

## Testing

### Manual Testing
- Test product CRUD operations in admin interface
- Verify image upload functionality
- Test category filtering on menu page
- Check responsive design on different screen sizes

### API Testing
```bash
# Health check
curl http://localhost:8080/healthz

# Get all products
curl http://localhost:8080/products
```

## Deployment

### AWS Production Setup
1. Set `LOCAL_MODE=false` in environment
2. Configure AWS credentials (IAM roles recommended)
3. Set proper S3 bucket and DynamoDB table names
4. Deploy using your preferred AWS deployment method

### Environment Variables
- `LOCAL_MODE`: true/false - switches between local and AWS storage
- `S3_BUCKET_NAME`: S3 bucket for image storage
- `DYNAMODB_TABLE_NAME`: DynamoDB table for product data
- `AWS_REGION`: AWS region for services