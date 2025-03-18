#!/bin/bash
set -e

# Change to app directory
cd /app

# Initialize local data if in LOCAL_MODE
if [ "$LOCAL_MODE" = "true" ]; then
    echo "🧪 Running in LOCAL MODE - initializing sample data..."
    python init_local_data.py
else
    echo "🌍 Running with AWS endpoints"
fi

# Start the FastAPI application
echo "🚀 Starting the FastAPI application..."
exec uvicorn main:app --host 0.0.0.0 --port 8080 --reload 