# Stage 1: Build React application
FROM node:18-alpine AS builder

WORKDIR /app

# Copy dependency specifications
COPY package.json package-lock.json ./

# Install dependencies strictly from lockfile
RUN npm ci

# Build argument for API URL
ARG REACT_APP_MOVIE_API_URL=http://localhost:5000
ENV REACT_APP_MOVIE_API_URL=$REACT_APP_MOVIE_API_URL

# Copy source code and build
COPY . ./
RUN npm run build

# Stage 2: Serve static files with Nginx
FROM nginx:alpine

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy build artifacts from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]
