#!/bin/bash

# Project name (use first argument or default to 'fastapi_project')
PROJECT_NAME=${1:-fastapi_project}

# Create project directory structure
mkdir -p "$PROJECT_NAME/src/$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize Git repository
git init

# Create source code: main.py
mkdir -p src/"$PROJECT_NAME"
cat > src/"$PROJECT_NAME"/main.py << EOL
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class Item(BaseModel):
    name: str
    description: str | None = None
    price: float
    tax: float | None = None

@app.get("/")
async def root():
    return {"message": "Welcome to FastAPI"}

@app.post("/items/")
async def create_item(item: Item):
    return {"item_name": item.name, "price": item.price}

@app.get("/items/{item_id}")
async def read_item(item_id: int):
    if item_id < 1:
        raise HTTPException(status_code=400, detail="Item ID must be positive")
    return {"item_id": item_id}
EOL

# Create pyproject.toml for Poetry
cat > pyproject.toml << EOL
[tool.poetry]
name = "$PROJECT_NAME"
version = "0.1.0"
description = "FastAPI Project with Docker"
authors = ["Your Name <you@example.com>"]

[tool.poetry.dependencies]
python = "^3.9"
fastapi = "^0.100.0"
uvicorn = "^0.22.0"
pydantic = "^2.0.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.3.1"
httpx = "^0.24.1"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
EOL

# Create Dockerfile
cat > Dockerfile << EOL
# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Add Poetry to PATH
ENV PATH="${PATH}:/root/.local/bin"

# Set working directory
WORKDIR /app

# Copy project files
COPY pyproject.toml poetry.lock* ./

# Configure Poetry
RUN poetry config virtualenvs.create false

# Install dependencies
RUN poetry install --no-interaction --no-ansi

# Copy the application code
COPY src/ ./src/

# Expose the port the app runs on
EXPOSE 8000

# Command to run the application
CMD ["uvicorn", "$PROJECT_NAME.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOL

# Create docker-compose.yml
cat > docker-compose.yml << EOL
version: '3.8'

services:
  web:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - ./src:/app/src
    environment:
      - ENV=development
EOL

# Create .dockerignore
cat > .dockerignore << EOL
__pycache__
*.pyc
*.pyo
*.pyd
.git
.gitignore
.venv
poetry.lock
EOL

# Create README.md
cat > README.md << EOL
# $PROJECT_NAME

## Prerequisites
- Docker
- Docker Compose
- (Optional) Poetry

## Local Development Setup
1. Install Poetry:
\`\`\`bash
curl -sSL https://install.python-poetry.org | python3 -
\`\`\`

2. Install dependencies:
\`\`\`bash
poetry install
\`\`\`

3. Run locally:
\`\`\`bash
poetry run uvicorn $PROJECT_NAME.main:app --reload
\`\`\`

## Docker Deployment

### Build and Run
\`\`\`bash
# Build the image
docker-compose build

# Start the service
docker-compose up
\`\`\`

### Access the API
- Swagger UI: http://localhost:8000/docs
- OpenAPI JSON: http://localhost:8000/openapi.json

## API Endpoints
- \`GET /\`: Root endpoint
- \`POST /items/\`: Create a new item
- \`GET /items/{item_id}\`: Retrieve item by ID

## Development
- Add more routes in \`src/$PROJECT_NAME/main.py\`
- Install additional dependencies with \`poetry add\`
- Run tests with \`poetry run pytest\`
EOL

# Create a basic test file
mkdir -p tests
cat > tests/test_main.py << EOL
from fastapi.testclient import TestClient
from $PROJECT_NAME.main import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Welcome to FastAPI"}

def test_create_item():
    response = client.post(
        "/items/",
        json={"name": "Test Item", "price": 45.2}
    )
    assert response.status_code == 200
    assert response.json()["item_name"] == "Test Item"

def test_read_item():
    response = client.get("/items/1")
    assert response.status_code == 200
    assert response.json() == {"item_id": 1}

def test_invalid_item_id():
    response = client.get("/items/0")
    assert response.status_code == 400
EOL

# Create .gitignore
cat > .gitignore << EOL
__pycache__/
*.py[cod]
.venv/
poetry.lock
.pytest_cache/
*.log
EOL

# Print completion message
echo "FastAPI project '$PROJECT_NAME' created successfully!"
echo "Next steps:"
echo "1. Navigate to the project directory: cd $PROJECT_NAME"
echo "2. Build and run with Docker: docker-compose up --build"
echo "3. Access API at http://localhost:8000/docs"
