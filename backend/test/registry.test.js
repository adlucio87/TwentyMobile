'use strict';

/**
 * Unit tests for the OAuth client registry core (`npm test`).
 *
 * They run with the Node test runner only — no Firebase emulator, no
 * `node_modules` — which is what lets `scripts/verify.sh --area backend` cover
 * the backend on every change.
 */

const assert = require('node:assert/strict');
const { describe, test } = require('node:test');

const {
  createRateLimiter,
  createRegistryHandler,
  extractHostname,
  interpretMetadataPayload,
  isAllowedHostname,
  isPrivateIp,
  isTeamApplicationName,
  normalizePath,
  resolvesToPublicIp,
  verifyClientOnTwenty,
} = require('../lib/registry');

const CLIENT_ID = '11111111-1111-4111-8111-111111111111';
const OTHER_CLIENT_ID = '22222222-2222-4222-8222-222222222222';

/** Minimal Firestore double exposing only what `createRegistryHandler` uses. */
function createFakeDb(initialDocs = {}) {
  const docs = new Map(Object.entries(initialDocs));
  const calls = { sets: [], deletes: [] };

  return {
    docs,
    calls,
    collection(name) {
      return {
        doc(id) {
          const key = `${name}/${id}`;
          return {
            async get() {
              const value = docs.get(key);
              return { exists: value !== undefined, data: () => value };
            },
            async set(payload, options) {
              const current = docs.get(key) || {};
              const merged =
                options && options.merge ? { ...current, ...payload } : { ...payload };
              docs.set(key, merged);
              calls.sets.push({ key, payload, options });
            },
            async delete() {
              docs.delete(key);
              calls.deletes.push(key);
            },
          };
        },
      };
    },
  };
}

/** `fetch` double recording every outbound call. */
function createFakeFetch(handler) {
  const calls = [];
  const impl = async (url, init) => {
    calls.push({ url, init });
    return handler(url, init, calls.length);
  };
  impl.calls = calls;
  return impl;
}

function metadataResponse(body) {
  return { ok: true, status: 200, json: async () => body };
}

function registeredApp(name = 'TwentyMobile') {
  return metadataResponse({
    data: { findApplicationRegistrationByClientId: { id: 'app-1', name } },
  });
}

function unknownApp() {
  return metadataResponse({
    data: { findApplicationRegistrationByClientId: null },
  });
}

function graphqlErrors() {
  return metadataResponse({
    errors: [{ message: 'Cannot query field "findApplicationRegistrationByClientId".' }],
  });
}

/** Public resolver: every hostname points at example.com's address. */
const publicResolver = async () => [{ address: '93.184.216.34', family: 4 }];

function createHandler({ db, fetchImpl, resolveHost, logger, config } = {}) {
  return createRegistryHandler({
    db: db || createFakeDb(),
    fetchImpl: fetchImpl || createFakeFetch(() => unknownApp()),
    resolveHost: resolveHost || publicResolver,
    now: () => Date.now(),
    logger: logger || { warn() {}, error() {} },
    config,
  });
}

describe('extractHostname', () => {
  test('normalizes URLs, bare hosts and ports', () => {
    assert.equal(extractHostname('https://CRM.Example.com/'), 'crm.example.com');
    assert.equal(extractHostname('  crm.example.com  '), 'crm.example.com');
    assert.equal(extractHostname('https://crm.example.com:8443/path'), 'crm.example.com');
  });

  test('returns null on unusable input', () => {
    assert.equal(extractHostname(undefined), null);
    assert.equal(extractHostname(42), null);
    assert.equal(extractHostname(''), null);
  });
});

describe('normalizePath', () => {
  test('collapses trailing slashes and query strings', () => {
    assert.equal(normalizePath('/api/oauth-client/'), '/api/oauth-client');
    assert.equal(normalizePath('/api/oauth-client?instance=x'), '/api/oauth-client');
    assert.equal(normalizePath('/'), '/');
    assert.equal(normalizePath(undefined), '/');
  });
});

describe('isAllowedHostname', () => {
  test('accepts public FQDNs', () => {
    assert.equal(isAllowedHostname('crm.acme.com'), true);
    assert.equal(isAllowedHostname('lucio.twenty.com'), true);
  });

  test('rejects localhost, IP literals and internal names', () => {
    ['localhost', 'localhost.localdomain', 'metadata.google.internal'].forEach((host) => {
      assert.equal(isAllowedHostname(host), false, host);
    });
    ['127.0.0.1', '10.0.0.5', '169.254.169.254', '2130706433'].forEach((host) => {
      assert.equal(isAllowedHostname(host), false, host);
    });
    ['crm.internal', 'crm.local', 'crm.corp', 'crm.lan', 'intranet', '1234567890.com'].forEach(
      (host) => {
        assert.equal(isAllowedHostname(host), false, host);
      },
    );
  });

  test('rejects malformed names', () => {
    ['crm..acme.com', '.crm.acme.com', 'crm.acme.com.', 'crm_acme.com', ''].forEach((host) => {
      assert.equal(isAllowedHostname(host), false, host);
    });
  });
});

describe('isPrivateIp', () => {
  test('flags loopback, private, link-local and CGNAT ranges', () => {
    ['127.0.0.1', '10.1.2.3', '172.16.0.1', '172.31.255.255', '192.168.1.1',
     '169.254.169.254', '100.64.0.1', '0.0.0.0', '::1', 'fe80::1', 'fd00::1',
     '::ffff:10.0.0.1'].forEach((ip) => {
      assert.equal(isPrivateIp(ip), true, ip);
    });
  });

  test('accepts public addresses', () => {
    ['93.184.216.34', '8.8.8.8', '172.32.0.1', '2606:4700::1111'].forEach((ip) => {
      assert.equal(isPrivateIp(ip), false, ip);
    });
  });
});

describe('resolvesToPublicIp', () => {
  test('returns false when any answer is private', async () => {
    const lookup = async () => [
      { address: '93.184.216.34', family: 4 },
      { address: '10.0.0.7', family: 4 },
    ];

    assert.equal(await resolvesToPublicIp('crm.acme.com', lookup), false);
  });

  test('returns false when resolution fails or returns nothing', async () => {
    assert.equal(
      await resolvesToPublicIp('crm.acme.com', async () => {
        throw new Error('ENOTFOUND');
      }),
      false,
    );
    assert.equal(await resolvesToPublicIp('crm.acme.com', async () => []), false);
  });

  test('accepts a single public record', async () => {
    assert.equal(
      await resolvesToPublicIp('crm.acme.com', async () => [
        { address: '93.184.216.34', family: 4 },
      ]),
      true,
    );
  });
});

describe('interpretMetadataPayload', () => {
  test('reports a registered application', () => {
    assert.deepEqual(
      interpretMetadataPayload({
        data: { findApplicationRegistrationByClientId: { id: 'a', name: 'TwentyMobile' } },
      }),
      { valid: true, appName: 'TwentyMobile' },
    );
  });

  test('only a null payload counts as a deleted application', () => {
    assert.deepEqual(
      interpretMetadataPayload({ data: { findApplicationRegistrationByClientId: null } }),
      { valid: false, reason: 'app_not_found' },
    );
  });

  test('a GraphQL error is never reported as a deleted application', () => {
    // Regression: Twenty answers HTTP 200 + `errors` on schema drift, and the
    // previous code purged a perfectly valid registry entry when that happened.
    assert.deepEqual(interpretMetadataPayload({ errors: [{ message: 'nope' }] }), {
      valid: false,
      error: 'graphql_error',
    });
    assert.deepEqual(interpretMetadataPayload({ data: null }), {
      valid: false,
      error: 'invalid_response',
    });
    assert.deepEqual(interpretMetadataPayload({ data: { somethingElse: 1 } }), {
      valid: false,
      error: 'unexpected_payload',
    });
  });

  test('a blank application name is reported as null', () => {
    assert.deepEqual(
      interpretMetadataPayload({
        data: { findApplicationRegistrationByClientId: { id: 'a', name: '   ' } },
      }),
      { valid: true, appName: null },
    );
  });
});

describe('verifyClientOnTwenty', () => {
  test('posts the public GraphQL query to /metadata over https', async () => {
    const fetchImpl = createFakeFetch(() => registeredApp('TwentyMobile'));

    const result = await verifyClientOnTwenty({
      hostname: 'crm.acme.com',
      clientId: CLIENT_ID,
      fetchImpl,
    });

    assert.deepEqual(result, { valid: true, appName: 'TwentyMobile' });
    assert.equal(fetchImpl.calls.length, 1);
    assert.equal(fetchImpl.calls[0].url, 'https://crm.acme.com/metadata');
    assert.equal(fetchImpl.calls[0].init.method, 'POST');
    assert.match(fetchImpl.calls[0].init.body, /findApplicationRegistrationByClientId/);
  });

  test('degrades to a coarse error code, never leaking the target status', async () => {
    const failing = createFakeFetch(() => ({ ok: false, status: 405, json: async () => ({}) }));
    const exploding = createFakeFetch(() => {
      throw new Error('ENOTFOUND');
    });
    const malformed = createFakeFetch(() => ({
      ok: true,
      status: 200,
      json: async () => {
        throw new Error('not json');
      },
    }));

    assert.deepEqual(
      await verifyClientOnTwenty({ hostname: 'a.com', clientId: CLIENT_ID, fetchImpl: failing }),
      { valid: false, error: 'http_error' },
    );
    assert.deepEqual(
      await verifyClientOnTwenty({ hostname: 'a.com', clientId: CLIENT_ID, fetchImpl: exploding }),
      { valid: false, error: 'network_error' },
    );
    assert.deepEqual(
      await verifyClientOnTwenty({ hostname: 'a.com', clientId: CLIENT_ID, fetchImpl: malformed }),
      { valid: false, error: 'invalid_response' },
    );
  });

  test('rejects an incomplete call without touching the network', async () => {
    const fetchImpl = createFakeFetch(() => registeredApp());

    assert.deepEqual(
      await verifyClientOnTwenty({ hostname: null, clientId: CLIENT_ID, fetchImpl }),
      { valid: false, error: 'invalid_request' },
    );
    assert.equal(fetchImpl.calls.length, 0);
  });
});

describe('isTeamApplicationName', () => {
  test('accepts the documented application names', () => {
    ['TwentyMobile', 'TwentyMobile CRM', 'twenty mobile', 'PocketCRM'].forEach((name) => {
      assert.equal(isTeamApplicationName(name), true, name);
    });
  });

  test('rejects anything else', () => {
    ['Marketing App', '', undefined, 'random-client'].forEach((name) => {
      assert.equal(isTeamApplicationName(name), false, String(name));
    });
  });
});

describe('createRateLimiter', () => {
  test('allows up to the limit then blocks within the window', () => {
    const limiter = createRateLimiter({ windowMs: 1000, max: 2 });
    const start = 1_000_000;

    assert.equal(limiter.allow('ip:1', start), true);
    assert.equal(limiter.allow('ip:1', start), true);
    assert.equal(limiter.allow('ip:1', start + 10), false);
    assert.equal(limiter.allow('ip:2', start + 10), true);
  });

  test('opens a new window after it expires', () => {
    const limiter = createRateLimiter({ windowMs: 1000, max: 1 });

    assert.equal(limiter.allow('ip:1', 0), true);
    assert.equal(limiter.allow('ip:1', 10), false);
    assert.equal(limiter.allow('ip:1', 1500), true);
  });
});

describe('createRegistryHandler', () => {
  /** Handler with a controllable clock (TTL and rate-limit windows). */
  function createTimedHandler({ db, fetchImpl, resolveHost, logger, config, now } = {}) {
    return createRegistryHandler({
      db: db || createFakeDb(),
      fetchImpl: fetchImpl || createFakeFetch(() => unknownApp()),
      resolveHost: resolveHost || publicResolver,
      now: now || (() => 1_000_000),
      logger: logger || { warn() {}, error() {} },
      config,
    });
  }

  describe('routing', () => {
    test('answers the health probe, with or without a trailing slash', async () => {
      const handle = createTimedHandler();

      const health = await handle({ method: 'GET', path: '/api/health' });
      assert.equal(health.status, 200);
      assert.equal(health.body.status, 'ok');
      assert.equal(health.headers['Cache-Control'], 'no-store');

      const slashed = await handle({ method: 'GET', path: '/api/health/' });
      assert.equal(slashed.status, 200);
    });

    test('answers 404 for unknown routes and 405 for unsupported methods', async () => {
      const handle = createTimedHandler();

      assert.equal((await handle({ method: 'GET', path: '/api/nope' })).status, 404);

      const notAllowed = await handle({ method: 'PUT', path: '/api/oauth-client' });
      assert.equal(notAllowed.status, 405);
      assert.equal(notAllowed.headers.Allow, 'GET, POST');
    });

    test('accepts the registry route with and without a path prefix', async () => {
      const handle = createTimedHandler();

      for (const path of ['/api/oauth-client', '/oauth-client', '/']) {
        const result = await handle({ method: 'GET', path, query: { instance: 'crm.acme.com' } });
        assert.equal(result.status, 200, path);
        assert.equal(result.body.exists, false, path);
      }
    });
  });

  describe('GET', () => {
    test('requires the instance parameter', async () => {
      const result = await createTimedHandler()({ method: 'GET', path: '/api/oauth-client' });

      assert.equal(result.status, 400);
      assert.equal(result.body.error, 'missing_instance');
    });

    test('reports an unregistered instance without calling it', async () => {
      const fetchImpl = createFakeFetch(() => registeredApp());
      const result = await createTimedHandler({ fetchImpl })({
        method: 'GET',
        path: '/api/oauth-client',
        query: { instance: 'https://crm.acme.com' },
      });

      assert.equal(result.status, 200);
      assert.deepEqual(result.body, { exists: false, instance: 'crm.acme.com' });
      assert.equal(fetchImpl.calls.length, 0);
    });

    test('serves a recently verified entry from the TTL cache', async () => {
      const db = createFakeDb({
        'oauth_clients/crm.acme.com': {
          clientId: CLIENT_ID,
          appName: 'TwentyMobile',
          verifiedAt: 1_000_000 - 1000,
        },
      });
      const fetchImpl = createFakeFetch(() => registeredApp());

      const result = await createTimedHandler({ db, fetchImpl })({
        method: 'GET',
        path: '/api/oauth-client',
        query: { instance: 'crm.acme.com' },
      });

      assert.equal(result.body.verified, true);
      assert.equal(result.body.cached, true);
      assert.equal(result.body.clientId, CLIENT_ID);
      assert.equal(fetchImpl.calls.length, 0);
    });

    test('re-verifies an expired entry and refreshes verifiedAt', async () => {
      const db = createFakeDb({
        'oauth_clients/crm.acme.com': {
          clientId: CLIENT_ID,
          appName: 'TwentyMobile',
          verifiedAt: 0,
        },
      });
      const fetchImpl = createFakeFetch(() => registeredApp('TwentyMobile'));

      const result = await createTimedHandler({ db, fetchImpl })({
        method: 'GET',
        path: '/api/oauth-client',
        query: { instance: 'crm.acme.com' },
      });

      assert.equal(result.body.verified, true);
      assert.equal(fetchImpl.calls.length, 1);
      assert.equal(db.docs.get('oauth_clients/crm.acme.com').verifiedAt, 1_000_000);
    });

    test('keeps the entry when the instance answers with GraphQL errors', async () => {
      // Regression: schema drift must never trigger the self-healing purge.
      const db = createFakeDb({
        'oauth_clients/crm.acme.com': {
          clientId: CLIENT_ID,
          appName: 'TwentyMobile',
          verifiedAt: 0,
        },
      });
      const fetchImpl = createFakeFetch(() => graphqlErrors());

      const result = await createTimedHandler({ db, fetchImpl })({
        method: 'GET',
        path: '/api/oauth-client',
        query: { instance: 'crm.acme.com' },
      });

      assert.equal(result.status, 200);
      assert.equal(result.body.exists, true);
      assert.equal(result.body.verified, false);
      assert.equal(result.body.clientId, CLIENT_ID);
      assert.deepEqual(db.calls.deletes, []);
      assert.equal(db.docs.has('oauth_clients/crm.acme.com'), true);
    });

    test('purges the entry only when the application was really deleted', async () => {
      const db = createFakeDb({
        'oauth_clients/crm.acme.com': {
          clientId: CLIENT_ID,
          appName: 'TwentyMobile',
          verifiedAt: 0,
        },
      });
      const fetchImpl = createFakeFetch(() => unknownApp());

      const result = await createTimedHandler({ db, fetchImpl })({
        method: 'GET',
        path: '/api/oauth-client',
        query: { instance: 'crm.acme.com' },
      });

      assert.equal(result.body.exists, false);
      assert.equal(result.body.reason, 'app_deleted_on_instance');
      assert.deepEqual(db.calls.deletes, ['oauth_clients/crm.acme.com']);
    });

    test('drops an incomplete record', async () => {
      const db = createFakeDb({ 'oauth_clients/crm.acme.com': { appName: 'x' } });

      const result = await createTimedHandler({ db })({
        method: 'GET',
        path: '/api/oauth-client',
        query: { instance: 'crm.acme.com' },
      });

      assert.equal(result.body.exists, false);
      assert.equal(result.body.reason, 'incomplete_record');
      assert.deepEqual(db.calls.deletes, ['oauth_clients/crm.acme.com']);
    });

    test('never calls a host that fails the SSRF guard or resolves privately', async () => {
      const fetchImpl = createFakeFetch(() => registeredApp());
      const legacyDb = createFakeDb({
        'oauth_clients/crm.internal': { clientId: CLIENT_ID, verifiedAt: 0 },
      });

      const blocked = await createTimedHandler({ db: legacyDb, fetchImpl })({
        method: 'GET',
        path: '/api/oauth-client',
        query: { instance: 'crm.internal' },
      });

      assert.equal(blocked.body.verified, false);
      assert.equal(blocked.body.clientId, CLIENT_ID);
      assert.equal(fetchImpl.calls.length, 0);

      const privateDb = createFakeDb({
        'oauth_clients/crm.acme.com': { clientId: CLIENT_ID, verifiedAt: 0 },
      });
      const privateResult = await createTimedHandler({
        db: privateDb,
        fetchImpl,
        resolveHost: async () => [{ address: '10.0.0.9', family: 4 }],
      })({ method: 'GET', path: '/api/oauth-client', query: { instance: 'crm.acme.com' } });

      assert.equal(privateResult.body.verified, false);
      assert.equal(fetchImpl.calls.length, 0);
    });
  });

  describe('POST', () => {
    function postRequest(body, ip = '1.2.3.4') {
      return { method: 'POST', path: '/api/oauth-client', body, ip };
    }

    test('rejects a missing or malformed payload', async () => {
      const handle = createTimedHandler();

      const missing = await handle(postRequest({}));
      assert.equal(missing.status, 400);
      assert.equal(missing.body.error, 'invalid_payload');

      const notUuid = await handle(
        postRequest({ instance: 'crm.acme.com', clientId: 'not-a-uuid' }),
      );
      assert.equal(notUuid.status, 400);
      assert.equal(notUuid.body.error, 'invalid_client_id_format');
    });

    test('refuses internal hostnames without any outbound call', async () => {
      const fetchImpl = createFakeFetch(() => registeredApp());
      const handle = createTimedHandler({ fetchImpl });

      const internal = await handle(postRequest({ instance: 'crm.internal', clientId: CLIENT_ID }));
      assert.equal(internal.status, 400);
      assert.equal(internal.body.error, 'invalid_instance');

      const literal = await handle(
        postRequest({ instance: 'http://169.254.169.254', clientId: CLIENT_ID }),
      );
      assert.equal(literal.status, 400);
      assert.equal(literal.body.error, 'invalid_instance');

      const privateDns = await createTimedHandler({
        fetchImpl,
        resolveHost: async () => [{ address: '10.1.2.3', family: 4 }],
      })(postRequest({ instance: 'crm.acme.com', clientId: CLIENT_ID }));
      assert.equal(privateDns.status, 400);
      assert.equal(privateDns.body.error, 'invalid_instance');

      assert.equal(fetchImpl.calls.length, 0);
    });

    test('refuses a client id the instance does not know', async () => {
      const handle = createTimedHandler({ fetchImpl: createFakeFetch(() => unknownApp()) });

      const result = await handle(postRequest({ instance: 'crm.acme.com', clientId: CLIENT_ID }));

      assert.equal(result.status, 400);
      assert.equal(result.body.error, 'client_id_verification_failed');
      assert.equal(result.body.details, 'app_not_found');
    });

    test('never echoes the target status when the instance is unreachable', async () => {
      // Previously `details` was "HTTP 405": the status of an arbitrary host the
      // caller picked, turned into an SSRF probe primitive.
      const handle = createTimedHandler({
        fetchImpl: createFakeFetch(() => ({ ok: false, status: 405, json: async () => ({}) })),
      });

      const result = await handle(postRequest({ instance: 'crm.acme.com', clientId: CLIENT_ID }));

      assert.equal(result.status, 400);
      assert.equal(result.body.details, 'verification_unavailable');
      assert.doesNotMatch(JSON.stringify(result.body), /405/);
    });

    test('refuses to share an unrelated application', async () => {
      const db = createFakeDb();
      const handle = createTimedHandler({
        db,
        fetchImpl: createFakeFetch(() => registeredApp('Marketing App')),
      });

      const result = await handle(postRequest({ instance: 'crm.acme.com', clientId: CLIENT_ID }));

      assert.equal(result.status, 409);
      assert.equal(result.body.error, 'app_name_not_shareable');
      assert.equal(db.calls.sets.length, 0);
      assert.equal(db.docs.size, 0);
    });

    test('registers a verified team application', async () => {
      const db = createFakeDb();
      const handle = createTimedHandler({
        db,
        fetchImpl: createFakeFetch(() => registeredApp('TwentyMobile')),
      });

      const result = await handle(
        postRequest({ instance: 'https://crm.acme.com/', clientId: CLIENT_ID }),
      );

      assert.equal(result.status, 200);
      assert.equal(result.body.success, true);
      assert.equal(result.body.instance, 'crm.acme.com');
      assert.equal(result.body.overwritten, false);

      const stored = db.docs.get('oauth_clients/crm.acme.com');
      assert.equal(stored.clientId, CLIENT_ID);
      assert.equal(stored.appName, 'TwentyMobile');
      assert.equal(stored.instanceUrl, 'https://crm.acme.com');
      assert.equal(stored.verifiedAt, 1_000_000);
      assert.deepEqual(stored.previousClientIds, []);
    });

    test('keeps the overwritten client id in an audit trail', async () => {
      const db = createFakeDb({
        'oauth_clients/crm.acme.com': { clientId: OTHER_CLIENT_ID, appName: 'TwentyMobile' },
      });
      const warnings = [];
      const handle = createTimedHandler({
        db,
        fetchImpl: createFakeFetch(() => registeredApp('TwentyMobile')),
        logger: { warn: (event) => warnings.push(event), error() {} },
      });

      const result = await handle(postRequest({ instance: 'crm.acme.com', clientId: CLIENT_ID }));

      assert.equal(result.body.overwritten, true);
      assert.deepEqual(db.docs.get('oauth_clients/crm.acme.com').previousClientIds, [
        OTHER_CLIENT_ID,
      ]);
      assert.deepEqual(warnings, ['oauth_registry_entry_overwritten']);
    });

    test('rate limits abusive callers', async () => {
      const handle = createTimedHandler({
        fetchImpl: createFakeFetch(() => registeredApp('TwentyMobile')),
        config: { postRateLimit: { windowMs: 60000, max: 2 } },
      });

      const request = postRequest({ instance: 'crm.acme.com', clientId: CLIENT_ID });
      assert.equal((await handle(request)).status, 200);
      assert.equal((await handle(request)).status, 200);

      const limited = await handle(request);
      assert.equal(limited.status, 429);
      assert.equal(limited.body.error, 'rate_limited');
      assert.equal(limited.headers['Retry-After'], '60');
    });

    test('rate limits registrations per instance, whoever is asking', async () => {
      const handle = createTimedHandler({
        fetchImpl: createFakeFetch(() => registeredApp('TwentyMobile')),
        config: { postPerInstanceRateLimit: { windowMs: 60000, max: 1 } },
      });

      const body = { instance: 'crm.acme.com', clientId: CLIENT_ID };
      assert.equal((await handle(postRequest(body, '1.1.1.1'))).status, 200);
      assert.equal((await handle(postRequest(body, '2.2.2.2'))).status, 429);
    });
  });

  test('rate limits GET lookups per caller', async () => {
    const handle = createTimedHandler({ config: { getRateLimit: { windowMs: 60000, max: 1 } } });

    const request = {
      method: 'GET',
      path: '/api/oauth-client',
      query: { instance: 'crm.acme.com' },
      ip: '9.9.9.9',
    };
    assert.equal((await handle(request)).status, 200);

    const limited = await handle(request);
    assert.equal(limited.status, 429);
    assert.equal(limited.headers['Retry-After'], '60');
  });
});
