<script lang="ts">
  import { onMount } from 'svelte';
  import Navbar from '$lib/components/Navbar.svelte';
  import SummaryCard from '$lib/components/SummaryCard.svelte';
  import NewEntryForm from '$lib/components/NewEntryForm.svelte';
  import TransactionList from '$lib/components/TransactionList.svelte';
  import SettingsModal from '$lib/components/SettingsModal.svelte';
  import Toast, { type ToastMessage } from '$lib/components/Toast.svelte';
  import {
    getBackend,
    setBackend,
    listTransactions,
    deleteTransaction,
    getExchangeRateApiKey,
    type Backend
  } from '$lib/db';
  import type { Transaction } from '$lib/types';
  import type { SettingsPayload } from '$lib/components/SettingsModal.svelte';

  // Svelte 5 Reactive State Runes
  let transactions = $state<Transaction[]>([]);
  let apiRate = $state<number | null>(null);
  let manualRate = $state<number>(50.0);
  let useManualRate = $state<boolean>(false);
  let apiKey = $state<string>('');
  let backend = $state<Backend>('sqlite');
  let supabaseUrl = $state<string>('');
  let supabaseAnonKey = $state<string>('');

  let isInitialLoading = $state<boolean>(true);
  let isRefreshing = $state<boolean>(false);
  let isOffline = $state<boolean>(false);
  let isSettingsOpen = $state<boolean>(false);
  let toasts = $state<ToastMessage[]>([]);

  // Derived state: active exchange rate
  let activeRate = $derived.by(() => {
    if (useManualRate) return manualRate;
    return apiRate ?? 50.0;
  });

  // Derived state: total savings in USD
  let totalUsd = $derived.by(() => {
    return transactions.reduce((sum, item) => sum + (Number(item.amount) || 0), 0);
  });

  // Toast Helper
  function showToast(type: 'success' | 'error' | 'info', text: string) {
    const id = Math.random().toString(36).substring(2, 9);
    toasts = [...toasts, { id, type, text }];
    setTimeout(() => {
      dismissToast(id);
    }, 4000);
  }

  function dismissToast(id: string) {
    toasts = toasts.filter(t => t.id !== id);
  }

  // Load local storage cache on mount
  onMount(() => {
    // Remove static HTML splash screen as soon as Svelte mounts
    const splashLoader = document.getElementById('initial-app-loader');
    if (splashLoader) {
      splashLoader.remove();
    }

    loadCachedData();
    fetchRemoteData();
  });

  function loadCachedData() {
    try {
      const savedManualSetting = localStorage.getItem('use_manual_rate');
      if (savedManualSetting !== null) {
        useManualRate = savedManualSetting === 'true';
      }

      const savedRate = localStorage.getItem('manual_rate');
      if (savedRate !== null) {
        manualRate = parseFloat(savedRate) || 50.0;
      }

      apiKey = getExchangeRateApiKey();
      backend = getBackend();
      supabaseUrl = localStorage.getItem('supabase_url') || '';
      supabaseAnonKey = localStorage.getItem('supabase_anon_key') || '';

      const cachedJson = localStorage.getItem('cached_transactions');
      if (cachedJson) {
        const parsed = JSON.parse(cachedJson);
        if (Array.isArray(parsed)) {
          transactions = parsed;
          isInitialLoading = false;
        }
      }
    } catch (e) {
      console.warn('Failed to load local storage cache:', e);
    }
  }

  async function fetchExchangeRate(): Promise<number> {
    const key = apiKey;
    if (!key) return 50.0;

    try {
      const res = await fetch(`https://v6.exchangerate-api.com/v6/${key}/latest/USD`);
      if (res.ok) {
        const data = await res.json();
        if (data && data.conversion_rates && typeof data.conversion_rates.EGP === 'number') {
          return data.conversion_rates.EGP;
        }
      }
    } catch (e) {
      console.warn('Exchange rate API fetch failed:', e);
    }
    return 50.0;
  }

  async function fetchRemoteData() {
    isRefreshing = true;

    try {
      // Run concurrent requests for rate and database logs
      const [fetchedRate, dbData] = await Promise.all([
        fetchExchangeRate(),
        listTransactions()
      ]);

      apiRate = fetchedRate;
      transactions = dbData;
      localStorage.setItem('cached_transactions', JSON.stringify(dbData));

      isOffline = false;
    } catch (err: any) {
      console.error('Remote fetch error:', err);
      isOffline = true;
      showToast('info', 'Offline mode. Displaying cached data.');
    } finally {
      isInitialLoading = false;
      isRefreshing = false;
    }
  }

  // Handle saving new entry
  function handleEntrySuccess() {
    showToast('success', 'New transaction added to savings balance!');
    fetchRemoteData();
  }

  function handleEntryError(msg: string) {
    showToast('error', msg);
  }

  // Handle deleting entry
  async function handleDeleteEntry(id: number) {
    const previous = [...transactions];
    transactions = transactions.filter(t => t.id !== id);
    localStorage.setItem('cached_transactions', JSON.stringify(transactions));

    try {
      await deleteTransaction(id);
      showToast('success', 'Transaction deleted');
    } catch (e: any) {
      console.error('Delete error:', e);
      transactions = previous; // Rollback
      localStorage.setItem('cached_transactions', JSON.stringify(previous));
      showToast('error', 'Failed to delete transaction. Reverted change.');
    }
  }

  // Handle settings update
  async function handleSaveSettings(payload: SettingsPayload) {
    useManualRate = payload.useManualRate;
    manualRate = payload.manualRate;
    apiKey = payload.apiKey;

    localStorage.setItem('use_manual_rate', payload.useManualRate.toString());
    localStorage.setItem('manual_rate', payload.manualRate.toString());
    localStorage.setItem('exchange_rate_api_key', payload.apiKey);
    localStorage.setItem('supabase_url', payload.supabaseUrl);
    localStorage.setItem('supabase_anon_key', payload.supabaseAnonKey);

    const ok = await setBackend(payload.backend);
    backend = ok ? payload.backend : 'sqlite';

    if (ok) {
      showToast(
        'success',
        `Settings saved (${backend === 'supabase' ? 'Supabase' : 'Local SQLite'})`
      );
    } else {
      showToast('error', 'Could not connect to Supabase. Using local SQLite instead.');
    }

    fetchRemoteData();
  }

  // Export to CSV
  async function handleExportCsv() {
    if (transactions.length === 0) {
      showToast('info', 'No transactions to export.');
      return;
    }

    try {
      const header = 'Date,Description,Amount (USD),Exchange Rate\n';
      const rows = transactions.map(t => {
        const desc = `"${t.description.replace(/"/g, '""')}"`;
        const rateVal = t.rate || activeRate;
        return `${t.date},${desc},${t.amount},${rateVal}`;
      }).join('\n');

      const csvContent = header + rows;
      await navigator.clipboard.writeText(csvContent);
      showToast('success', 'Transaction history copied to clipboard as CSV!');
    } catch (e) {
      console.error('Clipboard copy failed:', e);
      showToast('error', 'Failed to copy CSV to clipboard.');
    }
  }
</script>

<svelte:head>
  <title>NetCalc - Personal Finance & Savings Tracker</title>
</svelte:head>

<div class="app-root">
  <Navbar
    rate={activeRate}
    useManualRate={useManualRate}
    isRefreshing={isRefreshing}
    isOffline={isOffline}
    onOpenSettings={() => isSettingsOpen = true}
    onRefresh={fetchRemoteData}
  />

  <main class="main-content">
    {#if isInitialLoading}
      <div class="loading-full font-inter">
        <div class="spinner"></div>
        <p>Syncing NetCalc Database...</p>
      </div>
    {:else}
      <div class="content-grid">
        <!-- Left Column: Summary & Entry Form -->
        <section class="left-column">
          <SummaryCard
            totalUsd={totalUsd}
            rate={activeRate}
            transactionCount={transactions.length}
            onOpenSettings={() => isSettingsOpen = true}
          />

          <NewEntryForm
            rate={activeRate}
            onSuccess={handleEntrySuccess}
            onError={handleEntryError}
          />
        </section>

        <!-- Right Column: Transaction History & Controls -->
        <section class="right-column">
          <TransactionList
            transactions={transactions}
            activeRate={activeRate}
            onDelete={handleDeleteEntry}
            onExportCsv={handleExportCsv}
          />
        </section>
      </div>
    {/if}
  </main>

  <!-- Settings Modal -->
  {#if isSettingsOpen}
    <SettingsModal
      useManualRate={useManualRate}
      manualRate={manualRate}
      apiRate={apiRate}
      apiKey={apiKey}
      backend={backend}
      supabaseUrl={supabaseUrl}
      supabaseAnonKey={supabaseAnonKey}
      onSave={handleSaveSettings}
      onClose={() => isSettingsOpen = false}
    />
  {/if}

  <!-- Floating Toast Notifications -->
  <Toast toasts={toasts} onDismiss={dismissToast} />
</div>

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background-color: #0b0f19;
    color: #f1f5f9;
    overflow-x: hidden;
    -webkit-font-smoothing: antialiased;
  }

  .app-root {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    background: radial-gradient(circle at 50% 0%, rgba(16, 185, 129, 0.08) 0%, rgba(11, 15, 25, 1) 70%);
  }

  .main-content {
    flex: 1;
    max-width: 1280px;
    width: 100%;
    margin: 0 auto;
    padding-top: 1.25rem;
    padding-bottom: max(1.75rem, env(safe-area-inset-bottom));
    padding-left: max(1.5rem, env(safe-area-inset-left));
    padding-right: max(1.5rem, env(safe-area-inset-right));
    box-sizing: border-box;
  }

  .loading-full {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 50vh;
    gap: 1rem;
    color: #94a3b8;
    font-weight: 500;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 3px solid rgba(16, 185, 129, 0.2);
    border-top-color: #10b981;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  .content-grid {
    display: grid;
    grid-template-columns: 440px 1fr;
    gap: 1.5rem;
    align-items: start;
  }

  .left-column {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
  }

  .right-column {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  @media (max-width: 1024px) {
    .content-grid {
      grid-template-columns: 1fr;
    }
  }

  @media (max-width: 640px) {
    .main-content {
      padding-top: 1rem;
      padding-bottom: max(1.25rem, env(safe-area-inset-bottom));
      padding-left: max(0.85rem, env(safe-area-inset-left));
      padding-right: max(0.85rem, env(safe-area-inset-right));
    }
  }
</style>
