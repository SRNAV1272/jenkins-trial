
# Stage 1: Build React application
FROM node:24-alpine AS builder

WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install dependencies using the lock file
RUN npm ci

# Copy application source
COPY . .

# Generate production React build
RUN npm run build


# Stage 2: Serve React using Nginx
FROM nginx:alpine

# Remove default Nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy React production build
COPY --from=builder /app/build /usr/share/nginx/html

# Expose HTTP port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
