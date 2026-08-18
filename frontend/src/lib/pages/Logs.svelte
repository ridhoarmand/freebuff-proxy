<script>
  import { ListFilter, Search, RefreshCw, AlertCircle, AlertTriangle, CheckCircle2, Info, X } from '@lucide/svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import StatusBadge from '../components/StatusBadge.svelte';
  import EmptyState from '../components/EmptyState.svelte';
  import Pagination from '../components/Pagination.svelte';
  import { fetchAPI } from '../utils/api.js';
  import { usePolling } from '../utils/polling.js';
  import { formatTime, parseLogFields } from '../utils/format.js';

  let data = $state(null);
  let loading = $state(true);
  let filterLevel = $state('');
  let filterMsg = $state('');
  let page = $state(0);
  const PAGE_SIZE = 50;

  let pagedEntries = $derived(() => {
    const entries = data?.entries || [];
    const start = page * PAGE_SIZE;
    return entries.slice(start, start + PAGE_SIZE);
  });

  let totalPages = $derived(() => Math.ceil((data?.entries?.length || 0) / PAGE_SIZE));

  async function fetchLogs() {
    try {
      const query = new URLSearchParams();
      if (filterLevel) query.set('level', filterLevel);
      if (filterMsg.trim()) query.set('msg', filterMsg.trim());
      data = await fetchAPI(`/admin/api/logs?${query.toString()}`);
      page = 0;
    } catch { /* ignore */ } finally { loading = false; }
  }

  function handleFilterChange() { page = 0; fetchLogs(); }

  usePolling(fetchLogs, 3000);

  function levelColor(level) {
    switch(level) {
      case 'error': return 'red';
      case 'warn': return 'amber';
      case 'info': return 'teal';
      default: return 'blue';
    }
  }

  function levelIcon(level) {
    switch(level) {
      case 'error': return AlertCircle;
      case 'warn': return AlertTriangle;
      case 'info': return CheckCircle2;
      default: return Info;
    }
  }
</script>

<div class="space-y-6 page-enter">
  <PageHeader title="In-Memory Log Stream" subtitle="Circular log buffer (last 200 records) with live level filtering & search — updates every 3s">
    {#if data}
      <StatusBadge variant={data.enabled ? 'teal' : 'red'}>
        {#if data.enabled}
          <RefreshCw size={12} class="animate-spin" />
          Live · 3s
        {:else}
          Disabled
        {/if}
      </StatusBadge>
      <StatusBadge variant="muted" mono>{data.entries?.length || 0}</StatusBadge>
    {/if}
  </PageHeader>

  {#if data?.enabled}
    <!-- Filters -->
    <div class="fp-card p-4 flex flex-col sm:flex-row items-center gap-3">
      <div class="w-full sm:w-48">
        <label for="log-level-select" class="sr-only">Level</label>
        <select
          id="log-level-select"
          bind:value={filterLevel}
          onchange={handleFilterChange}
          class="fp-input fp-input-mono text-xs"
        >
          <option value="">ALL LEVELS</option>
          <option value="info">INFO</option>
          <option value="debug">DEBUG</option>
          <option value="warn">WARN</option>
          <option value="error">ERROR</option>
        </select>
      </div>
      <div class="w-full flex-1 relative flex items-center">
        <label for="log-search-input" class="sr-only">Search</label>
        <Search size={14} class="absolute left-3 text-[var(--fp-dim)] pointer-events-none" />
        <input
          id="log-search-input"
          type="text"
          bind:value={filterMsg}
          oninput={handleFilterChange}
          placeholder="Filter by message, req_id, path..."
          class="fp-input text-xs pl-9 pr-8 py-1.5 h-8.5"
        />
        {#if filterMsg}
          <button
            type="button"
            onclick={() => { filterMsg = ''; handleFilterChange(); }}
            class="absolute right-2 p-1 rounded hover:bg-[var(--fp-surface-3)] text-[var(--fp-dim)] hover:text-white transition-colors"
            aria-label="Clear filter"
          >
            <X size={13} />
          </button>
        {/if}
      </div>
    </div>

    <!-- Entries -->
    {#if !data?.entries || data.entries.length === 0}
      <EmptyState icon={ListFilter} title="No Matching Log Records" description="No log entries matched your filter criteria." />
    {:else}
      <div class="space-y-1.5">
        {#each pagedEntries() as e}
          {@const LevelIcon = levelIcon(e.level)}
          {@const fields = parseLogFields(e.fields)}
          <div class="fp-card overflow-hidden">
            <div class="flex items-center gap-3 px-4 py-2.5">
              <StatusBadge variant={levelColor(e.level)}>
                <LevelIcon size={10} />
                {e.level}
              </StatusBadge>
              <span class="text-sm font-mono text-white font-medium flex-1 truncate">{e.message}</span>
              <span class="shrink-0 text-[11px] font-mono text-[var(--fp-dim)] tabular-nums">{formatTime(e.time)}</span>
            </div>
            {#if fields.length > 0}
              <div class="px-4 pb-2.5 pt-0">
                <div class="flex flex-wrap gap-1.5">
                  {#each fields as f}
                    <span class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded fp-inset text-[10px] font-mono">
                      <span class="text-[var(--fp-dim)] font-semibold">{f.key}</span>
                      <span class="text-[var(--fp-muted)]">{f.value}</span>
                    </span>
                  {/each}
                </div>
              </div>
            {/if}
          </div>
        {/each}
      </div>
      <Pagination
        {page}
        totalPages={totalPages()}
        totalItems={data.entries.length}
        itemLabel="entries"
        onchange={(p) => page = p}
      />
    {/if}
  {:else}
    <EmptyState icon={ListFilter} title="Log Ring Disabled" description="The server was started without an active logring handler." />
  {/if}
</div>
