# syntax=docker/dockerfile:1

# ---- Stage 1: Dependencies ----
# Install production/build dependencies in isolation so this layer is cached
# and only re-run when lockfiles change.
FROM node:22-alpine AS deps
WORKDIR /app

# Install deterministically from the lockfile.
COPY package.json package-lock.json ./
RUN npm ci

# ---- Stage 2: Build ----
# Build the Next.js app. Relies on `output: "standalone"` in next.config.ts,
# which emits a self-contained app at .next/standalone.
FROM node:22-alpine AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Disable telemetry during the build.
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# ---- Stage 3: Runtime ----
# Minimal image that runs the standalone server. No node_modules install here;
# the standalone output already bundles what it needs.
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
# Bind to all interfaces so the container is reachable from the host.
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Run as a non-root user for a smaller attack surface.
RUN addgroup --system --gid 1001 nodejs \
  && adduser --system --uid 1001 nextjs

# Copy static assets and the standalone server output.
# standalone does NOT include public/ or .next/static by default, so copy them
# explicitly to their expected locations.
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

# The standalone build outputs server.js at the app root.
CMD ["node", "server.js"]
