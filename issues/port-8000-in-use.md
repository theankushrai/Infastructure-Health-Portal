# Port 8000 Already in Use

## Symptoms

- Error when trying to start the FastAPI server on port 8000
- Server fails to start with "Address already in use" error

## Quick Fix

### Windows (CMD/PowerShell)

```cmd
# Find process using port 8000
netstat -ano | findstr :8000

# Kill the process (replace 1234 with actual PID from above)
taskkill /PID 1234 /F

# Verify process is gone
tasklist | findstr 1234
```

### Linux/macOS

```bash
# Find process using port 8000
lsof -i :8000

# Kill the process (replace 1234 with actual PID from above)
kill -9 1234

# Alternative: Kill all processes on port 8000
fuser -k 8000/tcp
```

## Prevention

- Always stop services properly using Ctrl+C
- Use `docker-compose down` when stopping containers
- Consider using different ports for development and production
