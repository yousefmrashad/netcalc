<script lang="ts">
  import { Wallet, TrendingUp, ArrowRightLeft } from 'lucide-svelte';
  import { formatUsd, formatEgp } from '../formatters';

  interface Props {
    totalUsd: number;
    rate: number;
    transactionCount: number;
    onOpenSettings: () => void;
  }

  let { totalUsd, rate, transactionCount, onOpenSettings }: Props = $props();

  let totalEgp = $derived(totalUsd * rate);
</script>

<div class="summary-card">
  <div class="card-bg-gradient"></div>
  
  <div class="card-header">
    <div class="header-left">
      <div class="icon-wrapper">
        <Wallet size={22} />
      </div>
      <div>
        <span class="card-title">Total Savings</span>
        <span class="card-subtitle">{transactionCount} {transactionCount === 1 ? 'transaction' : 'transactions'} logged</span>
      </div>
    </div>

    <button class="rate-toggle-btn" onclick={onOpenSettings} title="Change Exchange Rate">
      <ArrowRightLeft size={14} />
      <span>1 USD = {rate.toFixed(2)} EGP</span>
    </button>
  </div>

  <div class="balance-display">
    <div class="usd-amount">{formatUsd(totalUsd)}</div>
    <div class="egp-amount">
      <TrendingUp size={16} class="trend-icon" />
      <span>{formatEgp(totalEgp)}</span>
    </div>
  </div>

  <div class="card-footer">
    <div class="base-badge">
      <span>Base Currency: <strong>USD</strong></span>
    </div>
    <div class="rate-info">
      <span>Stored & Normalized in USD</span>
    </div>
  </div>
</div>

<style>
  .summary-card {
    position: relative;
    background: linear-gradient(135deg, rgba(16, 185, 129, 0.15) 0%, rgba(15, 23, 42, 0.8) 100%);
    border: 1px solid rgba(16, 185, 129, 0.25);
    border-radius: 20px;
    padding: 1.75rem;
    overflow: hidden;
    box-shadow: 0 10px 30px -10px rgba(0, 0, 0, 0.5), inset 0 1px 0 rgba(255, 255, 255, 0.1);
  }

  .card-bg-gradient {
    position: absolute;
    top: -50%;
    right: -20%;
    width: 280px;
    height: 280px;
    background: radial-gradient(circle, rgba(16, 185, 129, 0.25) 0%, rgba(0, 0, 0, 0) 70%);
    pointer-events: none;
    filter: blur(40px);
  }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.25rem;
  }

  .header-left {
    display: flex;
    align-items: center;
    gap: 0.75rem;
  }

  .icon-wrapper {
    width: 42px;
    height: 42px;
    border-radius: 12px;
    background: rgba(16, 185, 129, 0.2);
    color: #34d399;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1px solid rgba(16, 185, 129, 0.3);
  }

  .card-title {
    display: block;
    font-size: 0.85rem;
    font-weight: 600;
    color: #94a3b8;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .card-subtitle {
    font-size: 0.78rem;
    color: #64748b;
  }

  .rate-toggle-btn {
    display: flex;
    align-items: center;
    gap: 0.4rem;
    background: rgba(30, 41, 59, 0.6);
    border: 1px solid rgba(255, 255, 255, 0.1);
    color: #cbd5e1;
    padding: 0.4rem 0.75rem;
    border-radius: 9999px;
    font-size: 0.78rem;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .rate-toggle-btn:hover {
    background: rgba(51, 65, 85, 0.8);
    border-color: rgba(16, 185, 129, 0.4);
    color: #ffffff;
  }

  .balance-display {
    margin-bottom: 1.25rem;
  }

  .usd-amount {
    font-size: 2.75rem;
    font-weight: 800;
    letter-spacing: -0.03em;
    color: #ffffff;
    line-height: 1.1;
    text-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
  }

  .egp-amount {
    display: flex;
    align-items: center;
    gap: 0.4rem;
    margin-top: 0.4rem;
    font-size: 1.15rem;
    font-weight: 600;
    color: #34d399;
  }

  .card-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-top: 1rem;
    border-top: 1px solid rgba(255, 255, 255, 0.08);
    font-size: 0.78rem;
    color: #94a3b8;
  }

  .base-badge strong {
    color: #10b981;
  }

  @media (max-width: 480px) {
    .usd-amount { font-size: 2.1rem; }
    .card-header { flex-direction: column; align-items: flex-start; gap: 0.75rem; }
  }
</style>
