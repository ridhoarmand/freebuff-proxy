/**
 * Copy text to clipboard and return a promise.
 * @param {string} text
 * @returns {Promise<boolean>} true if successful
 */
export async function copyToClipboard(text) {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    return false;
  }
}

/**
 * Create a reactive copy state tracker. Returns a Svelte 5 $state
 * and a copy function that auto-resets after a delay.
 *
 * Usage in components:
 *   const copied = createCopyState();
 *   copied.copy('text-to-copy');
 *   // copied.active — boolean, true for 1.8s after copy
 *   // copied.id — the last copied identifier (for multi-button UIs)
 */
export function createCopyState(resetMs = 1800) {
  let _active = $state(false);
  let _id = $state('');
  let timer;

  return {
    get active() { return _active; },
    get id() { return _id; },
    async copy(text, id = '') {
      const ok = await copyToClipboard(text);
      if (ok) {
        _active = true;
        _id = id || text;
        clearTimeout(timer);
        timer = setTimeout(() => {
          _active = false;
          _id = '';
        }, resetMs);
      }
      return ok;
    },
    isActive(id) {
      return _active && _id === id;
    },
  };
}
