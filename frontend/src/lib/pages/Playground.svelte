<script>
  import { onMount } from 'svelte';
  import { Play, Brain } from '@lucide/svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import Alert from '../components/Alert.svelte';
  import CopyButton from '../components/CopyButton.svelte';
  import { fetchAPI } from '../utils/api.js';

  let models = $state([]);
  let selectedModel = $state('');
  let prompt = $state('');
  let output = $state('');
  let reasoning = $state('');
  let streaming = $state(false);
  let errorMsg = $state('');
  let abortController = null;

  async function fetchModels() {
    try {
      const data = await fetchAPI('/admin/api/models');
      models = data.models.map(m => m.id);
      if (models.length > 0 && !selectedModel) {
        const preferred = models.find(m => m === 'deepseek/deepseek-v4-flash') ||
                          models.find(m => m.includes('deepseek-v4-flash')) ||
                          models[0];
        selectedModel = preferred;
      }
    } catch { /* ignore */ }
  }

  async function sendPrompt(e) {
    e?.preventDefault();
    if (!prompt.trim() || streaming || !selectedModel) return;

    streaming = true;
    output = '';
    reasoning = '';
    errorMsg = '';

    abortController = new AbortController();

    try {
      const res = await fetch('/admin/playground/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'X-Requested-With': 'fetch' },
        body: JSON.stringify({ model: selectedModel, prompt: prompt.trim(), stream: true }),
        signal: abortController.signal,
      });

      if (!res.ok) {
        const errText = await res.text();
        errorMsg = `HTTP ${res.status}: ${errText}`;
        streaming = false;
        return;
      }

      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let buf = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buf += decoder.decode(value, { stream: true });

        let idx;
        while ((idx = buf.indexOf('\n\n')) >= 0) {
          const chunk = buf.slice(0, idx);
          buf = buf.slice(idx + 2);

          for (const line of chunk.split('\n')) {
            if (!line.startsWith('data:')) continue;
            const data = line.slice(5).trim();
            if (data === '[DONE]') continue;
            try {
              const obj = JSON.parse(data);
              const delta = obj.choices?.[0]?.delta;
              if (delta) {
                if (delta.reasoning_content) reasoning += delta.reasoning_content;
                if (delta.content) output += delta.content;
              }
            } catch { /* buffered partial */ }
          }
        }
      }
    } catch (err) {
      if (err.name !== 'AbortError') {
        errorMsg = `Stream failed: ${err.message}`;
      }
    } finally {
      streaming = false;
      abortController = null;
    }
  }

  function handleKeydown(e) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      e.preventDefault();
      sendPrompt();
    }
  }

  function clearAll() {
    prompt = '';
    output = '';
    reasoning = '';
    errorMsg = '';
  }

  function cancelStream() {
    if (abortController) {
      abortController.abort();
      abortController = null;
      streaming = false;
    }
  }

  onMount(() => { fetchModels(); });
</script>

<div class="space-y-6 page-enter">
  <PageHeader title="Model Playground" subtitle="Interactive prompt console with live SSE streaming and reasoning inspection" />

  <!-- Prompt Form -->
  <div class="fp-card p-5 space-y-4">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
      <div class="flex items-center gap-2">
        <label for="pg-model-select" class="text-sm font-semibold text-white">Model:</label>
        <div class="flex items-center gap-1.5">
          <select
            id="pg-model-select"
            bind:value={selectedModel}
            class="fp-input fp-input-mono text-sm w-auto"
          >
            {#each models as m}
              <option value={m}>{m}</option>
            {/each}
          </select>
          <CopyButton text={selectedModel} variant="icon" />
        </div>
      </div>
      <span class="text-xs text-[var(--fp-dim)] font-mono">Press Ctrl+Enter to send</span>
    </div>

    <textarea
      bind:value={prompt}
      onkeydown={handleKeydown}
      rows="5"
      placeholder="Ask the model anything (e.g. write an idiomatic Go concurrent worker pool)..."
      class="fp-input fp-input-mono text-sm p-3"
    ></textarea>

    <div class="flex items-center justify-end gap-2">
      <button type="button" onclick={clearAll} class="fp-btn-secondary">Clear</button>
      {#if streaming}
        <button type="button" onclick={cancelStream} class="fp-btn-danger">
          <span class="w-2 h-2 rounded-full bg-[var(--fp-red)]"></span>
          <span>Cancel</span>
        </button>
      {/if}
      <button
        type="button"
        onclick={sendPrompt}
        disabled={streaming || !prompt.trim() || !selectedModel}
        class="fp-btn-primary"
      >
        <Play size={16} />
        <span>{streaming ? 'Streaming...' : 'Send Prompt'}</span>
      </button>
    </div>
  </div>

  <!-- Error -->
  <Alert variant="error" message={errorMsg} dismissable={false} />

  <!-- Reasoning -->
  {#if reasoning}
    <details class="fp-card overflow-hidden" open>
      <summary class="p-3.5 bg-[var(--fp-input-bg)] cursor-pointer text-xs font-semibold text-[var(--fp-amber)] flex items-center justify-between select-none">
        <span class="flex items-center gap-2">
          <Brain size={14} />
          <span>Thinking Process / Reasoning ({reasoning.length} chars)</span>
        </span>
        <CopyButton text={reasoning} variant="inline" label="Copy" />
      </summary>
      <div class="p-4 text-xs font-mono text-[var(--fp-muted)] whitespace-pre-wrap leading-relaxed border-t border-[var(--fp-border)] max-h-96 overflow-y-auto">
        {reasoning}
      </div>
    </details>
  {/if}

  <!-- Output -->
  <div class="fp-card p-5 min-h-[160px]">
    <div class="text-xs font-semibold text-[var(--fp-dim)] uppercase tracking-wider mb-2 flex items-center justify-between">
      <span>Output Stream</span>
      <div class="flex items-center gap-2">
        {#if streaming}
          <span class="text-[var(--fp-teal)] flex items-center gap-1">
            <span class="w-2 h-2 rounded-full bg-[var(--fp-teal)] animate-pulse"></span>
            Streaming...
          </span>
        {/if}
        {#if output && !streaming}
          <CopyButton text={output} variant="inline" label="Copy" />
        {/if}
      </div>
    </div>
    <div class="text-sm font-mono text-[var(--fp-text)] whitespace-pre-wrap leading-relaxed">
      {#if output}
        {output}
      {:else if !streaming}
        <span class="text-[var(--fp-dim)]">// Model response will stream here in real-time...</span>
      {/if}
    </div>
  </div>
</div>
