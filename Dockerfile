FROM node:18-alpine

LABEL org.opencontainers.image.title="did:trail Universal Resolver Driver" \
      org.opencontainers.image.description="DIF Universal Resolver driver for the did:trail method" \
      org.opencontainers.image.source="https://github.com/trailprotocol/trail-did-method" \
      org.opencontainers.image.licenses="Apache-2.0"

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Copy the local @trailprotocol/core package
# The driver depends on it via "file:../trail-did-method/packages/trail-core"
# In Docker we copy it explicitly so the build is self-contained
COPY trail-core/ ./trail-core/

# Rewrite the dependency path to point at the copied directory
RUN node -e " \
  const fs = require('fs'); \
  const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8')); \
  pkg.dependencies['@trailprotocol/core'] = 'file:./trail-core'; \
  fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2)); \
"

RUN npm install --omit=dev

COPY src/ ./src/

ENV PORT=8080
EXPOSE 8080

USER node

CMD ["node", "src/index.js"]
