#!/bin/bash

# Navigate to the docker directory
cd "$(dirname "$0")"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Error: Docker is not running. Please start Docker and try again."
  exit 1
fi

# Function to display help
show_help() {
  echo "Usage: $0 [OPTION]"
  echo "Run the Coffee Shop application locally using Docker."
  echo ""
  echo "Options:"
  echo "  up        Start the application (default if no option is provided)"
  echo "  down      Stop the application and remove containers"
  echo "  rebuild   Rebuild the application image and restart"
  echo "  logs      Show logs from all containers"
  echo "  help      Display this help message"
  echo ""
}

# Process command line arguments
case "$1" in
  up|"")
    echo "Starting Coffee Shop application..."
    docker-compose up -d
    echo "Application is running at http://localhost:8080"
    ;;
  down)
    echo "Stopping Coffee Shop application..."
    docker-compose down
    ;;
  rebuild)
    echo "Rebuilding and restarting Coffee Shop application..."
    docker-compose down
    docker-compose build --no-cache app
    docker-compose up -d
    echo "Application is running at http://localhost:8080"
    ;;
  logs)
    docker-compose logs -f
    ;;
  help)
    show_help
    ;;
  *)
    echo "Unknown option: $1"
    show_help
    exit 1
    ;;
esac 