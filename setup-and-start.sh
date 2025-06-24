#!/bin/bash

# JobSpy MCP Server Setup and Startup Script
# Run this script to set up and start your JobSpy MCP server

set -e  # Exit on any error

echo "🚀 Setting up JobSpy MCP Server..."

# Navigate to the project directory
PROJECT_DIR="/Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server"
cd "$PROJECT_DIR"

echo "📁 Working directory: $PROJECT_DIR"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

echo "✅ Docker is installed"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

echo "✅ Node.js is installed"

# Install npm dependencies
echo "📦 Installing npm dependencies..."
npm install

# Build the JobSpy Docker image
echo "🐳 Building JobSpy Docker image..."
cd jobspy
if docker build -t jobspy .; then
    echo "✅ JobSpy Docker image built successfully"
else
    echo "❌ Failed to build JobSpy Docker image"
    exit 1
fi

# Go back to main directory
cd "$PROJECT_DIR"

# Test Docker image
echo "🧪 Testing JobSpy Docker image..."
if docker run --rm jobspy --help > /dev/null 2>&1; then
    echo "✅ JobSpy Docker image is working correctly"
else
    echo "❌ JobSpy Docker image test failed"
    exit 1
fi

# Test a quick job search
echo "🔍 Testing job search functionality..."
if docker run --rm jobspy --search_term "test" --location "remote" --results_wanted 1 > /dev/null 2>&1; then
    echo "✅ Job search test passed"
else
    echo "⚠️  Job search test failed, but continuing..."
fi

echo ""
echo "🎉 Setup complete! Your JobSpy MCP Server is ready."
echo ""
echo "📋 To use with Claude, add this to your MCP settings:"
echo ""
echo '{
  "mcpServers": {
    "jobspy": {
      "command": "node",
      "args": ["'"$PROJECT_DIR"'/src/index.js"],
      "env": {
        "ENABLE_SSE": "false"
      }
    }
  }
}'
echo ""
echo "🚀 Starting the server now..."
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server
npm start