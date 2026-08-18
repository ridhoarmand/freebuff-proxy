<script>
  import { onMount } from 'svelte';
  import { Zap, ArrowRightLeft } from '@lucide/svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import StatusBadge from '../components/StatusBadge.svelte';
  import CopyButton from '../components/CopyButton.svelte';
  import { fetchAPI } from '../utils/api.js';
  import { copyToClipboard } from '../utils/clipboard.js';

  let data = $state(null);
  let loading = $state(true);
  let error = $state('');
  let copiedId = $state('');

  async function fetchData() {
    try {
      data = await fetchAPI('/admin/api/models');
    } catch (e) {
      error = e.message || 'Failed to fetch models';
    } finally {
      loading = false;
    }
  }

  function copyText(text) {
    copyToClipboard(text);
    copiedId = text;
    setTimeout(() => {
      if (copiedId === text) copiedId = '';
    }, 1800);
  }

  onMount(() => { fetchData(); });
</script>

<div class="space-y-6 page-enter">
  <PageHeader title="Model Catalog & Registry" subtitle="Live registered models with dynamic fallback & transparent alias resolution">
    {#if data}
      <StatusBadge variant="teal">{data.count} registered models</StatusBadge>
      <StatusBadge variant="muted" mono>{data.agents} upstream agents</StatusBadge>
    {/if}
  </PageHeader>

  <!-- Models Table -->
  <div class="fp-card overflow-hidden">
    <div class="p-4 border-b border-[var(--fp-border)] flex items-center justify-between">
      <div class="flex items-center gap-2">
        <Zap size={18} class="text-[var(--fp-amber)]" />
        <h2 class="text-base font-semibold text-white">Registered Models</h2>
      </div>
      <span class="text-xs text-[var(--fp-dim)]">Click model ID or copy button to copy</span>
    </div>
    <div class="overflow-x-auto">
      <table class="fp-table">
        <thead>
          <tr>
            <th scope="col">Model Identifier (ID)</th>
            <th scope="col">Upstream Agent Binding</th>
            <th scope="col" class="w-24 text-right">Action</th>
          </tr>
        </thead>
        <tbody>
          {#each data?.models || [] as m}
            <tr>
              <td>
                <button
                  type="button"
                  onclick={() => copyText(m.id)}
                  class="font-bold text-white hover:text-[var(--fp-amber)] text-left transition-colors flex items-center gap-2"
                  title="Click to copy model ID"
                >
                  <span>{m.id}</span>
                  {#if m.id.includes('deepseek-v4-flash')}
                    <span class="px-1.5 py-0.5 rounded bg-[var(--fp-amber)]/15 text-[var(--fp-amber)] border border-[var(--fp-amber)]/30 text-[10px] uppercase font-sans font-semibold">default</span>
                  {/if}
                </button>
              </td>
              <td class="text-[var(--fp-muted)]">{m.agent || '—'}</td>
              <td class="text-right">
                <CopyButton text={m.id} variant="labeled" />
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  </div>

  <!-- Model Aliases -->
  {#if data?.has_aliases && data?.aliases?.length > 0}
    <div class="fp-card overflow-hidden">
      <div class="p-4 border-b border-[var(--fp-border)] flex items-center gap-2">
        <ArrowRightLeft size={18} class="text-[var(--fp-blue)]" />
        <div>
          <h2 class="text-base font-semibold text-white">Active Model Aliases</h2>
          <p class="text-xs text-[var(--fp-muted)] mt-0.5">Configured in <code class="text-[var(--fp-amber)]">MODEL_ALIASES</code> — client requests are rewritten to target models.</p>
        </div>
      </div>
      <div class="overflow-x-auto">
        <table class="fp-table">
          <thead>
            <tr>
              <th scope="col">Client Alias</th>
              <th scope="col">Target Model ID</th>
              <th scope="col" class="w-24 text-right">Action</th>
            </tr>
          </thead>
          <tbody>
            {#each data.aliases as a}
              <tr>
                <td class="font-bold text-[var(--fp-blue)]">{a.alias}</td>
                <td class="text-white">{a.real}</td>
                <td class="text-right">
                  <CopyButton text={a.alias} variant="labeled" />
                </td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    </div>
  {/if}
</div>
