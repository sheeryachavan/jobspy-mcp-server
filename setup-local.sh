#!/bin/bash

# JobSpy MCP Server Local Setup Script (No Docker)
# Run this script to set up and start your JobSpy MCP server locally

set -e  # Exit on any error

echo "🚀 Setting up JobSpy MCP Server (Local Python version)..."

# Navigate to the project directory
PROJECT_DIR="/Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server"
cd "$PROJECT_DIR"

echo "📁 Working directory: $PROJECT_DIR"

# Check if Python is installed
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    echo "✅ Python3 is installed"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
    echo "✅ Python is installed"
    # Check if it's Python 3
    PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1)
    if [ "$PYTHON_VERSION" != "3" ]; then
        echo "❌ Python 2 detected. Please install Python 3.x"
        exit 1
    fi
else
    echo "❌ Python is not installed. Please install Python 3.x first."
    echo "Visit: https://www.python.org/downloads/"
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
    echo "❌ pip is not installed. Please install pip first."
    exit 1
fi

# Determine pip command
if command -v pip3 &> /dev/null; then
    PIP_CMD="pip3"
else
    PIP_CMD="pip"
fi

echo "✅ pip is available"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

echo "✅ Node.js is installed"

# Install npm dependencies
echo "📦 Installing npm dependencies..."
npm install

# Set up Python virtual environment
echo "🐍 Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    $PYTHON_CMD -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment and install Python dependencies
echo "📦 Installing Python dependencies..."
source venv/bin/activate

# Install jobspy in the virtual environment
cd jobspy
$PIP_CMD install -r requirements.txt
echo "✅ JobSpy Python package installed"

# Test jobspy installation
echo "🧪 Testing JobSpy installation..."
if $PYTHON_CMD -c "import jobspy; print('JobSpy imported successfully')" 2>/dev/null; then
    echo "✅ JobSpy is working correctly"
else
    echo "❌ JobSpy installation test failed"
    exit 1
fi

# Go back to main directory
cd "$PROJECT_DIR"

# Test a quick job search
echo "🔍 Testing job search functionality..."
if $PYTHON_CMD jobspy/main.py --search_term "test" --location "remote" --results_wanted 1 > /dev/null 2>&1; then
    echo "✅ Job search test passed"
else
    echo "⚠️  Job search test failed, but continuing..."
fi

echo ""
echo "🎉 Setup complete! Your JobSpy MCP Server is ready to run locally."
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

# Deactivate virtual environment for the main server
deactivate

# Start the server
npm start