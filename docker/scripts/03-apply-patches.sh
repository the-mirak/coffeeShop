#!/bin/bash

# This script applies necessary patches to the application code for local development

# Check if we're running in the Docker container
if [ ! -f "/.dockerenv" ]; then
  echo "This script should only be run inside the Docker container."
  exit 1
fi

# Apply the main.py patch
echo "Applying patches to application code..."

# Get the current owner of main.py
OWNER=$(stat -c '%u:%g' main.py)
echo "Current owner of main.py is $OWNER"

# Create a backup of the original main.py
cp main.py main.py.original

# Extract the important parts from the patch file
sed -n '/^from fastapi/,$p' /app/docker/main.py.patch > /tmp/main.py.new

# Replace the original file with the patched version
mv /tmp/main.py.new main.py

# Restore the original ownership
chown $OWNER main.py
echo "Ownership restored to $OWNER"

echo "Patches applied successfully!" 