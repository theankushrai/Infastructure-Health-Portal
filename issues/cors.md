# CORS Issues

## Problem

Frontend cannot communicate with backend due to CORS (Cross-Origin Resource Sharing) errors.

## What is CORS?

When frontend and backend run on different origins:

- Frontend: `http://localhost:5173`
- Backend: `http://127.0.0.1:8000`

Browser blocks cross-origin requests by default for security.

## Solution

### Add CORS Middleware to FastAPI

In `backend/app/main.py`, add these imports:

```python
from fastapi.middleware.cors import CORSMiddleware
```

### Configure CORS Settings

After `app = FastAPI()`, add:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Restart FastAPI

```bash
# Stop the server (Ctrl+C)
# Restart
uvicorn app.main:app --reload
```

## Configuration Options

- `allow_origins`: Which frontend domains are allowed
- `allow_methods`: HTTP methods (GET, POST, etc.)
- `allow_headers`: Which headers are allowed
- `allow_credentials`: Allow cookies/auth headers

## Production Considerations

For production, use specific origins instead of wildcard:

```python
allow_origins=["https://yourdomain.com", "https://app.yourdomain.com"]
```

## Key Point

CORS is a **browser security feature**, not a backend bug. Fix it once at the API boundary.
