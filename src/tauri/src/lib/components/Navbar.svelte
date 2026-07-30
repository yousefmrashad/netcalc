<script lang="ts">
  import { Settings, RefreshCw, Wifi, WifiOff, DollarSign } from 'lucide-svelte';

  interface Props {
    rate: number;
    useManualRate: boolean;
    isRefreshing: boolean;
    isOffline: boolean;
    onOpenSettings: () => void;
    onRefresh: () => void;
  }

  let { rate, useManualRate, isRefreshing, isOffline, onOpenSettings, onRefresh }: Props = $props();
</script>

<header class="navbar">
  <div class="brand">
    <div class="logo-badge">
      <DollarSign size={20} class="brand-icon" />
    </div>
    <div class="brand-info">
      <h1>NetCalc</h1>
      <span class="subtitle">Savings & Currency Tracker</span>
    </div>
  </div>

  <div class="nav-actions">
    <!-- Live Exchange Rate Badge (Desktop View) -->
    <button class="rate-badge" onclick={onOpenSettings} title="Click to edit exchange rate settings">
      <span class="rate-dot {useManualRate ? 'manual' : 'auto'}"></span>
      <span class="rate-label">{useManualRate ? 'MANUAL' : 'AUTO'}</span>
      <span class="rate-value">1 USD = {rate.toFixed(2)} EGP</span>
    </button>

    <!-- Network Status Pill -->
    {#if isOffline}
      <div class="status-pill offline" title="Offline mode - using cached data">
        <WifiOff size={14} />
        <span>Offline</span>
      </div>
    {:else}
      <div class="status-pill online" title="Connected to Supabase database">
        <Wifi size={14} />
        <span>Synced</span>
      </div>
    {/if}

    <!-- Refresh Button -->
    <button 
      class="icon-btn {isRefreshing ? 'spin' : ''}" 
      onclick={onRefresh} 
      disabled={isRefreshing}
      title="Refresh rates & transaction logs"
    >
      <RefreshCw size={18} />
    </button>

    <!-- Settings Button -->
    <button class="icon-btn" onclick={onOpenSettings} title="Exchange Rate Settings">
      <Settings size={18} />
    </button>
  </div>
</header>

<style>
  .navbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-top: max(1.1rem, calc(env(safe-area-inset-top) + 0.6rem));
    padding-bottom: 1.1rem;
    padding-left: max(1.5rem, env(safe-area-inset-left));
    padding-right: max(1.5rem, env(safe-area-inset-right));
    background: rgba(18, 22, 34, 0.85);
    backdrop-filter: blur(16px);
    -webkit-backdrop-filter: blur(16px);
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
    position: sticky;
    top: 0;
    z-index: 50;
  }

  .brand {
    display: flex;
    align-items: center;
    gap: 0.75rem;
  }

  .logo-badge {
    width: 38px;
    height: 38px;
    border-radius: 12px;
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    box-shadow: 0 4px 14px rgba(16, 185, 129, 0.35);
  }

  .brand-info h1 {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 800;
    letter-spacing: -0.02em;
    background: linear-gradient(135deg, #ffffff 0%, #cbd5e1 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }

  .brand-info .subtitle {
    font-size: 0.7rem;
    color: #94a3b8;
    display: block;
    font-weight: 500;
  }

  .nav-actions {
    display: flex;
    align-items: center;
    gap: 0.6rem;
  }

  .rate-badge {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.4rem 0.8rem;
    background: rgba(30, 41, 59, 0.8);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 9999px;
    color: #f1f5f9;
    font-size: 0.8rem;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .rate-badge:hover {
    background: rgba(51, 65, 85, 0.9);
    border-color: rgba(16, 185, 129, 0.4);
    transform: translateY(-1px);
  }

  .rate-dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
  }

  .rate-dot.auto {
    background: #10b981;
    box-shadow: 0 0 8px #10b981;
  }

  .rate-dot.manual {
    background: #f59e0b;
    box-shadow: 0 0 8px #f59e0b;
  }

  .rate-label {
    font-size: 0.65rem;
    font-weight: 700;
    color: #94a3b8;
    letter-spacing: 0.05em;
  }

  .rate-value {
    font-weight: 600;
  }

  .status-pill {
    display: flex;
    align-items: center;
    gap: 0.35rem;
    padding: 0.38rem 0.65rem;
    border-radius: 9999px;
    font-size: 0.72rem;
    font-weight: 600;
  }

  .status-pill.online {
    background: rgba(16, 185, 129, 0.12);
    color: #34d399;
    border: 1px solid rgba(16, 185, 129, 0.25);
  }

  .status-pill.offline {
    background: rgba(239, 68, 68, 0.12);
    color: #f87171;
    border: 1px solid rgba(239, 68, 68, 0.25);
  }

  .icon-btn {
    width: 36px;
    height: 36px;
    border-radius: 10px;
    background: rgba(30, 41, 59, 0.7);
    border: 1px solid rgba(255, 255, 255, 0.08);
    color: #cbd5e1;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .icon-btn:hover:not(:disabled) {
    background: rgba(51, 65, 85, 0.9);
    color: #ffffff;
    border-color: rgba(255, 255, 255, 0.2);
  }

  .icon-btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .spin {
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }

  @media (max-width: 640px) {
    .rate-badge { display: none; }
    .status-pill span { display: none; }
    .brand-info .subtitle { display: none; }
    .navbar {
      padding-left: max(1rem, env(safe-area-inset-left));
      padding-right: max(1rem, env(safe-area-inset-right));
    }
  }
</style>
