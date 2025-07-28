#!/bin/bash

# Git push script for Brew Haven project
echo "🚀 Preparing to commit and push Brew Haven changes..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not a git repository. Please run this from the project root."
    exit 1
fi

# Show current status
echo "📊 Current git status:"
git status

# Add all changes including the .kiro specs
echo "📝 Adding changes to staging..."
git add .
git add .kiro/

# Show what will be committed
echo "📋 Changes to be committed:"
git status --staged

# Commit with a descriptive message
COMMIT_MSG="feat: Add Brew Haven coffee shop application with order system specs

- Complete FastAPI coffee shop application with dual-mode architecture
- Local development with JSON storage and AWS production with DynamoDB/S3
- Admin dashboard for product management with image upload
- Customer menu interface with category filtering
- Responsive design with modern CSS
- Docker containerization for easy deployment
- Order system specifications in .kiro/specs/order-system/
- Comprehensive documentation and build instructions"

echo "💾 Committing changes..."
git commit -m "$COMMIT_MSG"

# Push to remote
echo "🌐 Pushing to remote repository..."
git push origin main

echo "✅ Successfully pushed changes to remote repository!"
echo "🎉 Your Brew Haven project is now up to date!"