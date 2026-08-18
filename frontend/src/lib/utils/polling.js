import { onMount, onDestroy } from 'svelte';

/**
 * Set up visibility-aware polling. Pauses when the tab is hidden,
 * resumes when visible. Calls fetchFn immediately on mount.
 *
 * @param {() => Promise<void>} fetchFn - Async function to call on each tick
 * @param {number} intervalMs - Polling interval in milliseconds
 */
export function usePolling(fetchFn, intervalMs) {
  let timer;

  function start() {
    clearInterval(timer);
    timer = setInterval(fetchFn, intervalMs);
  }

  function stop() {
    clearInterval(timer);
  }

  function handleVisibility() {
    if (document.hidden) {
      stop();
    } else {
      start();
    }
  }

  onMount(() => {
    fetchFn();
    start();
    document.addEventListener('visibilitychange', handleVisibility);
  });

  onDestroy(() => {
    stop();
    document.removeEventListener('visibilitychange', handleVisibility);
  });
}
