<script>
  import { Copy, Check } from '@lucide/svelte';
  import { copyToClipboard } from '../utils/clipboard.js';

  /**
   * CopyButton — consistent copy-to-clipboard button.
   *
   * @prop {string} text - Text to copy
   * @prop {'icon'|'labeled'|'inline'} [variant='icon']
   * @prop {string} [label='Copy']
   * @prop {number} [size=14]
   */
  let { text, variant = 'icon', label = 'Copy', size = 14 } = $props();
  let copied = $state(false);
  let timer;

  async function handleCopy() {
    const ok = await copyToClipboard(text);
    if (ok) {
      copied = true;
      clearTimeout(timer);
      timer = setTimeout(() => { copied = false; }, 1800);
    }
  }
</script>

{#if variant === 'icon'}
  <button
    type="button"
    onclick={handleCopy}
    class="p-2 rounded-lg bg-[var(--fp-input-bg)] border border-[var(--fp-border)] hover:border-[var(--fp-border-bright)] text-[var(--fp-muted)] hover:text-white transition-colors"
    title="Copy to clipboard"
    aria-label={copied ? 'Copied' : 'Copy to clipboard'}
  >
    {#if copied}
      <Check {size} class="text-[var(--fp-teal)]" />
    {:else}
      <Copy {size} />
    {/if}
  </button>
{:else if variant === 'labeled'}
  <button
    type="button"
    onclick={handleCopy}
    class="px-2.5 py-1 rounded-lg bg-[var(--fp-surface-3)] hover:bg-[var(--fp-border-bright)] text-xs transition-colors inline-flex items-center gap-1.5
      {copied ? 'text-[var(--fp-teal)] border border-[var(--fp-teal)]/40' : 'text-[var(--fp-muted)] hover:text-white'}"
  >
    {#if copied}
      <Check size={13} />
      <span>Copied</span>
    {:else}
      <Copy size={13} />
      <span>{label}</span>
    {/if}
  </button>
{:else}
  <button
    type="button"
    onclick={handleCopy}
    class="flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-medium text-[var(--fp-muted)] hover:text-white hover:bg-[var(--fp-surface-3)] transition-colors"
  >
    {#if copied}
      <Check size={12} class="text-[var(--fp-teal)]" />
      <span>Copied</span>
    {:else}
      <Copy size={12} />
      <span>{label}</span>
    {/if}
  </button>
{/if}
