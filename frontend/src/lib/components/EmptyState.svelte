<script>
  /**
   * EmptyState — icon + heading + description + optional action.
   *
   * @prop {any} icon - Lucide icon component
   * @prop {string} title
   * @prop {string} [description]
   */
  let { icon: Icon, title, description, children } = $props();
</script>

<div class="fp-card p-8 text-center">
  {#if Icon}
    <div class="w-12 h-12 rounded-full bg-[var(--fp-amber)]/10 text-[var(--fp-amber)] flex items-center justify-center mx-auto mb-3">
      <Icon size={24} />
    </div>
  {/if}
  <h3 class="text-lg font-semibold text-white mb-1">{title}</h3>
  {#if description}
    <p class="text-sm text-[var(--fp-muted)] max-w-md mx-auto mb-4">{description}</p>
  {/if}
  {#if children}
    {@render children()}
  {/if}
</div>
