/**
 * Format an ISO timestamp to a local short date.
 * @param {string} utcIso
 * @returns {string}
 */
export function formatLocalDate(utcIso) {
  if (!utcIso) return '';
  try {
    const d = new Date(utcIso);
    if (isNaN(d.getTime())) return utcIso;
    return d.toLocaleString(undefined, {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return utcIso;
  }
}

/**
 * Format an ISO timestamp to a local time string (HH:MM:SS).
 * @param {string} ts
 * @returns {string}
 */
export function formatTime(ts) {
  if (!ts) return '';
  try {
    const d = new Date(ts);
    if (isNaN(d.getTime())) return ts;
    return d.toLocaleTimeString(undefined, {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  } catch {
    return ts;
  }
}

/**
 * Parse structured log fields string into key-value pairs.
 * Fields are separated by double-space, key=value format.
 * @param {string} fields
 * @returns {Array<{key: string, value: string}>}
 */
export function parseLogFields(fields) {
  if (!fields) return [];
  return fields
    .split('  ')
    .filter(Boolean)
    .map((f) => {
      const [k, ...v] = f.split('=');
      return { key: k, value: v.join('=') };
    });
}
