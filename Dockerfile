# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Stage 1: build @trailprotocol/core from source.
# We never rely on a pre-built dist/ being present in the build context:
# trail-core's dist/ is a build artifact (gitignored in trail-did-method), so
# copying the package without building would ship an image whose
# "main": "dist/src/index.js" points at a missing file -> ERR_MODULE_NOT_FOUND
# at runtime. Building it here makes the image self-contained and reproducible.
# ---------------------------------------------------------------------------
FROM node:18-alpine AS core-build
WORKDIR /build

# Copy the local @trailprotocol/core source (README step:
#   cp -r ../trail-did-method/packages/trail-core ./trail-core)
COPY trail-core/ ./trail-core/

# Install devDeps (typescript) and compile to dist/, then pack a clean tarball
# that respects the package's "files" allowlist (dist/ only, no TS source, no
# node_modules). Pinned-version filename is normalised to core.tgz.
RUN cd trail-core \
    && npm install --no-audit --no-fund \
    && npm run build \
    && npm pack \
    && mv trailprotocol-core-*.tgz /build/core.tgz

# ---------------------------------------------------------------------------
# Stage 2: driver dependencies, installed against the freshly built tarball.
# ---------------------------------------------------------------------------
FROM node:18-alpine AS deps
WORKDIR /app

COPY package.json package-lock.json* ./
COPY --from=core-build /build/core.tgz ./core.tgz

# Point the @trailprotocol/core dependency at the local tarball so the install
# is hermetic (no npm-registry publish required, no host symlink).
RUN node -e " \
  const fs = require('fs'); \
  const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8')); \
  pkg.dependencies['@trailprotocol/core'] = 'file:./core.tgz'; \
  fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2)); \
"

RUN npm install --omit=dev --no-audit --no-fund

# ---------------------------------------------------------------------------
# Stage 3: minimal runtime image.
# ---------------------------------------------------------------------------
FROM node:18-alpine AS runtime

LABEL org.opencontainers.image.title="did:trail Universal Resolver Driver" \
      org.opencontainers.image.description="DIF Universal Resolver driver for the did:trail method" \
      org.opencontainers.image.source="https://github.com/trailprotocol/did-trail-universal-resolver-driver" \
      org.opencontainers.image.licenses="Apache-2.0"

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src/ ./src/

ENV PORT=8080
EXPOSE 8080

USER node

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://localhost:'+(process.env.PORT||8080)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "src/index.js"]
