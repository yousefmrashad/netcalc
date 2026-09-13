<script lang="ts">
  import { X, Settings, RefreshCw, Check, Database, Cloud } from 'lucide-svelte';

  export interface SettingsPayload {
    useManualRate: boolean;
    manualRate: number;
    apiKey: string;
    backend: 'sqlite' | 'supabase';
    supabaseUrl: string;
    supabaseAnonKey: string;
  }

  interface Props {
    useManualRate: boolean;
    manualRate: number;
    apiRate: number | null;
    apiKey: string;
    backend: 'sqlite' | 'supabase';
    supabaseUrl: string;
    supabaseAnonKey: string;
    onSave: (payload: SettingsPayload) => void;
    onClose: () => void;
  }

  let {
    useManualRate,
    manualRate,
    apiRate,
    apiKey,
    backend,
    supabaseUrl,
    supabaseAnonKey,
    onSave,
    onClose
  }: Props = $props();

  let selectedUseManual = $state(false);
  let customRateInput = $state('50.0');
  let apiKeyInput = $state('');
  let selectedBackend = $state<'sqlite' | 'supabase'>('sqlite');
  let urlInput = $state('');
  let anonKeyInput = $state('');

  $effect(() => {
    selectedUseManual = useManualRate;
    customRateInput = manualRate.toString();
    apiKeyInput = apiKey;
    selectedBackend = backend;
    urlInput = supabaseUrl;
    anonKeyInput = supabaseAnonKey;
  });

  function handleSave() {
    const parsed = parseFloat(customRateInput);
    const validRate = isNaN(parsed) || parsed <= 0 ? 50.0 : parsed;
    onSave({
      useManualRate: selectedUseManual,
      manualRate: validRate,
      apiKey: apiKeyInput.trim(),
      backend: selectedBackend,
      supabaseUrl: urlInput.trim(),
      supabaseAnonKey: anonKeyInput.trim()
    });
    onClose();
  }

  function handleKeyDown(e: KeyboardEvent) {
    if (e.key === 'Escape') {
      onClose();
    }
  }
</script>

<div
  class="modal-overlay"
  onclick={onClose}
  onkeydown={handleKeyDown}
  role="button"
  tabindex="0"
>
  <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
  <div
    class="modal-card"
    onclick={(e) => e.stopPropagation()}
    onkeydown={(e) => e.stopPropagation()}
    role="dialog"
    aria-modal="true"
    tabindex="-1"
  >
    <div class="modal-header">
      <div class="header-title">
        <Settings size={20} class="settings-icon" />
        <h3>Exchange Rate Settings</h3>
      </div>
      <button class="close-btn" onclick={onClose} aria-label="Close settings">
        <X size={18} />
      </button>
    </div>

    <div class="modal-body">
      <p class="section-desc">
        Configure how NetCalc calculates live EGP currency conversions.
      </p>

      <!-- Toggle Mode: Auto vs Manual -->
      <div class="mode-selector">
        <button
          type="button"
          class="mode-btn {!selectedUseManual ? 'active' : ''}"
          onclick={() => selectedUseManual = false}
        >
          <RefreshCw size={16} />
          <span>Auto (Live API)</span>
        </button>
        <button
          type="button"
          class="mode-btn {selectedUseManual ? 'active' : ''}"
          onclick={() => selectedUseManual = true}
        >
          <Check size={16} />
          <span>Manual Override</span>
        </button>
      </div>

      <!-- Current API Rate Display -->
      <div class="info-box">
        <span class="info-label">Live API Exchange Rate:</span>
        <span class="info-value">
          {apiRate !== null ? `1 USD = ${apiRate.toFixed(2)} EGP` : 'Loading / Unavailable (Using 50.00 fallback)'}
        </span>
      </div>

      <!-- Manual Rate Input -->
      {#if selectedUseManual}
        <div class="field-group">
          <label for="manual-rate-input">Custom Manual Rate (EGP per 1 USD)</label>
          <input
            id="manual-rate-input"
            type="number"
            step="0.01"
            placeholder="e.g. 50.00"
            bind:value={customRateInput}
          />
        </div>
      {/if}

      <!-- Exchange Rate API Key -->
      <div class="field-group">
        <label for="api-key-input">ExchangeRate-API Key</label>
        <input
          id="api-key-input"
          type="text"
          placeholder="Leave empty to use the free tier"
          bind:value={apiKeyInput}
        />
      </div>

      <!-- Storage Backend -->
      <div class="storage-section">
        <span class="storage-title">Storage</span>
        <p class="storage-desc">
          Choose where transactions are saved. Supabase requires a URL and anon key.
        </p>
        <div class="mode-selector">
          <button
            type="button"
            class="mode-btn {selectedBackend === 'sqlite' ? 'active' : ''}"
            onclick={() => selectedBackend = 'sqlite'}
          >
            <Database size={16} />
            <span>Local (SQLite)</span>
          </button>
          <button
            type="button"
            class="mode-btn {selectedBackend === 'supabase' ? 'active' : ''}"
            onclick={() => selectedBackend = 'supabase'}
          >
            <Cloud size={16} />
            <span>Supabase</span>
          </button>
        </div>

        {#if selectedBackend === 'supabase'}
          <div class="field-group">
            <label for="supabase-url-input">Supabase URL</label>
            <input
              id="supabase-url-input"
              type="text"
              placeholder="https://xxxx.supabase.co"
              bind:value={urlInput}
            />
          </div>
          <div class="field-group">
            <label for="supabase-key-input">Supabase Anon Key</label>
            <input
              id="supabase-key-input"
              type="text"
              bind:value={anonKeyInput}
            />
          </div>
          <p class="storage-desc">
            Note: credential changes take effect after restarting the app.
          </p>
        {/if}
      </div>
    </div>

    <div class="modal-footer">
      <button class="cancel-btn" onclick={onClose}>Cancel</button>
      <button class="save-btn" onclick={handleSave}>Save Settings</button>
    </div>
  </div>
</div>

<style>
  .modal-overlay {
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0, 0, 0, 0.75);
    backdrop-filter: blur(8px);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 100;
    padding: 1rem;
  }

  .modal-card {
    background: #1e293b;
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 20px;
    width: 100%;
    max-width: 440px;
    overflow: hidden;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.6);
  }

  .modal-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1.25rem 1.5rem;
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  }

  .header-title {
    display: flex;
    align-items: center;
    gap: 0.6rem;
  }

  :global(.settings-icon) {
    color: #10b981;
  }

  .header-title h3 {
    margin: 0;
    font-size: 1.1rem;
    color: #f1f5f9;
  }

  .close-btn {
    background: transparent;
    border: none;
    color: #94a3b8;
    cursor: pointer;
    padding: 4px;
    border-radius: 8px;
    display: flex;
  }

  .close-btn:hover {
    color: #ffffff;
    background: rgba(255, 255, 255, 0.1);
  }

  .modal-body {
    padding: 1.5rem;
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
  }

  .section-desc {
    margin: 0;
    font-size: 0.85rem;
    color: #94a3b8;
  }

  .mode-selector {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.6rem;
    background: rgba(15, 23, 42, 0.6);
    padding: 4px;
    border-radius: 12px;
    border: 1px solid rgba(255, 255, 255, 0.08);
  }

  .mode-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.4rem;
    padding: 0.65rem;
    border: none;
    background: transparent;
    color: #94a3b8;
    font-weight: 600;
    font-size: 0.85rem;
    border-radius: 9999px;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .mode-btn.active {
    background: #10b981;
    color: #ffffff;
    box-shadow: 0 2px 10px rgba(16, 185, 129, 0.35);
  }

  .info-box {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: rgba(15, 23, 42, 0.6);
    padding: 0.85rem 1rem;
    border-radius: 12px;
    border: 1px solid rgba(255, 255, 255, 0.06);
    font-size: 0.82rem;
  }

  .info-label {
    color: #94a3b8;
  }

  .info-value {
    color: #34d399;
    font-weight: 600;
  }

  .field-group {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
  }

  label {
    font-size: 0.8rem;
    font-weight: 600;
    color: #cbd5e1;
  }

  input {
    background: rgba(15, 23, 42, 0.8);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    padding: 0.75rem 1rem;
    color: #ffffff;
    font-size: 0.95rem;
    outline: none;
  }

  input:focus {
    border-color: #10b981;
  }

  .storage-section {
    display: flex;
    flex-direction: column;
    gap: 0.6rem;
    padding-top: 0.25rem;
  }

  .storage-title {
    font-size: 0.85rem;
    font-weight: 700;
    color: #cbd5e1;
  }

  .storage-desc {
    margin: 0;
    font-size: 0.78rem;
    color: #64748b;
  }

  .modal-footer {
    display: flex;
    justify-content: flex-end;
    gap: 0.75rem;
    padding: 1.25rem 1.5rem;
    border-top: 1px solid rgba(255, 255, 255, 0.08);
  }

  .cancel-btn {
    background: rgba(51, 65, 85, 0.8);
    border: 1px solid rgba(255, 255, 255, 0.1);
    color: #cbd5e1;
    padding: 0.6rem 1.1rem;
    border-radius: 10px;
    font-weight: 600;
    cursor: pointer;
  }

  .save-btn {
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    border: none;
    color: white;
    padding: 0.6rem 1.1rem;
    border-radius: 10px;
    font-weight: 600;
    cursor: pointer;
  }
</style>
