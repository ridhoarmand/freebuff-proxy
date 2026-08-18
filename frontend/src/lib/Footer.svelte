<script>
  import { ExternalLink } from '@lucide/svelte';
</script>

<footer class="border-t border-[var(--fp-border)] mt-12">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 py-4 flex items-center justify-between text-xs text-[var(--fp-dim)]">
    <span class="font-mono">freebuff-proxy</span>
    <div class="flex items-center gap-4">
      <a
        href="/healthz"
        target="_blank"
        rel="noopener noreferrer"
        class="inline-flex items-center gap-1 hover:text-[var(--fp-muted)] transition-colors"
      >
        /healthz
        <ExternalLink size={10} />
      </a>
      <a
        href="/metrics"
        target="_blank"
        rel="noopener noreferrer"
        class="inline-flex items-center gap-1 hover:text-[var(--fp-muted)] transition-colors"
      >
        /metrics
        <ExternalLink size={10} />
      </a>
    </div>
  </div>
</footer>
