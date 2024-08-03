#!/bin/bash
# Update the package index
sudo yum update -y

# Install necessary packages
sudo yum install -y git nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Clone the GitHub repository
cd /home/ec2-user
git clone https://github.com/the-mirak/coffeeShop.git

# Move the cloned files to the Nginx web directory
sudo cp -r coffeeShop/* /usr/share/nginx/html/

# Set the correct permissions
sudo chown -R nginx:nginx /usr/share/nginx/html

# Configure Nginx to serve the static website
sudo tee /etc/nginx/conf.d/coffeeShop.conf <<EOL
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index coffee_shop.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

# Remove the default Nginx configuration file
sudo rm /etc/nginx/conf.d/default.conf

# Restart Nginx to apply the changes
sudo systemctl restart nginx
