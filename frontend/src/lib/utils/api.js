/**
 * Shared API fetch utility. Handles JSON parsing, auth redirects,
 * and standardized error handling.
 */

/**
 * Fetch JSON from an admin API endpoint. On 401, redirects to login.
 * @param {string} path - API path (e.g. '/admin/api/overview')
 * @param {RequestInit} [opts] - Additional fetch options
 * @returns {Promise<any>} Parsed JSON response
 * @throws {Error} On non-OK status or network failure
 */
export async function fetchAPI(path, opts = {}) {
  const res = await fetch(path, {
    ...opts,
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'fetch',
      ...opts.headers,
    },
  });

  if (res.status === 401) {
    window.location.href = '/admin/login';
    throw new Error('Unauthorized');
  }

  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(text || `HTTP ${res.status}`);
  }

  return res.json();
}

/**
 * POST JSON to an admin API endpoint.
 * @param {string} path
 * @param {any} body
 * @returns {Promise<any>}
 */
export async function postAPI(path, body) {
  return fetchAPI(path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: body != null ? JSON.stringify(body) : undefined,
  });
}

/**
 * POST form data to an admin endpoint.
 * @param {string} path
 * @param {Record<string, string>} fields
 * @returns {Promise<Response>} Raw response (login/config use non-JSON responses)
 */
export async function postForm(path, fields) {
  return fetch(path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(fields),
  });
}
