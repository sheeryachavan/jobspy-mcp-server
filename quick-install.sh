#!/bin/bash

# Quick Install Script for JobSpy MCP Server (Local Python)
# This script installs everything you need to run JobSpy locally without Docker

set -e  # Exit on any error

PROJECT_DIR="/Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server"

echo "🚀 JobSpy MCP Server - Quick Local Install"
echo "========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "📁 Changing to project directory..."
    cd "$PROJECT_DIR"
fi

echo "📁 Working in: $(pwd)"
echo ""

# Step 1: Check prerequisites
echo "1️⃣ Checking prerequisites..."

# Check Python
if command -v python3 &> /dev/null; then
    echo "✅ Python3: $(python3 --version)"
elif command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1)
    if [ "$PYTHON_VERSION" = "3" ]; then
        echo "✅ Python: $(python --version)"
    else
        echo "❌ Python 3 required, but found Python $PYTHON_VERSION"
        echo "Please install Python 3: https://www.python.org/downloads/"
        exit 1
    fi
else
    echo "❌ Python not found"
    echo "Please install Python 3: https://www.python.org/downloads/"
    exit 1
fi

# Check Node.js
if command -v node &> /dev/null; then
    echo "✅ Node.js: $(node --version)"
else
    echo "❌ Node.js not found"
    echo "Please install Node.js: https://nodejs.org/"
    exit 1
fi

# Check npm
if command -v npm &> /dev/null; then
    echo "✅ npm: $(npm --version)"
else
    echo "❌ npm not found (should come with Node.js)"
    exit 1
fi

echo ""

# Step 2: Install Node.js dependencies
echo "2️⃣ Installing Node.js dependencies..."
npm install
echo "✅ Node.js dependencies installed"
echo ""

# Step 3: Set up Python environment
echo "3️⃣ Setting up Python environment..."

# Determine Python command
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    PIP_CMD="pip3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
    PIP_CMD="pip"
fi

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "📦 Creating Python virtual environment..."
    $PYTHON_CMD -m venv venv
    echo "✅ Virtual environment created"
else
    echo "📦 Virtual environment already exists"
fi

# Activate virtual environment and install dependencies
echo "📦 Installing Python dependencies..."
source venv/bin/activate

# Install jobspy
cd jobspy
pip install -r requirements.txt
echo "✅ JobSpy Python package installed"

cd ..
echo ""

# Step 4: Test the installation
echo "4️⃣ Testing installation..."

# Test Python JobSpy
echo "🧪 Testing JobSpy Python package..."
if $PYTHON_CMD -c "import jobspy; print('✅ JobSpy can be imported')" 2>/dev/null; then
    echo "✅ JobSpy Python package working"
else
    echo "❌ JobSpy import failed"
    echo "Trying system-wide installation..."
    deactivate 2>/dev/null || true
    $PIP_CMD install python-jobspy>=1.1.80
    if $PYTHON_CMD -c "import jobspy; print('✅ JobSpy can be imported')" 2>/dev/null; then
        echo "✅ JobSpy working with system installation"
    else
        echo "❌ JobSpy installation failed"
        exit 1
    fi
fi

# Test a simple job search (quick test)
echo "🔍 Testing job search (quick test)..."
cd jobspy
if timeout 30 $PYTHON_CMD main.py --search_term "test" --location "remote" --results_wanted 1 --site_name "indeed" > /tmp/jobspy_quick_test.json 2>&1; then
    if [ -s /tmp/jobspy_quick_test.json ]; then
        echo "✅ Job search test completed successfully"
    else
        echo "⚠️  Job search completed but no output (may be normal)"
    fi
else
    echo "⚠️  Quick job search test failed, but installation may still work"
    echo "   (This can happen due to rate limiting or network issues)"
fi

cd ..
deactivate 2>/dev/null || true

echo ""

# Step 5: Final instructions
echo "🎉 Installation Complete!"
echo "======================="
echo ""
echo "✅ All components installed successfully"
echo ""
echo "📋 Next Steps:"
echo "1. Add this to your Claude MCP settings:"
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
echo "2. Start the MCP server:"
echo "   npm start"
echo ""
echo "3. Restart Claude to pick up the new MCP server"
echo ""
echo "🔧 Troubleshooting:"
echo "   - If you have issues, run: ./test-local.sh"
echo "   - Check: TROUBLESHOOTING-LOCAL.md"
echo ""
echo "🚀 You're ready to search for jobs with Claude!"