FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create directories for local data
RUN mkdir -p /app/local_data/images /app/local_data/db /app/sample_images

# Copy application code
COPY . .

# Make the entrypoint script executable
RUN chmod +x /app/docker-entrypoint.sh

# Expose port 8080
EXPOSE 8080

# Set the entrypoint script
ENTRYPOINT ["/app/docker-entrypoint.sh"] 