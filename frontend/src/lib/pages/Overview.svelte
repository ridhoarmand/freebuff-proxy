<script>
  import { Shield, AlertTriangle, Play, RefreshCw, CheckCircle2, XCircle } from '@lucide/svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import StatusBadge from '../components/StatusBadge.svelte';
  import EmptyState from '../components/EmptyState.svelte';
  import CopyButton from '../components/CopyButton.svelte';
  import { fetchAPI, postAPI } from '../utils/api.js';
  import { usePolling } from '../utils/polling.js';

  let data = $state(null);
  let loading = $state(true);
  let error = $state('');

  // Smoke test state
  let smokeModel = $state('');
  let smokePrompt = $state('ping');
  let smokeRunning = $state(false);
  let smokeResult = $state(null);
  let smokeError = $state('');

  async function fetchData() {
    try {
      data = await fetchAPI('/admin/api/overview');
      if (!smokeModel && data?.models?.length > 0) {
        const preferred = data.models.find(m => m === 'deepseek/deepseek-v4-flash') ||
                          data.models.find(m => m.includes('deepseek-v4-flash')) ||
                          data.models[0];
        smokeModel = preferred;
      }
    } catch (e) {
      error = e.message || 'Failed to fetch overview data';
    } finally {
      loading = false;
    }
  }

  async function runSmokeTest(e) {
    e?.preventDefault();
    if (!smokeModel || smokeRunning) return;
    smokeRunning = true;
    smokeResult = null;
    smokeError = '';
    try {
      const result = await postAPI('/admin/smoke', { model: smokeModel, prompt: smokePrompt });
      if (result.ok) {
        smokeResult = result;
      } else {
        smokeError = result.message || 'Smoke test failed';
      }
    } catch (e) {
      smokeError = e.message || 'Network error running smoke test';
    } finally {
      smokeRunning = false;
    }
  }

  usePolling(fetchData, 5000);

  function riskVariant(risk) {
    switch (risk) {
      case 'low': return 'teal';
      case 'moderate': return 'amber';
      case 'high': case 'critical': return 'red';
      default: return 'muted';
    }
  }

  function riskDot(risk) {
    switch (risk) {
      case 'low': return 'bg-[var(--fp-teal)]';
      case 'moderate': return 'bg-[var(--fp-amber)]';
      case 'high': return 'bg-[#F97316]';
      case 'critical': return 'bg-[var(--fp-red)]';
      default: return 'bg-[var(--fp-dim)]';
    }
  }

  function modeVariant(data) {
    if (data?.in_bridge) return 'blue';
    if (data?.mode === 'hybrid') return 'purple';
    return 'amber';
  }
</script>

<div class="space-y-6 page-enter">
  <PageHeader title="Overview" subtitle="Live proxy status & real-time token pool telemetry">
    {#if data}
      <StatusBadge variant={modeVariant(data)}>{data.mode} mode</StatusBadge>
      <StatusBadge variant="muted" mono>{data.model_count} models</StatusBadge>
      <StatusBadge variant="muted" mono>up {data.uptime}</StatusBadge>
      {#if data.safe_mode}
        <StatusBadge variant="teal">
          <Shield size={12} />
          safe mode
        </StatusBadge>
      {/if}
    {/if}
  </PageHeader>

  <!-- Loading Skeleton -->
  {#if loading}
    <div class="space-y-4">
      <div class="skeleton skeleton-card"></div>
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
        {#each [1,2,3,4] as _}
          <div class="skeleton skeleton-card"></div>
        {/each}
      </div>
    </div>
  {/if}

  <!-- Smoke Test Card -->
  <div class="fp-card p-5">
    <div class="flex items-center justify-between gap-2 mb-3">
      <div class="flex items-center gap-2">
        <Play size={18} class="text-[var(--fp-amber)]" />
        <h2 class="text-base font-semibold text-white">End-to-End Smoke Test</h2>
      </div>
      <span class="text-xs text-[var(--fp-dim)]">Zero-token pipeline verification</span>
    </div>
    <form onsubmit={runSmokeTest} class="grid grid-cols-1 sm:grid-cols-12 gap-3">
      <div class="sm:col-span-4 flex items-center gap-1.5">
        <label for="smoke-model" class="sr-only">Model</label>
        <select
          id="smoke-model"
          bind:value={smokeModel}
          class="fp-input fp-input-mono text-sm flex-1"
        >
          {#each data?.models || [] as model}
            <option value={model}>{model}</option>
          {/each}
        </select>
        <CopyButton text={smokeModel} variant="icon" />
      </div>
      <div class="sm:col-span-6">
        <label for="smoke-prompt" class="sr-only">Prompt</label>
        <input
          id="smoke-prompt"
          type="text"
          bind:value={smokePrompt}
          maxlength="200"
          placeholder="Test prompt..."
          class="fp-input text-sm"
        />
      </div>
      <div class="sm:col-span-2">
        <button
          type="submit"
          disabled={smokeRunning || !smokeModel}
          class="w-full h-full min-h-[38px] fp-btn-primary"
        >
          {#if smokeRunning}
            <RefreshCw size={14} class="animate-spin" />
            <span>Testing...</span>
          {:else}
            <span>Run Test</span>
          {/if}
        </button>
      </div>
    </form>

    {#if smokeResult}
      <div class="mt-4 p-4 rounded-lg bg-[var(--fp-teal)]/10 border border-[var(--fp-teal)]/30 text-sm">
        <div class="flex items-center gap-2 text-[var(--fp-teal)] font-medium mb-2">
          <CheckCircle2 size={16} />
          <span>Smoke test passed in {smokeResult.ms}ms via {smokeResult.token} ({smokeResult.model})</span>
        </div>
        {#if smokeResult.phases?.length > 0}
          <div class="flex flex-wrap gap-2 mt-2">
            {#each smokeResult.phases as phase}
              <span class="px-2 py-0.5 rounded fp-inset text-xs font-mono text-[var(--fp-muted)]">
                {phase.name}: <strong class="text-white tabular-nums">{phase.ms}ms</strong>
              </span>
            {/each}
          </div>
        {/if}
        {#if smokeResult.preview}
          <pre class="mt-3 p-2 rounded bg-[var(--fp-bg)] border border-[var(--fp-border)] text-xs font-mono text-[var(--fp-text)] overflow-x-auto whitespace-pre-wrap">{smokeResult.preview}</pre>
        {/if}
      </div>
    {/if}

    {#if smokeError}
      <div class="mt-4 p-3 rounded-lg bg-[var(--fp-red)]/10 border border-[var(--fp-red)]/30 text-sm text-[var(--fp-red)] flex items-center gap-2" role="alert">
        <XCircle size={16} />
        <span>{smokeError}</span>
      </div>
    {/if}
  </div>

  <!-- Bridge / Empty / Token Cards -->
  {#if data?.in_bridge}
    <div class="fp-card p-5 border-[var(--fp-blue)]/30">
      <h3 class="text-base font-semibold text-white mb-1">Bridge Mode Active</h3>
      <p class="text-sm text-[var(--fp-muted)]">
        Upstream tokens are relayed directly per client request ({data.bridge_tokens || 0} active bridge client{data.bridge_tokens === 1 ? '' : 's'}). Session pools and quota tracking are client-scoped.
      </p>
    </div>
  {:else if !data?.has_tokens}
    <EmptyState
      icon={AlertTriangle}
      title="No Upstream Tokens Configured"
      description="Add tokens to AUTH_TOKENS in Config or Setup to start the pooled relay."
    />
  {:else}
    <!-- Token Cards Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
      {#each data?.tokens || [] as token}
        <div class="fp-card fp-card-interactive p-4 flex flex-col justify-between">
          <div>
            <div class="flex items-center justify-between mb-3">
              <div class="flex items-center gap-2">
                <span class="w-2.5 h-2.5 rounded-full {riskDot(token.risk_level)}"></span>
                <span class="font-bold text-white text-base">Token #{token.index}</span>
              </div>
              <StatusBadge variant={riskVariant(token.risk_level)}>{token.risk_level}</StatusBadge>
            </div>

            {#if token.has_standing}
              <div class="mb-3 px-2.5 py-1 rounded bg-[var(--fp-blue)]/10 border border-[var(--fp-blue)]/20 text-xs text-[var(--fp-blue)] flex items-center justify-between">
                <span>Trust standing: <strong>{token.standing_label}</strong></span>
                <span class="tabular-nums">{Math.round(token.standing_score)}/100</span>
              </div>
            {/if}

            <div class="grid grid-cols-2 gap-2 text-xs font-mono mb-4">
              <div class="p-2 rounded fp-inset">
                <span class="text-[var(--fp-dim)] block text-[10px] uppercase">Session</span>
                <span class="text-white font-semibold">{token.session_status}</span>
              </div>
              <div class="p-2 rounded fp-inset">
                <span class="text-[var(--fp-dim)] block text-[10px] uppercase">Active Runs</span>
                <span class="text-white font-semibold tabular-nums">{token.active_runs}</span>
              </div>
              <div class="p-2 rounded fp-inset">
                <span class="text-[var(--fp-dim)] block text-[10px] uppercase">Requests</span>
                <span class="text-white font-semibold tabular-nums">{token.requests}</span>
              </div>
              <div class="p-2 rounded fp-inset">
                <span class="text-[var(--fp-dim)] block text-[10px] uppercase">24h Messages</span>
                <span class="text-white font-semibold tabular-nums">{token.messages_24h}{token.daily_limit > 0 ? ` / ${token.daily_limit}` : ''}</span>
              </div>
            </div>
          </div>

          {#if token.daily_limit > 0}
            <div>
              <div class="w-full bg-[var(--fp-input-bg)] h-2 rounded-full overflow-hidden border border-[var(--fp-border)]">
                <div
                  class="h-full transition-all duration-300 {token.usage_pct >= 80 ? 'bg-[var(--fp-red)]' : 'bg-[var(--fp-amber)]'}"
                  style="width: {Math.min(token.usage_pct, 100)}%"
                ></div>
              </div>
              <div class="flex justify-between text-[11px] text-[var(--fp-dim)] mt-1 font-mono">
                <span>Usage</span>
                <span class="tabular-nums">{token.usage_pct}%</span>
              </div>
            </div>
          {/if}
        </div>
      {/each}
    </div>
  {/if}
</div>
