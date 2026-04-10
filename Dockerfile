# -- Base stage --
ARG NODE_VERSION=lts-alpine
FROM node:${NODE_VERSION} AS base

# Set working directory and ownership
WORKDIR /app
RUN chown -R node:node /app
RUN npm install -g pnpm

# -- Dependencies stage --
FROM base AS deps

# Install production dependencies
COPY --chown=node:node package*.json ./

RUN pnpm install --prod

# -- Build dependencies --
FROM deps AS build-deps

RUN pnpm install

COPY --chown=node:node package*.json ./

# -- Build Stage -- 
FROM build-deps AS build

COPY --chown=node:node . .

RUN pnpm run build

RUN chown -R node:node /app

# -- Dev stage --
FROM build AS development

ENV NODE_ENV=development \
    NPM_CONFIG_LOGLEVEL=warn

COPY --chown=node:node . .

# Switch to non-root user
USER node

ENTRYPOINT [ "pnpm", "run", "dev" ]

# -- Prod stage --
ARG NODE_VERSION=24.11.1-alpine
FROM node:${NODE_VERSION} AS production

WORKDIR /app
RUN chown -R node:node /app

ENV NODE_ENV=production \
    NODE_OPTIONS="--max-old-space-size=256 --no-warnings" \
    NPM_CONFIG_LOGLEVEL=silent

COPY --from=deps --chown=node:node /app/package*.json ./
COPY --from=deps --chown=node:node /app/node_modules ./node_modules

USER node

EXPOSE 3000

ENTRYPOINT ["pnpm", "start"]

# -- Test stage --
FROM build-deps AS test

ENV NODE_ENV=test

COPY --chown=node:node . .

USER node

ENTRYPOINT ["pnpm", "run", "test"]
