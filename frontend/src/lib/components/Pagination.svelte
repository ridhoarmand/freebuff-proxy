<script>
  /**
   * Pagination — shared Previous/Next pagination for tables.
   *
   * @prop {number} page - Current page (0-indexed)
   * @prop {number} totalPages - Total number of pages
   * @prop {number} totalItems - Total number of items
   * @prop {string} [itemLabel='items']
   * @prop {(page: number) => void} onchange
   */
  let { page = 0, totalPages = 1, totalItems = 0, itemLabel = 'items', onchange } = $props();
</script>

{#if totalPages > 1}
  <div class="flex items-center justify-between px-4 py-3 bg-[var(--fp-input-bg)] border-t border-[var(--fp-border)] text-xs text-[var(--fp-muted)] rounded-b-xl">
    <span class="font-mono">Page {page + 1} of {totalPages} ({totalItems} {itemLabel})</span>
    <div class="flex items-center gap-2">
      <button
        type="button"
        onclick={() => onchange(Math.max(0, page - 1))}
        disabled={page === 0}
        class="px-3 py-1.5 rounded-lg bg-[var(--fp-surface-3)] hover:bg-[var(--fp-border-bright)] text-white border border-[var(--fp-border-bright)] disabled:opacity-30 transition-colors"
      >
        Previous
      </button>
      <button
        type="button"
        onclick={() => onchange(Math.min(totalPages - 1, page + 1))}
        disabled={page >= totalPages - 1}
        class="px-3 py-1.5 rounded-lg bg-[var(--fp-surface-3)] hover:bg-[var(--fp-border-bright)] text-white border border-[var(--fp-border-bright)] disabled:opacity-30 transition-colors"
      >
        Next
      </button>
    </div>
  </div>
{/if}
