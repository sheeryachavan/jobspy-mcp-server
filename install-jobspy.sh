#!/bin/bash

# Quick JobSpy Installation Fix

echo "🔧 Installing JobSpy in virtual environment..."

cd "/Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server"

# Activate virtual environment
source venv/bin/activate

# Install JobSpy
echo "📦 Installing python-jobspy package..."
pip install python-jobspy>=1.1.80

# Test installation
echo "🧪 Testing installation..."
if python -c "import jobspy; print('✅ JobSpy installed successfully')" 2>/dev/null; then
    echo "✅ JobSpy is working!"
else
    echo "❌ Installation failed, trying alternative..."
    cd jobspy
    pip install -r requirements.txt
    cd ..
    
    if python -c "import jobspy; print('✅ JobSpy installed successfully')" 2>/dev/null; then
        echo "✅ JobSpy is working with requirements.txt!"
    else
        echo "❌ Still having issues. Try system-wide installation:"
        echo "   pip3 install python-jobspy>=1.1.80"
    fi
fi

deactivate

echo ""
echo "✅ Done! Now run: npm start"