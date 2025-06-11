#!/bin/bash

# Test script for JobSpy MCP Server (Local)

PROJECT_DIR="/Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server"
cd "$PROJECT_DIR"

echo "🧪 Testing JobSpy MCP Server (Local Version)..."

# Test 1: Check Python availability
echo ""
echo "1️⃣ Testing Python availability..."
if command -v python3 &> /dev/null; then
    echo "✅ python3 found: $(python3 --version)"
elif command -v python &> /dev/null; then
    echo "✅ python found: $(python --version)"
else
    echo "❌ Python not found"
    exit 1
fi

# Test 2: Check virtual environment
echo ""
echo "2️⃣ Testing virtual environment..."
if [ -d "venv" ]; then
    echo "✅ Virtual environment found"
    if [ -f "venv/bin/python" ] || [ -f "venv/bin/python" ]; then
        echo "✅ Python executable found in venv"
    else
        echo "❌ Python executable not found in venv"
    fi
else
    echo "⚠️  Virtual environment not found - will use system Python"
fi

# Test 3: Check jobspy directory
echo ""
echo "3️⃣ Testing JobSpy files..."
if [ -d "jobspy" ]; then
    echo "✅ JobSpy directory found"
    if [ -f "jobspy/main.py" ]; then
        echo "✅ main.py found"
    else
        echo "❌ main.py not found in jobspy directory"
        exit 1
    fi
    if [ -f "jobspy/requirements.txt" ]; then
        echo "✅ requirements.txt found"
    else
        echo "❌ requirements.txt not found"
    fi
else
    echo "❌ JobSpy directory not found"
    exit 1
fi

# Test 4: Check Node.js dependencies
echo ""
echo "4️⃣ Testing Node.js setup..."
if [ -d "node_modules" ]; then
    echo "✅ Node modules installed"
else
    echo "❌ Node modules not installed. Run: npm install"
    exit 1
fi

# Test 5: Test JobSpy Python execution
echo ""
echo "5️⃣ Testing JobSpy execution..."

# Determine Python command
if [ -f "venv/bin/python3" ]; then
    PYTHON_CMD="./venv/bin/python3"
elif [ -f "venv/bin/python" ]; then
    PYTHON_CMD="./venv/bin/python"
elif command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
else
    PYTHON_CMD="python"
fi

echo "Using Python command: $PYTHON_CMD"

# Test help command
cd jobspy
if $PYTHON_CMD main.py --help > /dev/null 2>&1; then
    echo "✅ JobSpy help command works"
else
    echo "❌ JobSpy help command failed"
    echo "Trying to install requirements..."
    if command -v pip3 &> /dev/null; then
        pip3 install -r requirements.txt
    elif command -v pip &> /dev/null; then
        pip install -r requirements.txt
    else
        echo "❌ pip not found"
        exit 1
    fi
fi

# Test a simple search
echo ""
echo "6️⃣ Testing simple job search..."
if timeout 30 $PYTHON_CMD main.py --search_term "test" --location "remote" --results_wanted 1 --site_name "indeed" > /tmp/jobspy_test.json 2>&1; then
    echo "✅ Simple job search completed"
    if [ -s /tmp/jobspy_test.json ]; then
        echo "✅ Output file created and not empty"
        # Check if it's valid JSON
        if python3 -m json.tool /tmp/jobspy_test.json > /dev/null 2>&1; then
            echo "✅ Output is valid JSON"
        else
            echo "⚠️  Output might not be valid JSON, but test passed"
        fi
    else
        echo "⚠️  Output file is empty, but command succeeded"
    fi
else
    echo "❌ Simple job search failed"
    echo "Last few lines of output:"
    tail -5 /tmp/jobspy_test.json 2>/dev/null || echo "No output file created"
fi

cd "$PROJECT_DIR"

echo ""
echo "🎯 Test Summary:"
echo "If all tests passed, you can now start the MCP server with:"
echo "  npm start"
echo ""
echo "Add this to your Claude MCP settings:"
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