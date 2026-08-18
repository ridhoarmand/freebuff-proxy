<script>
  /**
   * StatusBadge — consistent status pill used throughout the dashboard.
   *
   * @prop {'amber'|'teal'|'red'|'blue'|'purple'|'muted'} [variant='muted']
   * @prop {boolean} [uppercase=true]
   * @prop {boolean} [mono=false]
   */
  let { variant = 'muted', uppercase = true, mono = false, children } = $props();

  const styles = {
    amber:  'bg-[var(--fp-amber)]/15 text-[var(--fp-amber)] border-[var(--fp-amber)]/30',
    teal:   'bg-[var(--fp-teal)]/15 text-[var(--fp-teal)] border-[var(--fp-teal)]/30',
    red:    'bg-[var(--fp-red)]/15 text-[var(--fp-red)] border-[var(--fp-red)]/30',
    blue:   'bg-[#60A5FA]/15 text-[#60A5FA] border-[#60A5FA]/30',
    purple: 'bg-[#AC94FA]/15 text-[#AC94FA] border-[#AC94FA]/30',
    muted:  'bg-[var(--fp-border)] text-[var(--fp-muted)] border-[var(--fp-border-bright)]',
  };
</script>

<span
  class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border transition-colors
    {uppercase ? 'uppercase tracking-wider' : ''}
    {mono ? 'font-mono' : ''}
    {styles[variant] || styles.muted}"
>
  {@render children()}
</span>
