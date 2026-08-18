<script>
  import { CheckCircle2, AlertCircle, AlertTriangle, Info } from '@lucide/svelte';

  /**
   * Alert — dismissable status banner.
   *
   * @prop {'success'|'error'|'warning'|'info'} [variant='info']
   * @prop {string} message
   * @prop {boolean} [dismissable=true]
   * @prop {() => void} [ondismiss]
   */
  let { variant = 'info', message, dismissable = true, ondismiss } = $props();

  const icons = { success: CheckCircle2, error: AlertCircle, warning: AlertTriangle, info: Info };
  const styles = {
    success: 'bg-[var(--fp-teal)]/10 border-[var(--fp-teal)]/30 text-[var(--fp-teal)]',
    error:   'bg-[var(--fp-red)]/10 border-[var(--fp-red)]/30 text-[var(--fp-red)]',
    warning: 'bg-[var(--fp-amber)]/10 border-[var(--fp-amber)]/30 text-[var(--fp-amber)]',
    info:    'bg-[#60A5FA]/10 border-[#60A5FA]/30 text-[#60A5FA]',
  };

  let Icon = $derived(icons[variant] || Info);
</script>

{#if message}
  <div
    class="p-4 rounded-xl flex items-center justify-between gap-3 text-sm border {styles[variant] || styles.info}"
    role="alert"
  >
    <div class="flex items-center gap-2">
      <Icon size={16} />
      <span>{message}</span>
    </div>
    {#if dismissable && ondismiss}
      <button
        onclick={ondismiss}
        class="text-xs opacity-70 hover:opacity-100 underline shrink-0"
        aria-label="Dismiss alert"
      >
        Dismiss
      </button>
    {/if}
  </div>
{/if}
