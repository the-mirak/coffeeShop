# Project Context - Brew Haven Coffee Shop

## Project Overview
Brew Haven is a FastAPI-based coffee shop web application with dual-mode architecture supporting both local development and AWS production deployment.

## Technology Stack
- **Backend**: FastAPI with Python 3.9
- **Frontend**: Jinja2 templates with modern CSS
- **Storage**: Dual-mode (Local JSON/files for dev, DynamoDB/S3 for production)
- **Deployment**: Docker containerized

## Current Features
- Product management (CRUD operations)
- Image upload and storage
- Admin dashboard
- Customer menu interface
- Category filtering (coffee, tea, pastry, dessert, juice)
- Responsive design

## Architecture Patterns
- Repository pattern for data access
- Local storage implementations that mirror AWS APIs
- Environment-based configuration switching
- RESTful API endpoints

## Development Guidelines
- Use Pydantic models for data validation
- Follow FastAPI best practices
- Maintain compatibility between local and AWS modes
- Use proper error handling and logging
- Implement responsive UI patterns

## File Structure
- `main.py` - Main FastAPI application
- `models.py` - Pydantic data models
- `local_storage.py` - Local development storage implementations
- `templates/` - Jinja2 HTML templates
- `static/` - CSS, JS, and static assets
- `local_data/` - Local development data storage