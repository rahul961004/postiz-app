# Dockerfile for Postiz on Render - Working Version
FROM node:22-alpine AS base

# Install dependencies
FROM base AS deps
RUN apk add --no-cache libc6-compat python3 make g++ openssl
WORKDIR /app

# Copy ALL source files FIRST (Prisma needs these for postinstall)
COPY . .

# Install dependencies - postinstall will generate Prisma client
RUN corepack enable pnpm && pnpm i --no-frozen-lockfile

# Build the application
FROM base AS builder
WORKDIR /app
COPY --from=deps /app ./

# Build
ENV NEXT_TELEMETRY_DISABLED=1
RUN corepack enable pnpm && pnpm build

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
RUN apk add --no-cache openssl

# Copy built application
COPY --from=builder /app ./

USER nextjs

EXPOSE 3000

ENV PORT=3000

CMD ["pnpm", "start"]
