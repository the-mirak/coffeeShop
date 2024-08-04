#!/bin/bash

# Update the system and install necessary packages
yum update -y
yum install -y git python3-pip

# Clone the repository
REPO_URL="https://github.com/the-mirak/coffeeShop.git"
TARGET_DIR="/home/ec2-user/coffeeShop"
git clone $REPO_URL $TARGET_DIR

# Check if the clone was successful
if [ ! -d "$TARGET_DIR" ]; then
  echo "Directory $TARGET_DIR does not exist. Git clone might have failed."
  exit 1
fi

# Change directory to the application folder
cd $TARGET_DIR

# Create a .env file with necessary environment variables
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat <<EOF > .env
S3_BUCKET_NAME=coffeeshop-bucket-24
DYNAMODB_TABLE_NAME=coffeeShopDB
AWS_REGION=us-east-1
EOF

# Install dependencies
pip3 install -r requirements.txt

# Install gunicorn
pip3 install gunicorn

# Make sure the script is executable
chmod +x run.sh

# Create a systemd service to run the FastAPI application with gunicorn
cat <<EOF > /etc/systemd/system/coffeeShop.service
[Unit]
Description=CoffeeShop FastAPI Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=$TARGET_DIR
ExecStart=/usr/local/bin/gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app -b 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to apply the new service
systemctl daemon-reload

# Enable the service to start on boot
systemctl enable coffeeShop.service

# Start the FastAPI application service
systemctl start coffeeShop.service
