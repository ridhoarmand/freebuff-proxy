<script>
  import { onMount } from 'svelte';
  import Navbar from './lib/Navbar.svelte';
  import Footer from './lib/Footer.svelte';
  import Overview from './lib/pages/Overview.svelte';
  import Tokens from './lib/pages/Tokens.svelte';
  import Models from './lib/pages/Models.svelte';
  import Traces from './lib/pages/Traces.svelte';
  import Playground from './lib/pages/Playground.svelte';
  import Config from './lib/pages/Config.svelte';
  import Setup from './lib/pages/Setup.svelte';
  import Logs from './lib/pages/Logs.svelte';
  import Metrics from './lib/pages/Metrics.svelte';
  import Login from './lib/pages/Login.svelte';

  let activeTab = $state('overview');
  let versionInfo = $state(null);

  function syncTabFromURL() {
    const path = window.location.pathname;
    const hash = window.location.hash.replace('#', '');
    
    if (path === '/admin/login' || hash === 'login') {
      activeTab = 'login';
      return;
    }

    if (hash) {
      activeTab = hash;
      return;
    }

    const segments = path.split('/').filter(Boolean);
    if (segments.length >= 2 && segments[0] === 'admin') {
      activeTab = segments[1] || 'overview';
    } else {
      activeTab = 'overview';
    }
  }

  $effect(() => {
    if (activeTab !== 'login') {
      window.location.hash = activeTab;
    }
  });

  onMount(() => {
    syncTabFromURL();
    window.addEventListener('hashchange', syncTabFromURL);

    // Fetch version / update check
    fetch('/admin/api/version')
      .then((res) => res.json())
      .then((data) => {
        versionInfo = {
          has_update: data.has_update || false,
          latest_version: data.latest_version || '',
          update_url: data.update_url || '',
        };
      })
      .catch(() => {});

    return () => {
      window.removeEventListener('hashchange', syncTabFromURL);
    };
  });
</script>

<div class="min-h-screen bg-[var(--fp-bg)] text-[var(--fp-text)] flex flex-col font-sans selection:bg-[var(--fp-amber)]/30 selection:text-white">
  {#if activeTab !== 'login'}
    <Navbar bind:activeTab {versionInfo} />
  {/if}

  <main class="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8">
    {#if activeTab === 'overview'}
      <Overview />
    {:else if activeTab === 'tokens'}
      <Tokens />
    {:else if activeTab === 'models'}
      <Models />
    {:else if activeTab === 'traces'}
      <Traces />
    {:else if activeTab === 'playground'}
      <Playground />
    {:else if activeTab === 'config'}
      <Config />
    {:else if activeTab === 'setup'}
      <Setup />
    {:else if activeTab === 'logs'}
      <Logs />
    {:else if activeTab === 'metrics'}
      <Metrics />
    {:else if activeTab === 'login'}
      <Login />
    {/if}
  </main>

  {#if activeTab !== 'login'}
    <Footer />
  {/if}
</div>
