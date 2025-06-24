# JobSpy MCP Server - Local Setup Troubleshooting Guide

## 🔧 Common Issues and Solutions (Local Python Version)

### Issue 1: "Python not found"
**Error:** `Python not found. Please install Python 3.x or run setup-local.sh`

**Solutions:**
1. **Install Python 3.x:**
   - Visit: https://www.python.org/downloads/
   - Or use Homebrew: `brew install python3`

2. **Check Python installation:**
   ```bash
   python3 --version
   python --version
   ```

### Issue 2: "JobSpy directory not found"
**Error:** `JobSpy directory not found at /path/to/jobspy`

**Solution:**
Make sure you're running from the correct directory and the jobspy folder exists:
```bash
cd /Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server
ls -la jobspy/
```

### Issue 3: "main.py not found"
**Error:** `main.py not found in /path/to/jobspy`

**Solution:**
Check if the jobspy directory contains the required files:
```bash
ls -la jobspy/
# Should show: main.py, requirements.txt, Dockerfile
```

### Issue 4: "ModuleNotFoundError: No module named 'jobspy'"
**Error:** Python can't find the jobspy module

**Solutions:**
1. **Install jobspy package:**
   ```bash
   pip3 install python-jobspy>=1.1.80
   ```

2. **Use virtual environment (recommended):**
   ```bash
   cd /Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server
   python3 -m venv venv
   source venv/bin/activate
   pip install python-jobspy>=1.1.80
   ```

### Issue 5: "Invalid arguments" or "Expected number, received string"
**Status:** ✅ **FIXED** - Updated schema handles string inputs

### Issue 6: JSON parsing errors in MCP communication
**Error:** `Unexpected non-whitespace character after JSON`

**Solutions:**
1. Restart Claude
2. Make sure server is running in stdio mode (not SSE)
3. Check the MCP configuration in Claude settings

### Issue 7: Job search timeouts
**Error:** Command times out during job search

**Solutions:**
1. **Increase timeout in requests:**
   ```javascript
   // In your requests, add longer timeout
   {
     "timeout": 120000  // 2 minutes
   }
   ```

2. **Reduce results wanted:**
   ```javascript
   {
     "resultsWanted": 5  // Start with fewer results
   }
   ```

## 🧪 Testing Commands

### Test Python Installation:
```bash
python3 --version
pip3 --version
```

### Test JobSpy Package:
```bash
python3 -c "import jobspy; print('JobSpy installed successfully')"
```

### Test Local JobSpy Script:
```bash
cd /Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server/jobspy
python3 main.py --help
python3 main.py --search_term "developer" --location "remote" --results_wanted 3
```

### Test MCP Server Manually:
```bash
cd /Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server
echo '{"method":"tools/list","jsonrpc":"2.0","id":1}' | node src/index.js
```

### Run Full Test Suite:
```bash
cd /Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server
chmod +x test-local.sh
./test-local.sh
```

## 📋 Server Configuration for Claude

Add this to your Claude MCP settings file:

```json
{
  "mcpServers": {
    "jobspy": {
      "command": "node",
      "args": ["/Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server/src/index.js"],
      "env": {
        "ENABLE_SSE": "false"
      }
    }
  }
}
```

## 🚀 Quick Setup (Recommended)

1. **Run the setup script:**
   ```bash
   cd /Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server
   chmod +x setup-local.sh
   ./setup-local.sh
   ```

2. **Or manual setup:**
   ```bash
   # Install Node dependencies
   npm install
   
   # Create and activate virtual environment
   python3 -m venv venv
   source venv/bin/activate
   
   # Install Python dependencies
   cd jobspy
   pip install -r requirements.txt
   cd ..
   
   # Test the setup
   ./test-local.sh
   
   # Start the server
   npm start
   ```

## 🔍 Debugging Steps

1. **Check all requirements:**
   ```bash
   # Python 3
   python3 --version
   
   # Node.js
   node --version
   npm --version
   
   # JobSpy package
   python3 -c "import jobspy; print(jobspy.__version__)"
   ```

2. **Verify file structure:**
   ```bash
   cd /Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server
   tree -L 2  # or ls -la
   # Should show:
   # ├── jobspy/
   # │   ├── main.py
   # │   ├── requirements.txt
   # │   └── Dockerfile
   # ├── src/
   # │   ├── tools/
   # │   ├── schemas/
   # │   └── index.js
   # ├── package.json
   # └── venv/ (if created)
   ```

3. **Test Python execution:**
   ```bash
   cd jobspy
   python3 main.py --search_term "test" --location "remote" --results_wanted 1
   ```

4. **Check Node.js integration:**
   ```bash
   cd ..
   node -e "console.log('Node.js working')"
   npm test 2>/dev/null || echo "No tests defined (OK)"
   ```

## 🆘 If All Else Fails

1. **Clean restart:**
   ```bash
   # Remove virtual environment
   rm -rf venv
   
   # Remove node modules
   rm -rf node_modules
   
   # Reinstall everything
   ./setup-local.sh
   ```

2. **Manual Python package installation:**
   ```bash
   # System-wide installation (not recommended but works)
   pip3 install python-jobspy>=1.1.80
   
   # Or with user flag
   pip3 install --user python-jobspy>=1.1.80
   ```

3. **Alternative testing:**
   ```bash
   # Test JobSpy directly in Python
   python3 -c "
   from jobspy import scrape_jobs
   jobs = scrape_jobs(
       site_name=['indeed'],
       search_term='test',
       location='remote',
       results_wanted=1
   )
   print(f'Found {len(jobs)} jobs')
   "
   ```

## 📝 Environment Variables

Optional environment variables you can set:

```bash
# In your shell or .bashrc/.zshrc
export JOBSPY_TIMEOUT=120000
export JOBSPY_DEFAULT_RESULTS=10
export JOBSPY_VERBOSE=1
```

## 🎯 Final Verification

Once everything is set up, this should work:

```bash
cd /Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server
./test-local.sh
```

If all tests pass, start the server:

```bash
npm start
```

Then configure Claude with the MCP settings above, and you should be able to search for jobs!