# Docker Setup for Coffee Shop Application

This directory contains Docker configuration for running the Coffee Shop application locally for development and testing purposes.

## Prerequisites

- Docker
- Docker Compose

## Quick Start

To start the application, run:

```bash
./run-local.sh
```

The application will be available at http://localhost:8080

## Available Commands

- `./run-local.sh` or `./run-local.sh up` - Start the application
- `./run-local.sh down` - Stop the application and remove containers
- `./run-local.sh rebuild` - Rebuild the application image and restart
- `./run-local.sh logs` - Show logs from all containers
- `./run-local.sh help` - Display help message

## Architecture

The Docker setup consists of the following components:

1. **FastAPI Application**: The main application container running the FastAPI web server.
2. **LocalStack**: A container that simulates AWS services locally, including:
   - DynamoDB for database storage
   - S3 for image storage

## Development Workflow

1. Start the application using `./run-local.sh`
2. Make changes to the code - the application will automatically reload
3. Access the application at http://localhost:8080
4. Access the admin interface at http://localhost:8080/admin

## Initialization

The following initialization happens automatically when the containers start:

1. Creation of the DynamoDB table
2. Creation of the S3 bucket
3. Loading of sample data
4. Uploading of sample images

## Troubleshooting

If you encounter issues:

1. Check the logs with `./run-local.sh logs`
2. Rebuild the application with `./run-local.sh rebuild`
3. Ensure Docker is running and has sufficient resources allocated 