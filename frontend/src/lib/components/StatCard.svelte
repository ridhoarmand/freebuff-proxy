<script>
  /**
   * StatCard — metric display tile with label, value, and optional sparkline.
   *
   * @prop {string} label
   * @prop {string|number} value
   * @prop {string} [description]
   * @prop {string} [sparkHtml] - SVG sparkline HTML
   */
  let { label, value, description, sparkHtml } = $props();
</script>

<div class="fp-card p-5 flex flex-col justify-between">
  <div>
    <div class="text-xs font-semibold text-[var(--fp-muted)] uppercase tracking-wider mb-1">{label}</div>
    <div class="text-3xl font-bold text-white font-mono tabular-nums">{value}</div>
  </div>
  {#if sparkHtml}
    <div class="mt-4 overflow-hidden">
      {@html sparkHtml}
    </div>
  {/if}
  {#if description}
    <p class="text-xs text-[var(--fp-dim)] mt-4">{description}</p>
  {/if}
</div>
