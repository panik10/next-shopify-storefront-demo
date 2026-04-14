### -- Base stage --
ARG NODE_VERSION=lts-alpine
FROM node:${NODE_VERSION} AS base

# Set working directory and ownership
WORKDIR /app
RUN chown -R node:node /app
RUN npm install -g pnpm

### -- Dependencies stage --
FROM base AS deps

# Install production dependencies
COPY --chown=node:node package*.json ./

RUN pnpm install --prod

### -- Build dependencies --
FROM deps AS build-deps

RUN pnpm install

COPY --chown=node:node package*.json ./

### -- Build Stage -- 
FROM build-deps AS build

COPY --chown=node:node . .
RUN --mount=type=secret,id=DOT_ENV,target=/app/.env \
    pnpm run build

RUN pnpm run build

RUN chown -R node:node /app

### -- Dev stage --
FROM build AS development

ENV NODE_ENV=development \
    NPM_CONFIG_LOGLEVEL=warn

COPY --chown=node:node . .

# Switch to non-root user
USER node

LABEL com.my-cool-aid-company.developer.name="panik10"

ENTRYPOINT [ "pnpm", "run", "dev" ]

### -- Prod stage --
FROM node:${NODE_VERSION} AS production

WORKDIR /app
RUN chown -R node:node /app

ENV NODE_ENV=production \
    NODE_OPTIONS="--max-old-space-size=256 --no-warnings" \
    NPM_CONFIG_LOGLEVEL=silent

COPY --from=deps --chown=node:node /app/package*.json ./
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/.next ./.next
COPY --from=build --chown=node:node /app/public ./public
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Switch to non-root user
USER node

EXPOSE 3000

ENTRYPOINT ["pnpm", "start"]

### -- Test stage --
FROM build-deps AS test

ENV NODE_ENV=test

COPY --chown=node:node . .

USER node

ENTRYPOINT ["pnpm", "run", "test"]
