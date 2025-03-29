# syntax = docker/dockerfile:1

# Adjust NODE_VERSION as desired
ARG NODE_VERSION=20.18.3
FROM node:${NODE_VERSION}-slim AS base

LABEL fly_launch_runtime="Node.js"

# Node.js app lives here
WORKDIR /app

# Set production environment
ENV NODE_ENV="production"


# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build node modules
# Install packages needed to build node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential node-gyp pkg-config python-is-python3 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


# Install node modules
COPY package-lock.json package.json ./
RUN npm ci

# ✅ Install pg manually
RUN npm install pg

# Copy application code
COPY . .

# Build application
RUN npm run build

# Remove development dependencies
RUN npm prune --omit=dev


# Final stage for app image
FROM base

# Copy built application
COPY --from=build /app /app

# ✅ Ensure pg is present in the final stage
RUN npm install pg --omit=dev

# Start the server by default, this can be overwritten at runtime
EXPOSE 1337
CMD [ "npm", "run", "start" ]
