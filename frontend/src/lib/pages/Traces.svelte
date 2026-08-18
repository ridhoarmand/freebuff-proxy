<script>
  import { Timer } from '@lucide/svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import StatusBadge from '../components/StatusBadge.svelte';
  import EmptyState from '../components/EmptyState.svelte';
  import Pagination from '../components/Pagination.svelte';
  import { fetchAPI } from '../utils/api.js';
  import { usePolling } from '../utils/polling.js';

  let data = $state(null);
  let loading = $state(true);
  let error = $state('');
  let page = $state(0);
  const PAGE_SIZE = 50;

  let pagedTraces = $derived(() => {
    const traces = data?.traces || [];
    const start = page * PAGE_SIZE;
    return traces.slice(start, start + PAGE_SIZE);
  });

  let totalPages = $derived(() => Math.ceil((data?.traces?.length || 0) / PAGE_SIZE));

  async function fetchData() {
    try {
      data = await fetchAPI('/admin/api/traces');
      page = 0;
    } catch (e) {
      error = e.message || 'Failed to fetch traces';
    } finally {
      loading = false;
    }
  }

  usePolling(fetchData, 3000);

  function statusVariant(status) {
    if (status === 'ok') return 'teal';
    if (status === 'rate_limited') return 'amber';
    return 'red';
  }
</script>

<div class="space-y-6 page-enter">
  <PageHeader title="Live Request Traces" subtitle="Real-time routing decisions, duration metrics, and error classification">
    {#if data}
      <StatusBadge variant={data.enabled ? 'teal' : 'red'}>
        {data.enabled ? 'Ring Active (200 records)' : 'Ring Disabled'}
      </StatusBadge>
    {/if}
  </PageHeader>

  {#if !data?.enabled}
    <EmptyState icon={Timer} title="Trace Viewer Disabled" description="The trace ring was not initialized (server started without dashboard log handler)." />
  {:else if !data?.traces || data.traces.length === 0}
    <EmptyState icon={Timer} title="No Chat Completions Yet" description="Incoming chat completion requests will appear here automatically." />
  {:else}
    <div class="fp-card overflow-hidden">
      <div class="overflow-x-auto">
        <table class="fp-table">
          <thead>
            <tr>
              <th scope="col">Time</th>
              <th scope="col">Token</th>
              <th scope="col">Model</th>
              <th scope="col">Status</th>
              <th scope="col">Duration</th>
              <th scope="col">Details / Error</th>
            </tr>
          </thead>
          <tbody>
            {#each pagedTraces() as t}
              <tr class={t.error ? 'bg-[var(--fp-red)]/5' : ''}>
                <td class="text-[var(--fp-dim)] whitespace-nowrap">{t.time}</td>
                <td class="font-bold text-white whitespace-nowrap">{t.token}</td>
                <td class="text-[var(--fp-muted)] whitespace-nowrap">{t.model}</td>
                <td class="whitespace-nowrap">
                  <StatusBadge variant={statusVariant(t.status)}>{t.status}</StatusBadge>
                </td>
                <td class="text-white font-semibold whitespace-nowrap tabular-nums">{t.ms}</td>
                <td class="text-[var(--fp-red)] break-all">{t.error || '—'}</td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
      <Pagination
        {page}
        totalPages={totalPages()}
        totalItems={data.traces.length}
        itemLabel="traces"
        onchange={(p) => page = p}
      />
    </div>
  {/if}
</div>
