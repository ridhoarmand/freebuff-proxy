<script>
  import {
    LayoutDashboard, Key, Cpu, Activity, MessageSquare,
    Settings, Wrench, FileText, BarChart3, ChevronRight,
    Menu, X, ArrowUpCircle
  } from '@lucide/svelte';

  /**
   * @prop {string} activeTab
   * @prop {(tab: string) => void} onTabChange
   * @prop {{ has_update: boolean, latest_version: string, update_url: string }} [versionInfo]
   */
  let { activeTab = $bindable(), onTabChange, versionInfo } = $props();

  let mobileOpen = $state(false);

  const tabs = [
    { id: 'overview',   label: 'Overview',    icon: LayoutDashboard, key: '1' },
    { id: 'tokens',     label: 'Tokens',      icon: Key,             key: '2' },
    { id: 'models',     label: 'Models',      icon: Cpu,             key: '3' },
    { id: 'traces',     label: 'Traces',      icon: Activity,        key: '4' },
    { id: 'playground', label: 'Playground',   icon: MessageSquare,   key: '5' },
    { id: 'config',     label: 'Config',       icon: Settings,        key: '6' },
    { id: 'setup',      label: 'Setup',        icon: Wrench,          key: '7' },
    { id: 'logs',       label: 'Logs',         icon: FileText,        key: '8' },
    { id: 'metrics',    label: 'Metrics',      icon: BarChart3,       key: '9' },
  ];

  function switchTab(id) {
    activeTab = id;
    onTabChange?.(id);
    window.location.hash = id;
    mobileOpen = false;
  }

  function handleKeydown(e) {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') return;
    const num = parseInt(e.key);
    if (num >= 1 && num <= 9) {
      e.preventDefault();
      switchTab(tabs[num - 1].id);
    }
  }
</script>

<svelte:window onkeydown={handleKeydown} />

<header class="sticky top-0 z-50 border-b border-[var(--fp-border)] bg-[var(--fp-bg)]/80 backdrop-blur-xl backdrop-saturate-150">
  <nav class="max-w-7xl mx-auto px-4 sm:px-6" aria-label="Main navigation">
    <div class="flex items-center justify-between h-14">
      <!-- Logo -->
      <div class="flex items-center gap-3">
        <a href="/admin" class="flex items-center gap-2.5 group" aria-label="freebuff-proxy dashboard home">
          <div class="w-7 h-7 rounded-lg bg-[var(--fp-amber)]/12 border border-[var(--fp-amber)]/25 flex items-center justify-center transition-all duration-200 group-hover:bg-[var(--fp-amber)]/20 group-hover:border-[var(--fp-amber)]/40">
            <ChevronRight size={14} class="text-[var(--fp-amber)]" />
          </div>
          <span class="text-sm font-semibold text-white tracking-tight hidden sm:inline">freebuff-proxy</span>
        </a>
      </div>

      <!-- Desktop Nav -->
      <div class="hidden md:flex items-center gap-0.5" role="tablist">
        {#each tabs as tab}
          <button
            role="tab"
            aria-selected={activeTab === tab.id}
            onclick={() => switchTab(tab.id)}
            class="relative flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all duration-200
              {activeTab === tab.id
                ? 'text-[var(--fp-amber)] bg-[var(--fp-amber)]/10'
                : 'text-[var(--fp-muted)] hover:text-white hover:bg-[var(--fp-surface-3)]'}"
            title="{tab.label} (press {tab.key})"
          >
            <tab.icon size={14} />
            <span>{tab.label}</span>
            {#if activeTab === tab.id}
              <span class="absolute -bottom-[9px] left-3 right-3 h-[2px] bg-[var(--fp-amber)] rounded-full"></span>
            {/if}
          </button>
        {/each}
      </div>

      <!-- Right side: update badge + mobile menu -->
      <div class="flex items-center gap-2">
        {#if versionInfo?.has_update}
          <a
            href={versionInfo.update_url}
            target="_blank"
            rel="noopener noreferrer"
            class="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-semibold uppercase tracking-wider bg-[var(--fp-teal)]/15 text-[var(--fp-teal)] border border-[var(--fp-teal)]/30 hover:bg-[var(--fp-teal)]/25 transition-colors"
          >
            <ArrowUpCircle size={12} />
            <span>v{versionInfo.latest_version}</span>
          </a>
        {/if}

        <!-- Mobile menu button -->
        <button
          class="md:hidden p-2 rounded-lg text-[var(--fp-muted)] hover:text-white hover:bg-[var(--fp-surface-3)] transition-colors"
          onclick={() => mobileOpen = !mobileOpen}
          aria-label={mobileOpen ? 'Close menu' : 'Open menu'}
          aria-expanded={mobileOpen}
          aria-controls="mobile-nav"
        >
          {#if mobileOpen}
            <X size={20} />
          {:else}
            <Menu size={20} />
          {/if}
        </button>
      </div>
    </div>

    <!-- Mobile Nav -->
    {#if mobileOpen}
      <div
        id="mobile-nav"
        class="md:hidden py-3 border-t border-[var(--fp-border)] space-y-1"
        role="tablist"
        aria-label="Mobile navigation"
      >
        {#each tabs as tab}
          <button
            role="tab"
            aria-selected={activeTab === tab.id}
            onclick={() => switchTab(tab.id)}
            class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors
              {activeTab === tab.id
                ? 'text-[var(--fp-amber)] bg-[var(--fp-amber)]/10'
                : 'text-[var(--fp-muted)] hover:text-white hover:bg-[var(--fp-surface-3)]'}"
          >
            <tab.icon size={16} />
            <span>{tab.label}</span>
            <span class="ml-auto text-[10px] text-[var(--fp-dim)] font-mono">{tab.key}</span>
          </button>
        {/each}

        {#if versionInfo?.has_update}
          <a
            href={versionInfo.update_url}
            target="_blank"
            rel="noopener noreferrer"
            class="flex items-center gap-2 px-3 py-2.5 rounded-lg text-sm font-medium text-[var(--fp-teal)] hover:bg-[var(--fp-teal)]/10 transition-colors"
          >
            <ArrowUpCircle size={16} />
            <span>Update to v{versionInfo.latest_version}</span>
          </a>
        {/if}
      </div>
    {/if}
  </nav>
</header>
