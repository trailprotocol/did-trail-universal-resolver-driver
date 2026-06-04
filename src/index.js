import express from 'express';
import { TrailResolver } from '@trailprotocol/core';

const PORT = process.env.PORT || 8080;
const REGISTRY_ENDPOINT = process.env.TRAIL_REGISTRY_ENDPOINT;

const resolver = new TrailResolver({
  registryEndpoint: REGISTRY_ENDPOINT,
});

const app = express();
app.use(express.json());

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', driver: 'did-trail', version: '0.1.0' });
});

// DIF Universal Resolver API - W3C DID Resolution
// Spec: https://w3c-ccg.github.io/did-resolution/
app.get('/1.0/identifiers/:did(*)', async (req, res) => {
  const did = req.params.did;

  if (!did.startsWith('did:trail:')) {
    return res.status(400).json({
      didDocument: null,
      didDocumentMetadata: {},
      didResolutionMetadata: {
        error: 'invalidDid',
        errorMessage: `DID must start with did:trail:, got: ${did}`,
      },
    });
  }

  try {
    const result = await resolver.resolve(did);

    // Ensure didResolutionMetadata carries the contentType required by the spec
    const response = {
      '@context': 'https://w3id.org/did-resolution/v1',
      didDocument: result.didDocument,
      didDocumentMetadata: result.didDocumentMetadata ?? {},
      didResolutionMetadata: {
        contentType: 'application/did+ld+json',
        ...result.didResolutionMetadata,
      },
    };

    res
      .set('Content-Type', 'application/ld+json;profile="https://w3id.org/did-resolution"')
      .status(200)
      .json(response);
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    const notFound = message.toLowerCase().includes('not found') ||
                     message.toLowerCase().includes('invalid');

    res.status(notFound ? 404 : 500).json({
      '@context': 'https://w3id.org/did-resolution/v1',
      didDocument: null,
      didDocumentMetadata: {},
      didResolutionMetadata: {
        error: notFound ? 'notFound' : 'internalError',
        errorMessage: message,
      },
    });
  }
});

app.listen(PORT, () => {
  console.log(`did:trail Universal Resolver Driver listening on port ${PORT}`);
  if (REGISTRY_ENDPOINT) {
    console.log(`Registry endpoint: ${REGISTRY_ENDPOINT}`);
  } else {
    console.log('No registry endpoint - self-mode DIDs only');
  }
});
