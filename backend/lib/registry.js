'use strict';

/**
 * Pure, dependency-free core of the TwentyMobile OAuth client registry.
 *
 * Everything that must be reasoned about (and unit-tested) lives here:
 *
 *  * hostname normalisation + validation, which doubles as the **SSRF guard**
 *    for the outbound `https://<hostname>/metadata` call;
 *  * the interpretation of Twenty's GraphQL answer, where a GraphQL `errors`
 *    payload must never be mistaken for "the application was deleted";
 *  * a small in-memory rate limiter (the endpoint is public and unauthenticated
 *    by design: native mobile clients cannot keep a secret);
 *  * the whole HTTP contract via [createRegistryHandler].
 *
 * `backend/index.js` is only the `firebase-functions` adapter: it injects
 * Firestore, `fetch`, the DNS resolver and the clock. Keeping the rules here is
 * what makes them testable without the Firebase emulator (`npm test`, wired
 * into `scripts/verify.sh --area backend`).
 *
 * Collaborators expected by [createRegistryHandler] (the documented slice of
 * `admin.firestore()`, so tests can pass a tiny fake):
 *
 *   db.collection(name).doc(id).get()             -> { exists, data() }
 *   db.collection(name).doc(id).set(payload, { merge })
 *   db.collection(name).doc(id).delete()
 */

/** Firestore collection holding one document per instance hostname. */
const COLLECTION = 'oauth_clients';

/** Path reached on the Twenty instance to prove a client id exists. */
const METADATA_PATH = '/metadata';

/** Routes served by the function (normalised, without trailing slash). */
const HEALTH_PATHS = new Set(['/api/health', '/health']);
const REGISTRY_PATHS = new Set(['/api/oauth-client', '/oauth-client', '/']);

/** `client_id`s issued by Twenty are UUIDs. */
const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

/** Public GraphQL query used as the liveness check (works unauthenticated). */
const VERIFY_QUERY = `
    query VerifyApp($clientId: String!) {
      findApplicationRegistrationByClientId(clientId: $clientId) {
        id
        name
      }
    }
  `;

const DEFAULT_CONFIG = {
  /** Hard cap for the outbound verification (the mobile client waits 8s). */
  verificationTimeoutMs: 3000,
  /** How long a successful verification is trusted before re-checking. */
  verificationTtlMs: 5 * 60 * 1000,
  /** Requests/min allowed per caller IP. */
  getRateLimit: { windowMs: 60 * 1000, max: 60 },
  postRateLimit: { windowMs: 60 * 1000, max: 10 },
  /** Registrations/min allowed per target instance. */
  postPerInstanceRateLimit: { windowMs: 60 * 1000, max: 5 },
  /** Number of previous client ids kept per instance for auditability. */
  maxClientHistory: 5,
};

// ---------------------------------------------------------------------------
// Hostnames
// ---------------------------------------------------------------------------

/**
 * Normalizes an instance URL to a clean hostname (e.g. "lucio.twenty.com").
 * Returns null when the input cannot be parsed.
 */
function extractHostname(inputUrl) {
  if (!inputUrl || typeof inputUrl !== 'string') return null;
  let trimmed = inputUrl.trim();
  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    trimmed = 'https://' + trimmed;
  }
  try {
    const parsed = new URL(trimmed);
    return parsed.hostname.toLowerCase() || null;
  } catch {
    return null;
  }
}

/** Hostnames that must never be reachable from the function. */
const BLOCKED_HOSTNAMES = new Set([
  'localhost',
  'localhost.localdomain',
  'metadata.google.internal',
  'metadata.goog',
]);

/** Suffixes reserved for internal/special-use names (RFC 6761/6762/8375). */
const BLOCKED_HOST_SUFFIXES = [
  '.local',
  '.localhost',
  '.internal',
  '.home',
  '.home.arpa',
  '.corp',
  '.lan',
  '.intranet',
  '.test',
  '.invalid',
  '.example',
  '.onion',
  '.in-addr.arpa',
  '.ip6.arpa',
];

/** True for IPv4/IPv6 literals and numeric shorthand (e.g. 2130706433). */
function isIpLiteral(host) {
  if (host.includes(':')) return true;
  if (/^\d{1,3}(\.\d{1,3}){3}$/.test(host)) return true;
  if (/^\d+$/.test(host)) return true;
  if (/^0x[0-9a-f]+$/i.test(host)) return true;
  return false;
}

/** True for loopback, link-local, private, CGNAT and reserved addresses. */
function isPrivateIp(address) {
  if (typeof address !== 'string' || address.length === 0) return true;

  if (address.includes(':')) {
    const ip = address.toLowerCase().split('%')[0];
    if (ip.startsWith('::ffff:')) return isPrivateIp(ip.slice(7));
    if (ip === '::' || ip === '::1') return true;
    if (/^fe[89ab]/.test(ip)) return true; // fe80::/10 link-local
    if (/^f[cd]/.test(ip)) return true; // fc00::/7 unique local
    if (ip.startsWith('ff')) return true; // multicast
    return false;
  }

  const parts = address.split('.').map((part) => Number(part));
  if (parts.length !== 4 || parts.some((n) => !Number.isInteger(n) || n < 0 || n > 255)) {
    return true;
  }
  const [a, b] = parts;
  if (a === 0 || a === 10 || a === 127) return true;
  if (a === 169 && b === 254) return true; // link-local / cloud metadata
  if (a === 172 && b >= 16 && b <= 31) return true;
  if (a === 192 && b === 168) return true;
  if (a === 100 && b >= 64 && b <= 127) return true; // CGNAT 100.64/10
  if (a === 192 && b === 0) return true; // 192.0.0.0/24 + 192.0.2.0/24
  if (a === 198 && (b === 18 || b === 19)) return true; // benchmarking
  if (a >= 224) return true; // multicast + reserved
  return false;
}

/**
 * Static (no DNS) validation of a hostname a caller wants us to fetch.
 *
 * Deliberately strict: a bare LAN name, an IP literal or a `.internal` domain
 * cannot be a Twenty instance reachable from Cloud Functions, and letting them
 * through would turn this endpoint into a public SSRF probe.
 */
function isAllowedHostname(hostname) {
  if (!hostname || typeof hostname !== 'string') return false;
  if (hostname.length > 253) return false;
  if (BLOCKED_HOSTNAMES.has(hostname)) return false;
  if (isIpLiteral(hostname)) return false;
  if (!/^[a-z0-9.-]+$/.test(hostname)) return false;
  if (!hostname.includes('.')) return false; // require an FQDN
  if (hostname.startsWith('.') || hostname.endsWith('.') || hostname.includes('..')) {
    return false;
  }
  if (BLOCKED_HOST_SUFFIXES.some((suffix) => hostname.endsWith(suffix))) {
    return false;
  }
  // An all-digits label would still let a provider resolve it to an address.
  return hostname.split('.').every((label) => !/^\d+$/.test(label));
}

/**
 * Resolves [hostname] and refuses anything pointing at a non-public address:
 * DNS-based rebinding protection on top of [isAllowedHostname].
 */
async function resolvesToPublicIp(hostname, lookup) {
  try {
    const records = await lookup(hostname, { all: true });
    const list = Array.isArray(records) ? records : [records];
    const addresses = list
      .map((record) => (record ? String(record.address || '') : ''))
      .filter((address) => address.length > 0);
    if (addresses.length === 0) return false;
    return addresses.every((address) => !isPrivateIp(address));
  } catch {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Twenty metadata verification
// ---------------------------------------------------------------------------

/**
 * Turns a `/metadata` GraphQL answer into a verdict.
 *
 * A GraphQL `errors` payload is returned by Twenty with HTTP 200 whenever the
 * query does not match the running version's schema. Treating it as
 * `app_not_found` used to make the GET route purge perfectly valid registry
 * entries, so the distinction is explicit here.
 */
function interpretMetadataPayload(payload) {
  if (!payload || typeof payload !== 'object') {
    return { valid: false, error: 'invalid_response' };
  }
  if (Array.isArray(payload.errors) && payload.errors.length > 0) {
    return { valid: false, error: 'graphql_error' };
  }
  const data = payload.data;
  if (!data || typeof data !== 'object') {
    return { valid: false, error: 'invalid_response' };
  }
  if (!Object.prototype.hasOwnProperty.call(data, 'findApplicationRegistrationByClientId')) {
    return { valid: false, error: 'unexpected_payload' };
  }

  const application = data.findApplicationRegistrationByClientId;
  if (application && application.id) {
    const name =
      typeof application.name === 'string' && application.name.trim()
        ? application.name.trim()
        : null;
    return { valid: true, appName: name };
  }
  return { valid: false, reason: 'app_not_found' };
}

/**
 * Asks the Twenty instance whether [clientId] still exists.
 *
 * Never throws, and never returns the target's HTTP status: the verdict is
 * coarse on purpose so the endpoint cannot be used to probe third-party hosts.
 */
async function verifyClientOnTwenty({
  hostname,
  clientId,
  fetchImpl,
  timeoutMs = DEFAULT_CONFIG.verificationTimeoutMs,
}) {
  if (!hostname || !clientId) return { valid: false, error: 'invalid_request' };

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetchImpl(`https://${hostname}${METADATA_PATH}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'TwentyMobile-Registry/1.0',
      },
      body: JSON.stringify({ query: VERIFY_QUERY, variables: { clientId } }),
      signal: controller.signal,
    });

    if (!response || !response.ok) return { valid: false, error: 'http_error' };

    let payload;
    try {
      payload = await response.json();
    } catch {
      return { valid: false, error: 'invalid_response' };
    }
    return interpretMetadataPayload(payload);
  } catch {
    return { valid: false, error: 'network_error' };
  } finally {
    clearTimeout(timeoutId);
  }
}

/**
 * Only applications created by TwentyMobile (dynamic registration) or named as
 * documented in the README may be shared with teammates: it keeps an unrelated
 * application — and therefore a hijack of the shared client id — out of the
 * registry.
 */
function isTeamApplicationName(appName) {
  if (typeof appName !== 'string') return false;
  const normalized = appName.toLowerCase().replace(/[^a-z0-9]/g, '');
  return normalized.includes('twentymobile') || normalized.includes('pocketcrm');
}

// ---------------------------------------------------------------------------
// Rate limiting
// ---------------------------------------------------------------------------

/**
 * Tiny fixed-window limiter kept in memory.
 *
 * Cloud Functions scale out, so this is per instance: a cheap abuse brake for
 * the worst offenders (and for hostname enumeration), not a global quota.
 */
function createRateLimiter({ windowMs, max, maxKeys = 5000 } = {}) {
  const buckets = new Map();

  return {
    allow(key, now = Date.now()) {
      if (!key) return true;
      const bucket = buckets.get(key);
      if (!bucket || now - bucket.start >= windowMs) {
        if (buckets.size >= maxKeys) {
          for (const [existingKey, existing] of buckets) {
            if (now - existing.start >= windowMs) buckets.delete(existingKey);
          }
          if (buckets.size >= maxKeys) {
            // Still full: drop the oldest window instead of growing unbounded.
            buckets.delete(buckets.keys().next().value);
          }
        }
        buckets.set(key, { start: now, count: 1 });
        return true;
      }
      bucket.count += 1;
      return bucket.count <= max;
    },
    size: () => buckets.size,
    reset: () => buckets.clear(),
  };
}

// ---------------------------------------------------------------------------
// HTTP contract
// ---------------------------------------------------------------------------

/** Collapses a path to the form used by the route tables. */
function normalizePath(path) {
  if (typeof path !== 'string' || path.length === 0) return '/';
  const withoutQuery = path.split('?')[0].split('#')[0];
  if (withoutQuery.length > 1 && withoutQuery.endsWith('/')) {
    const stripped = withoutQuery.replace(/\/+$/, '');
    return stripped.length === 0 ? '/' : stripped;
  }
  return withoutQuery;
}

function jsonResponse(status, body, headers = {}) {
  return { status, body, headers: { 'Cache-Control': 'no-store', ...headers } };
}

function parseBody(rawBody) {
  if (!rawBody) return {};
  if (typeof rawBody === 'string') {
    try {
      const parsed = JSON.parse(rawBody);
      return parsed && typeof parsed === 'object' ? parsed : {};
    } catch {
      return {};
    }
  }
  return typeof rawBody === 'object' ? rawBody : {};
}

/**
 * Builds the framework-agnostic request handler.
 *
 * Routes: `GET /api/oauth-client?instance=…`, `POST /api/oauth-client` and
 * `GET /api/health`. Returns plain `{ status, body, headers }` objects, so the
 * whole surface (validation, self-healing, SSRF guard, rate limits) is
 * unit-testable without the Firebase emulator.
 */
function createRegistryHandler({
  db,
  fetchImpl,
  resolveHost,
  now = () => Date.now(),
  logger = console,
  config = {},
}) {
  const settings = {
    ...DEFAULT_CONFIG,
    ...config,
    getRateLimit: { ...DEFAULT_CONFIG.getRateLimit, ...(config.getRateLimit || {}) },
    postRateLimit: { ...DEFAULT_CONFIG.postRateLimit, ...(config.postRateLimit || {}) },
    postPerInstanceRateLimit: {
      ...DEFAULT_CONFIG.postPerInstanceRateLimit,
      ...(config.postPerInstanceRateLimit || {}),
    },
  };

  const getLimiter = createRateLimiter(settings.getRateLimit);
  const postLimiter = createRateLimiter(settings.postRateLimit);
  const instanceLimiter = createRateLimiter(settings.postPerInstanceRateLimit);

  /** Confirms the hostname is well-formed *and* publicly routable. */
  async function guardHostname(hostname) {
    if (!isAllowedHostname(hostname)) return false;
    if (typeof resolveHost !== 'function') return true;
    return resolvesToPublicIp(hostname, resolveHost);
  }

  /**
   * `GET`: returns the shared client id for an instance, with a TTL-cached,
   * self-healing liveness check.
   */
  async function handleGet(hostname) {
    const docRef = db.collection(COLLECTION).doc(hostname);
    const snapshot = await docRef.get();

    if (!snapshot.exists) {
      return jsonResponse(200, { exists: false, instance: hostname });
    }

    const data = snapshot.data() || {};
    const clientId = data.clientId;
    if (!clientId) {
      // Incomplete record: drop it instead of teaching the app a half-entry.
      await docRef.delete();
      return jsonResponse(200, {
        exists: false,
        instance: hostname,
        reason: 'incomplete_record',
      });
    }

    const appName = data.appName || 'TwentyMobile';
    const verifiedAt = typeof data.verifiedAt === 'number' ? data.verifiedAt : 0;

    if (now() - verifiedAt < settings.verificationTtlMs) {
      return jsonResponse(200, {
        exists: true,
        instance: hostname,
        clientId,
        appName,
        verified: true,
        cached: true,
      });
    }

    if (!(await guardHostname(hostname))) {
      return jsonResponse(200, {
        exists: true,
        instance: hostname,
        clientId,
        appName,
        verified: false,
      });
    }

    const check = await verifyClientOnTwenty({
      hostname,
      clientId,
      fetchImpl,
      timeoutMs: settings.verificationTimeoutMs,
    });

    if (check.valid) {
      await docRef.set(
        { appName: check.appName || appName, verifiedAt: now() },
        { merge: true },
      );
      return jsonResponse(200, {
        exists: true,
        instance: hostname,
        clientId,
        appName: check.appName || appName,
        verified: true,
      });
    }

    if (check.reason === 'app_not_found') {
      // The admin really deleted the application: purge the stale record so the
      // next attempt re-registers (or asks for a new Client ID).
      await docRef.delete();
      return jsonResponse(200, {
        exists: false,
        instance: hostname,
        reason: 'app_deleted_on_instance',
        message: 'Application was removed from Twenty CRM and purged from registry.',
      });
    }

    // Instance unreachable or schema mismatch: keep the entry, report "unverified".
    logger.warn?.('oauth_registry_verification_unavailable', {
      instance: hostname,
      error: check.error,
    });
    return jsonResponse(200, {
      exists: true,
      instance: hostname,
      clientId,
      appName,
      verified: false,
    });
  }

  /**
   * `POST`: validates and registers the client id of a team instance. The
   * client id is accepted only when the instance itself confirms it exists.
   */
  async function handlePost({ rawInstance, rawClientId }) {
    const clientId = typeof rawClientId === 'string' ? rawClientId.trim() : null;
    const hostname = extractHostname(rawInstance);

    if (!hostname || !clientId) {
      return jsonResponse(400, {
        error: 'invalid_payload',
        message: "Fields 'instance' and 'clientId' are required.",
      });
    }

    if (!UUID_REGEX.test(clientId)) {
      return jsonResponse(400, {
        error: 'invalid_client_id_format',
        message: 'clientId must be a valid UUID.',
      });
    }

    if (!(await guardHostname(hostname))) {
      return jsonResponse(400, {
        error: 'invalid_instance',
        message: 'The instance hostname must be a publicly reachable domain.',
      });
    }

    const check = await verifyClientOnTwenty({
      hostname,
      clientId,
      fetchImpl,
      timeoutMs: settings.verificationTimeoutMs,
    });

    if (!check.valid) {
      if (check.error) {
        logger.warn?.('oauth_registry_registration_unverified', {
          instance: hostname,
          error: check.error,
        });
      }
      return jsonResponse(400, {
        error: 'client_id_verification_failed',
        message: 'The target Twenty CRM instance does not recognize this Client ID.',
        // Coarse on purpose: the target's status/error is never echoed back.
        details: check.error ? 'verification_unavailable' : 'app_not_found',
      });
    }

    if (check.appName && !isTeamApplicationName(check.appName)) {
      return jsonResponse(409, {
        error: 'app_name_not_shareable',
        message: 'Only TwentyMobile applications can be shared in the team registry.',
      });
    }

    const appName = check.appName || 'TwentyMobile';
    const docRef = db.collection(COLLECTION).doc(hostname);
    const snapshot = await docRef.get();
    const existing = snapshot.exists ? snapshot.data() || {} : {};
    const overwritten =
      Boolean(existing.clientId) && existing.clientId !== clientId;

    const history = Array.isArray(existing.previousClientIds)
      ? existing.previousClientIds.filter((id) => id && id !== clientId)
      : [];
    if (overwritten && existing.clientId) history.unshift(existing.clientId);

    await docRef.set(
      {
        hostname,
        instanceUrl: `https://${hostname}`,
        clientId,
        appName,
        updatedAt: new Date(now()).toISOString(),
        verifiedAt: now(),
        previousClientIds: history.slice(0, settings.maxClientHistory),
      },
      { merge: true },
    );

    if (overwritten) {
      // Kept auditable: whoever inspects the registry can see the previous id.
      logger.warn?.('oauth_registry_entry_overwritten', {
        instance: hostname,
        previousClientId: existing.clientId,
      });
    }

    return jsonResponse(200, {
      success: true,
      instance: hostname,
      clientId,
      appName,
      overwritten,
    });
  }

  /**
   * Routes one request. Never throws: unexpected failures become a 500 so the
   * function cannot crash the whole instance.
   *
   * @param {{ method?: string, path?: string, query?: object, body?: unknown, ip?: string }} request
   * @returns {Promise<{ status: number, body: object, headers: Record<string, string> }>}
   */
  return async function handle(request = {}) {
    try {
      const method = (request.method || 'GET').toUpperCase();
      const path = normalizePath(request.path);
      const ip = request.ip || 'unknown';

      if (method === 'GET' && HEALTH_PATHS.has(path)) {
        return jsonResponse(200, {
          status: 'ok',
          service: 'TwentyMobile OAuth Registry',
        });
      }

      if (!REGISTRY_PATHS.has(path)) {
        return jsonResponse(404, {
          error: 'not_found',
          message: 'Endpoint not found.',
        });
      }

      if (method !== 'GET' && method !== 'POST') {
        return jsonResponse(405, { error: 'method_not_allowed' }, { Allow: 'GET, POST' });
      }

      const limiter = method === 'GET' ? getLimiter : postLimiter;
      if (!limiter.allow(`ip:${ip}`, now())) {
        return jsonResponse(
          429,
          { error: 'rate_limited', message: 'Too many requests. Please retry shortly.' },
          { 'Retry-After': '60' },
        );
      }

      if (method === 'GET') {
        const hostname = extractHostname(request.query?.instance);
        if (!hostname) {
          return jsonResponse(400, {
            error: 'missing_instance',
            message: "Query parameter 'instance' is required.",
          });
        }
        return await handleGet(hostname);
      }

      const body = parseBody(request.body);
      const requestedHostname = extractHostname(body.instance || body.instanceUrl);
      if (requestedHostname && !instanceLimiter.allow(`host:${requestedHostname}`, now())) {
        return jsonResponse(
          429,
          {
            error: 'rate_limited',
            message: 'Too many registrations for this instance. Please retry shortly.',
          },
          { 'Retry-After': '60' },
        );
      }

      return await handlePost({
        rawInstance: body.instance || body.instanceUrl,
        rawClientId: body.clientId,
      });
    } catch (error) {
      logger.error?.('oauth_registry_unhandled_error', { message: error?.message });
      return jsonResponse(500, {
        error: 'internal_error',
        message: 'Failed to handle the registry request.',
      });
    }
  };
}

module.exports = {
  COLLECTION,
  DEFAULT_CONFIG,
  HEALTH_PATHS,
  METADATA_PATH,
  REGISTRY_PATHS,
  UUID_REGEX,
  VERIFY_QUERY,
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
};
