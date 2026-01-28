# syntax=docker/dockerfile:1.7

###############################################################################
# 1) deps (production dependencies only)
# - Installs ONLY prod deps into node_modules, using pnpm.
# - This is what we’ll copy into the final runtime image.
###############################################################################
FROM node:22-bookworm-slim AS deps
WORKDIR /app
# Enable pnpm via Corepack (bundled with recent Node)
RUN corepack enable
# Copy only manifests first for better caching
COPY package.json pnpm-lock.yaml ./
# Install production deps only
# BuildKit cache mount speeds up repeated installs
RUN --mount=type=cache,id=pnpm-store,target=/pnpm/store \
  pnpm config set store-dir /pnpm/store && \
  pnpm install --prod --frozen-lockfile

###############################################################################
# 2) build (dev dependencies + compile)
# - Installs all deps (including dev deps), then builds NestJS (ts->dist).
# - Keeps build tools isolated from runtime.
###############################################################################
FROM node:22-bookworm-slim AS build
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml ./
# Install all deps (dev + prod) needed to build
RUN --mount=type=cache,id=pnpm-store,target=/pnpm/store \
  pnpm config set store-dir /pnpm/store && \
  pnpm install --frozen-lockfile
# Copy source after deps for best caching
COPY . .
# Build NestJS (expects "build" script -> produces dist/)
RUN pnpm run build

###############################################################################
# 3) runtime (small, production-only)
# - Copies compiled output + prod node_modules only.
# - Uses distroless: smaller, fewer moving parts, no shell.
###############################################################################
FROM gcr.io/distroless/nodejs22-debian12 AS runtime
WORKDIR /app
# Production environment
ENV NODE_ENV=production
# Copy only what we need to run
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./package.json
# Distroless runs as non-root user 'nonroot' (UID 65532) by default
# Making it explicit for clarity and documentation
USER nonroot
# Expose the port (documentation only, actual binding happens in app)
EXPOSE 8257
# Distroless node image runs "node" as entrypoint,
# so we pass only the JS file path as CMD.
CMD ["dist/main.js"]
