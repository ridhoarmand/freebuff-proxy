<script>
  /**
   * PageHeader — consistent page title + subtitle + optional right-side badges.
   *
   * @prop {string} title
   * @prop {string} [subtitle]
   */
  let { title, subtitle, children } = $props();
</script>

<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
  <div>
    <h1 class="text-2xl font-bold text-white tracking-tight">{title}</h1>
    {#if subtitle}
      <p class="text-sm text-[var(--fp-muted)] mt-1">{subtitle}</p>
    {/if}
  </div>
  {#if children}
    <div class="flex flex-wrap items-center gap-2">
      {@render children()}
    </div>
  {/if}
</div>
