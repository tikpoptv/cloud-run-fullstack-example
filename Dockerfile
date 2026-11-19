# Stage 1: build the frontend with Node
FROM node:22-slim AS frontend
WORKDIR /fe
COPY frontend/ ./
RUN npm run build

# Stage 2: Python backend that also serves the built frontend
FROM python:3.12-slim
WORKDIR /app
COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ ./
COPY --from=frontend /fe/dist ./static

# Cloud Run sets PORT; gunicorn reads it automatically (default bind 0.0.0.0:$PORT).
ENV PORT=8080
CMD ["gunicorn", "--workers", "1", "--threads", "4", "app:app"]
