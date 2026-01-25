Make backend wait for Mongo

Update your backend service:

backend:
build: ./backend
container_name: infra-health-backend
ports: - "8000:8000"
depends_on:
mongo:
condition: service_healthy

👉 Now:

Backend will start only after Mongo is ready

DNS + connection both work
