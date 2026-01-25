# Docker Multi-Stage Builds

## Overview

A **multi-stage build** lets you:

- Use heavy tools (Node, npm, compilers) to **build**
- **Exclude** them from the final image

Result:

```
Big, messy build environment ❌
Small, clean runtime image ✅
```

## Stage 1 - Build the React App

```dockerfile
FROM node:20-alpine AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . .
RUN npm run build
```

### What this does:

- Uses Node.js (Alpine = lightweight)
- Names this stage **`build`**
- Installs dependencies first (Docker layer caching)
- Copies source code and builds the app
- Creates `/app/dist` with optimized static files

## Stage 2 - Runtime (Nginx)

```dockerfile
FROM nginx:alpine

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### What this does:

- Starts a **new image** (Node image is gone)
- Copies only the built files from the `build` stage
- Exposes port 80 for web traffic
- Starts nginx in foreground

## Benefits

### ✅ Smaller image

- Node image: ~300MB+
- Final nginx image: ~25MB

### ✅ Better security

- No build tools in production
- Smaller attack surface

### ✅ Faster startup

- No runtime compilation
- Just static file serving

### ✅ Cleaner separation

- Build ≠ Runtime

## Mental Model

```
Stage 1 (Node)
- node
- npm
- node_modules
- source code
- build tools
        |
        |  (copy only dist)
        v
Stage 2 (Nginx)
- static files only
- tiny image
- fast startup
```

## TL;DR

This Dockerfile:

- Uses Node **only to build**
- Uses Nginx **only to serve**
- Ships **only the final static files**
- Produces a **small, secure, production-ready image**
