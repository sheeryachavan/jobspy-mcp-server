# JobSpy MCP Server - Troubleshooting Guide

## 🔧 Common Issues and Solutions

### Issue 1: "Docker image not found"
**Error:** `JobSpy Docker image not found. Please build it first`

**Solution:**
```bash
cd /Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server/jobspy
docker build -t jobspy .
```

### Issue 2: "Permission denied" when running Docker
**Error:** `permission denied while trying to connect to the Docker daemon socket`

**Solutions:**
1. Make sure Docker Desktop is running
2. Add your user to the docker group:
   ```bash
   sudo usermod -aG docker $USER
   ```
3. Restart your terminal/computer

### Issue 3: "Invalid arguments" or "Expected number, received string"
**Status:** ✅ **FIXED** - Updated schema handles string inputs

### Issue 4: JSON parsing errors in MCP communication
**Error:** `Unexpected non-whitespace character after JSON`

**Solutions:**
1. Restart Claude
2. Make sure server is running in stdio mode (not SSE)
3. Check the MCP configuration in Claude settings

### Issue 5: "Module not found" errors
**Error:** `Cannot find module '@modelcontextprotocol/sdk'`

**Solution:**
```bash
cd /Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server
npm install
```

## 🧪 Testing Commands

### Test Docker Installation:
```bash
docker --version
docker ps
```

### Test JobSpy Docker Image:
```bash
docker images | grep jobspy
docker run --rm jobspy --help
```

### Test Job Search:
```bash
docker run --rm jobspy --search_term "developer" --location "remote" --results_wanted 3
```

### Test MCP Server Manually:
```bash
cd /Users/shreesh.chavan/Downloads/Personal/PersonalProjects/MCPservers/jobspy-mcp-server
echo '{"method":"tools/list","jsonrpc":"2.0","id":1}' | node src/index.js
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

## 🔍 Debugging Steps

1. **Check server logs:**
   - Look for error messages in the terminal where you started the server
   - Check for Docker-related errors

2. **Verify Docker setup:**
   ```bash
   docker images jobspy
   docker run --rm jobspy --version
   ```

3. **Test parameters manually:**
   ```bash
   docker run --rm jobspy --search_term "test" --location "remote" --results_wanted 1 --site_name "indeed"
   ```

4. **Check if ports are available:**
   ```bash
   lsof -i :9423  # Default SSE port
   ```

## 🆘 If All Else Fails

1. **Clean restart:**
   ```bash
   # Stop the server (Ctrl+C)
   # Remove Docker image
   docker rmi jobspy
   # Rebuild everything
   ./setup-and-start.sh
   ```

2. **Check system requirements:**
   - Docker Desktop running
   - Node.js 16+ installed
   - npm dependencies installed
   - Sufficient disk space for Docker images

3. **Alternative testing:**
   - Try running without Docker (if JobSpy supports it)
   - Test with minimal parameters first
   - Check Claude's MCP connection status