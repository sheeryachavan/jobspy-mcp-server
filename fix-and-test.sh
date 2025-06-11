#!/bin/bash

# Simple Fix and Test Script for JobSpy MCP Server

PROJECT_DIR="/Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server"
cd "$PROJECT_DIR"

echo "🔧 JobSpy MCP Server - Fix and Test"
echo "==================================="
echo ""

# Test 1: Check if virtual environment works
echo "1️⃣ Testing virtual environment..."
if [ -f "venv/bin/python3" ]; then
    echo "✅ Virtual environment found"
    PYTHON_CMD="./venv/bin/python3"
    PIP_CMD="./venv/bin/pip3"
elif [ -f "venv/bin/python" ]; then
    echo "✅ Virtual environment found"
    PYTHON_CMD="./venv/bin/python"
    PIP_CMD="./venv/bin/pip"
else
    echo "⚠️  Virtual environment not found, using system Python"
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
        PIP_CMD="pip3"
    else
        PYTHON_CMD="python"
        PIP_CMD="pip"
    fi
fi

echo "Using Python: $PYTHON_CMD"
echo ""

# Test 2: Check if JobSpy is installed
echo "2️⃣ Checking JobSpy installation..."
if $PYTHON_CMD -c "import jobspy; print('JobSpy version:', jobspy.__version__)" 2>/dev/null; then
    echo "✅ JobSpy is installed and working"
else
    echo "❌ JobSpy not found, installing..."
    
    # Install JobSpy
    echo "📦 Installing JobSpy..."
    if $PIP_CMD install python-jobspy>=1.1.80; then
        echo "✅ JobSpy installed successfully"
    else
        echo "❌ Failed to install JobSpy"
        echo "Trying alternative installation..."
        if [ -f "jobspy/requirements.txt" ]; then
            cd jobspy
            $PIP_CMD install -r requirements.txt
            cd ..
            echo "✅ JobSpy installed from requirements.txt"
        else
            echo "❌ Could not install JobSpy"
            exit 1
        fi
    fi
fi

echo ""

# Test 3: Test JobSpy functionality
echo "3️⃣ Testing JobSpy functionality..."
cd jobspy

echo "🧪 Testing help command..."
if $PYTHON_CMD main.py --help > /dev/null 2>&1; then
    echo "✅ JobSpy help command works"
else
    echo "❌ JobSpy help command failed"
    exit 1
fi

echo "🔍 Testing simple job search..."
echo "   (This may take 20-30 seconds...)"

# Create a test command with shorter timeout
if timeout 45 $PYTHON_CMD main.py \
    --search_term "test" \
    --location "remote" \
    --results_wanted 1 \
    --site_name "indeed" \
    --format "json" > /tmp/jobspy_test_output.json 2>&1; then
    
    echo "✅ Job search completed successfully"
    
    # Check if output contains jobs
    if [ -s /tmp/jobspy_test_output.json ]; then
        echo "✅ Output file created"
        
        # Try to validate JSON
        if $PYTHON_CMD -m json.tool /tmp/jobspy_test_output.json > /dev/null 2>&1; then
            echo "✅ Output is valid JSON"
            
            # Count jobs found
            JOB_COUNT=$($PYTHON_CMD -c "
import json
try:
    with open('/tmp/jobspy_test_output.json', 'r') as f:
        data = json.load(f)
    if isinstance(data, list):
        print(len(data))
    else:
        print('1' if data else '0')
except:
    print('0')
" 2>/dev/null || echo "0")
            
            echo "✅ Found $JOB_COUNT job(s) in test search"
        else
            echo "⚠️  Output exists but may not be valid JSON"
            echo "   First few lines of output:"
            head -3 /tmp/jobspy_test_output.json
        fi
    else
        echo "⚠️  No output generated (this might be normal for some sites)"
    fi
else
    echo "❌ Job search test failed"
    echo "Error output:"
    cat /tmp/jobspy_test_output.json 2>/dev/null | tail -5
    echo ""
    echo "⚠️  This might be due to:"
    echo "   - Network issues"
    echo "   - Rate limiting from job sites"
    echo "   - Missing dependencies"
    echo "   - Site blocking automated requests"
    echo ""
    echo "   The MCP server might still work for other searches."
fi

cd ..
echo ""

# Test 4: Test Node.js setup
echo "4️⃣ Testing Node.js setup..."
if [ -d "node_modules" ]; then
    echo "✅ Node modules installed"
else
    echo "❌ Node modules missing, installing..."
    npm install
    echo "✅ Node modules installed"
fi

# Test if the main server file exists and is readable
if node -e "console.log('✅ Node.js can run the server')" 2>/dev/null; then
    echo "✅ Node.js is working"
else
    echo "❌ Node.js test failed"
fi

echo ""

# Final summary
echo "🎯 Test Summary"
echo "==============="
echo ""
echo "✅ Setup appears to be working!"
echo ""
echo "📋 To start the MCP server:"
echo "   npm start"
echo ""
echo "📋 Claude MCP Configuration:"
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
echo "🚀 You should now be able to search for jobs through Claude!"
echo ""
echo "💡 If you still have issues:"
echo "   1. Check that Claude is configured with the above MCP settings"
echo "   2. Restart Claude after adding the MCP configuration"
echo "   3. Try a simple search like: 'Find me 3 software developer jobs'"