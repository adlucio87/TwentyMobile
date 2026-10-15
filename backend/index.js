'use strict';

/**
 * `firebase-functions` adapter for the TwentyMobile OAuth client registry.
 *
 * Every rule (SSRF guard, GraphQL interpretation, self-healing, rate limits)
 * lives in `./lib/registry.js`, which is pure and unit-tested (`npm test`).
 * This file only wires the platform in: Firestore, `fetch`, DNS, the clock,
 * CORS and the Hosting rewrite (`/api/**` → this function, see firebase.json).
 */

const dns = require('node:dns/promises');

const cors = require('cors');
const admin = require('firebase-admin');
const { onRequest } = require('firebase-functions/v2/https');

const { createRegistryHandler } = require('./lib/registry');

// Application Default Credentials: no secret is ever committed (see README).
admin.initializeApp();
const db = admin.firestore();

/**
 * CORS only matters for browser callers: native iOS/Android clients send no
 * `Origin` header and are never subject to CORS. Keeping the list narrow stops
 * an unrelated web page from probing the registry.
 *
 * Override with `OAUTH_REGISTRY_ALLOWED_ORIGINS=https://a.example,https://b.example`.
 */
const allowedOrigins = (
  process.env.OAUTH_REGISTRY_ALLOWED_ORIGINS ||
  'https://twentymobilecrm.luciosoft.it,https://luciosoft-twentymobilecrm.web.app'
)
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

const corsMiddleware = cors({
  origin(origin, callback) {
    // No Origin: curl, the mobile app, server-to-server.
    if (!origin) return callback(null, true);
    return callback(null, allowedOrigins.includes(origin));
  },
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type'],
  maxAge: 600,
});

/** Positive integer from the environment, or undefined. */
function positiveIntFromEnv(name) {
  const parsed = Number.parseInt(process.env[name] || '', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined;
}

const config = {};
const verifyTimeoutMs = positiveIntFromEnv('OAUTH_REGISTRY_VERIFY_TIMEOUT_MS');
if (verifyTimeoutMs) config.verificationTimeoutMs = verifyTimeoutMs;
const verifyTtlSeconds = positiveIntFromEnv('OAUTH_REGISTRY_VERIFY_TTL_SECONDS');
if (verifyTtlSeconds) config.verificationTtlMs = verifyTtlSeconds * 1000;

/** Caller address used by the in-memory rate limiter (never persisted). */
function clientIp(req) {
  const forwarded = req.headers ? req.headers['x-forwarded-for'] : null;
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.ip || 'unknown';
}

const handleRegistryRequest = createRegistryHandler({
  db,
  fetchImpl: (url, init) => fetch(url, init),
  resolveHost: (hostname, options) => dns.lookup(hostname, options),
  now: () => Date.now(),
  logger: console,
  config,
});

/**
 * Cloud Function: `oauthRegistry`
 *  - `GET  /api/oauth-client?instance=…` → shared client id (with liveness check)
 *  - `POST /api/oauth-client`            → validates + registers a client id
 *  - `GET  /api/health`                  → readiness probe
 */
exports.oauthRegistry = onRequest(
  {
    region: 'europe-west1',
    maxInstances: 10,
  },
  (req, res) => {
    corsMiddleware(req, res, async () => {
      const result = await handleRegistryRequest({
        method: req.method,
        path: req.path,
        query: req.query,
        body: req.body,
        ip: clientIp(req),
      });

      res.status(result.status);
      Object.entries(result.headers || {}).forEach(([name, value]) => {
        res.set(name, value);
      });
      res.json(result.body);
    });
  },
);
