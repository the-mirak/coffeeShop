# Coffee Shop

A FastAPI web application for a coffee shop, using either AWS services (S3 and DynamoDB) or local storage for development.

## Features

- Product management (add, edit, delete)
- Image upload and storage (S3 in production, local files in development)
- Database storage (DynamoDB in production, JSON files in development)
- Responsive UI for customers and admin

## Docker Setup for Local Development

This project includes Docker configuration for local development without requiring AWS resources or LocalStack.

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Running Locally with Docker

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Build and start the Docker container:
   ```bash
   docker-compose up --build
   ```

3. Access the application at [http://localhost:8080](http://localhost:8080)

4. For admin access, go to [http://localhost:8080/admin](http://localhost:8080/admin)

### Adding Sample Data

The application will initialize with some sample data. If you want to add your own images:

1. Create a `sample_images` directory in the project root
2. Add your image files with names matching the entries in `init_local_data.py`
3. Restart the container

### Switching Between Local and AWS Endpoints

To switch between local development and AWS:

1. Edit your `.env` file:
   - For local development: `LOCAL_MODE=true`
   - For AWS: `LOCAL_MODE=false`

2. When using AWS mode, provide valid AWS configuration:

   ```
   LOCAL_MODE=false
   S3_BUCKET_NAME=your-actual-bucket
   DYNAMODB_TABLE_NAME=your-actual-table
   AWS_REGION=your-region
   ```

3. For AWS authentication, the following methods are supported (in order of best practice):

   a) **IAM Roles (Recommended)**:
      - When running in AWS (EC2/ECS/EKS): Configure instance/task IAM roles with appropriate permissions
      - When running locally: Use AWS CLI profiles with role assumption
      ```
      # In docker-compose.yml or .env file
      AWS_PROFILE=your-profile-name
      ```

   b) **Direct Credentials (Not Recommended for Production)**:
      ```
      AWS_ACCESS_KEY_ID=your-access-key
      AWS_SECRET_ACCESS_KEY=your-secret-key
      ```

4. Restart the container to apply changes:
   ```bash
   docker-compose down
   docker-compose up
   ```

## Development

- The application uses FastAPI with Jinja2 templates
- Static files are in the `static` directory
- Templates are in the `templates` directory
- Local data is stored in `local_data` when running in local mode

## Project Structure

- `main.py` - Main application entry point
- `local_storage.py` - Local storage implementations for development
- `init_local_data.py` - Script to initialize local data
- `models.py` - Data models
- `templates/` - HTML templates
- `static/` - Static assets (CSS, JS, etc.)
- `local_data/` - Local storage for development (created at runtime)
  - `images/` - Local image storage
  - `db/` - Local database files

## License

This project is licensed under the MIT License.