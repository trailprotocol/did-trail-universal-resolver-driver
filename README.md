# did:trail Universal Resolver Driver

A [DIF Universal Resolver](https://github.com/decentralized-identity/universal-resolver) driver for the **did:trail** method.

- DID Method Spec: https://trailprotocol.org
- Method: `did:trail`
- Driver Image: build locally via Docker (see [Docker](#docker)). A prebuilt
  `ghcr.io/trailprotocol/did-trail-universal-resolver-driver` image is in preparation.

---

## Quick Start (local)

```bash
# Install dependencies
npm install

# Run the driver
npm start
# Listening on http://localhost:8080

# Test with a self-mode DID
curl http://localhost:8080/1.0/identifiers/did:trail:self:z6MknrHzRBzm3CJ3FhiNfmKJriSmtTZB3HbUEZ3NqQveFHJW
```

---

## API

### `GET /1.0/identifiers/{did}`

Resolves a `did:trail` DID and returns a W3C DID Resolution Result.

**Request**

```
GET /1.0/identifiers/did:trail:self:z6Mk...
```

**Response** - `200 OK`

```json
{
  "@context": "https://w3id.org/did-resolution/v1",
  "didDocument": {
    "@context": [
      "https://www.w3.org/ns/did/v1",
      "https://trailprotocol.org/ns/did/v1"
    ],
    "id": "did:trail:self:z6Mk...",
    "trail:trailMode": "self-signed",
    "trail:trailTrustTier": 0,
    "verificationMethod": [...],
    "authentication": [...],
    "assertionMethod": [...]
  },
  "didDocumentMetadata": {
    "created": "2026-04-21T...",
    "deactivated": false,
    "trailTrustTier": 0
  },
  "didResolutionMetadata": {
    "contentType": "application/did+ld+json"
  }
}
```

**Error** - `404 Not Found`

```json
{
  "@context": "https://w3id.org/did-resolution/v1",
  "didDocument": null,
  "didDocumentMetadata": {},
  "didResolutionMetadata": {
    "error": "notFound",
    "errorMessage": "..."
  }
}
```

### `GET /health`

Returns `{ "status": "ok", "driver": "did-trail", "version": "0.1.0" }`.

---

## DID Modes Supported

| Mode | Example | Resolution |
|------|---------|------------|
| `self` | `did:trail:self:<multibase-pubkey>` | Local - no registry required |
| `org` / `agent` | `did:trail:<hash>` | Requires `TRAIL_REGISTRY_ENDPOINT` env var |

---

## Docker

### Build

```bash
# Copy @trailprotocol/core into the build context first
cp -r ../trail-did-method/packages/trail-core ./trail-core

docker build -t did-trail-driver .
docker run -p 8080:8080 did-trail-driver
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | HTTP port |
| `TRAIL_REGISTRY_ENDPOINT` | _(unset)_ | TRAIL Registry URL for org/agent-mode DIDs |

---

## Integration with Universal Resolver

Add the driver to the Universal Resolver by following these steps:

### 1. `application.yml`

Add the snippet from `config/application.yml` under the `drivers:` key.

### 2. `docker-compose.yml`

Add the service from `config/docker-compose.yml`.

### 3. Submit a PR

Target repo: https://github.com/decentralized-identity/universal-resolver

The driver must pass the Universal Resolver test suite before the PR is merged.

---

## Development

```bash
npm run dev   # node --watch for live reload
```

---

## License

Apache-2.0 - see [LICENSE](https://github.com/trailprotocol/trail-did-method/blob/main/LICENSE)
