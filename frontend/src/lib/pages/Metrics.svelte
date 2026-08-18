<script>
  import { Radio, ExternalLink } from '@lucide/svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import StatusBadge from '../components/StatusBadge.svelte';
  import StatCard from '../components/StatCard.svelte';
  import { fetchAPI } from '../utils/api.js';
  import { usePolling } from '../utils/polling.js';

  let data = $state(null);
  let loading = $state(true);
  let error = $state('');

  async function fetchMetrics() {
    try {
      data = await fetchAPI('/admin/api/metrics');
    } catch (e) {
      error = e.message || 'Failed to fetch metrics';
    } finally {
      loading = false;
    }
  }

  usePolling(fetchMetrics, 5000);
</script>

<div class="space-y-6 page-enter">
  <PageHeader title="Telemetry & Metrics" subtitle="Live metrics counters and trends sampled every 5s">
    {#if data}
      <StatusBadge variant="muted" mono>{data.models} models</StatusBadge>
      <StatusBadge variant="muted" mono>{data.sample_count} samples cached</StatusBadge>
    {/if}
  </PageHeader>

  <!-- Loading Skeleton -->
  {#if loading}
    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
      {#each [1,2,3] as _}
        <div class="skeleton skeleton-card"></div>
      {/each}
    </div>
  {/if}

  <!-- Metric Cards -->
  {#if data}
    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
      <StatCard
        label="Requests Served"
        value={data.requests_total}
        sparkHtml={data.requests_spark}
      />
      <StatCard
        label="Transient Retries"
        value={data.transient_retries}
        sparkHtml={data.retries_spark}
      />
      <StatCard
        label="Fingerprint Rotations"
        value={data.fingerprint_rotations}
        description="Stealth browser TLS profile rotation events"
      />
    </div>
  {/if}

  <!-- Prometheus Card -->
  <div class="fp-card p-5 space-y-3">
    <div class="flex items-center gap-2">
      <Radio size={18} class="text-[var(--fp-amber)]" />
      <h2 class="text-base font-semibold text-white">Prometheus Exporter Feed</h2>
    </div>
    <p class="text-xs text-[var(--fp-muted)]">
      Real-time Prometheus format metrics are exposed at <code class="text-[var(--fp-amber)] font-mono">/metrics</code> for Grafana, Prometheus scrapers, Datadog, or SigNoz. Includes per-token counters, cooldown locks, session status, and microsecond phase latencies.
    </p>
    <div>
      <a
        href="/metrics"
        target="_blank"
        rel="noopener noreferrer"
        class="fp-btn-secondary"
      >
        <ExternalLink size={14} />
        <span>Open Raw /metrics Feed</span>
      </a>
    </div>
  </div>
</div>
