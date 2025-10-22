FROM node:20-alpine AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy package files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY tsconfig*.json ./
COPY vite*.ts ./
COPY tailwind.config.ts ./
COPY vite-env.d.ts ./

# Install Node.js dependencies
RUN pnpm install

# Copy source files
COPY src ./src
COPY build-all.mts ./

# Build the assets
RUN pnpm run build

# Python runtime stage
FROM python:3.11-slim

WORKDIR /app

# Copy built assets from builder stage
COPY --from=builder /app/assets ./assets

# Copy Python server files
COPY pizzaz_server_python ./pizzaz_server_python

# Install Python dependencies
RUN pip install --no-cache-dir -r pizzaz_server_python/requirements.txt

# Verify assets are in place
RUN ls -la /app/assets && echo "Assets directory contents verified"

# Expose port (Railway will set the PORT env var)
EXPOSE 8000

# Run the Python server from /app directory
# This ensures main.py can resolve assets at parent.parent/assets = /app/assets
CMD ["python", "pizzaz_server_python/main.py"]

