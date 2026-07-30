<script lang="ts">
  import { Search, X, Download, Trash2, Calendar, FileText, AlertTriangle, Layers } from 'lucide-svelte';
  import { formatUsd, formatEgp } from '../formatters';
  import type { Transaction } from '../types';

  interface Props {
    transactions: Transaction[];
    activeRate: number;
    onDelete: (id: number) => void;
    onExportCsv: () => void;
  }

  let { transactions, activeRate, onDelete, onExportCsv }: Props = $props();

  let searchQuery = $state('');
  let itemToDelete = $state<Transaction | null>(null);

  // Filter transactions dynamically with Svelte 5 $derived
  let filteredTransactions = $derived.by(() => {
    const q = searchQuery.toLowerCase().trim();
    if (!q) return transactions;

    return transactions.filter(trx => {
      const desc = (trx.description || '').toLowerCase();
      const date = (trx.date || '').toLowerCase();
      const amountStr = trx.amount.toString();
      const egpStr = (trx.amount * (trx.rate || activeRate)).toFixed(2);

      return desc.includes(q) || date.includes(q) || amountStr.includes(q) || egpStr.includes(q);
    });
  });

  function confirmDelete(trx: Transaction) {
    itemToDelete = trx;
  }

  function handleExecuteDelete() {
    if (itemToDelete) {
      onDelete(itemToDelete.id);
      itemToDelete = null;
    }
  }

  function handleModalKeyDown(e: KeyboardEvent) {
    if (e.key === 'Escape') {
      itemToDelete = null;
    }
  }
</script>

<div class="list-container">
  <!-- List Control Bar: Search & Export -->
  <div class="control-bar">
    <div class="search-input-wrapper">
      <Search size={18} class="search-icon" />
      <input
        type="text"
        placeholder="Search history by description, date, or amount..."
        bind:value={searchQuery}
      />
      {#if searchQuery}
        <button class="clear-btn" onclick={() => searchQuery = ''} title="Clear search">
          <X size={16} />
        </button>
      {/if}
    </div>

    <button class="export-btn" onclick={onExportCsv} title="Export CSV to Clipboard">
      <Download size={16} />
      <span>Export CSV</span>
    </button>
  </div>

  <!-- Transaction Items List -->
  {#if filteredTransactions.length === 0}
    <div class="empty-state">
      <div class="empty-icon-wrapper">
        {#if searchQuery}
          <Search size={32} />
        {:else}
          <Layers size={32} />
        {/if}
      </div>
      <h3>{searchQuery ? 'No matching transactions' : 'No transactions recorded yet'}</h3>
      <p>
        {searchQuery
          ? `No entries match "${searchQuery}". Try searching with a different term.`
          : 'Use the form above to add your first transaction to NetCalc.'}
      </p>
    </div>
  {:else}
    <div class="items-grid">
      {#each filteredTransactions as trx (trx.id)}
        <div class="trx-card">
          <!-- Icon -->
          <div class="trx-icon">
            <FileText size={18} />
          </div>

          <!-- Left Info: Description & Meta -->
          <div class="trx-info">
            <h4 class="trx-desc">{trx.description}</h4>
            <div class="trx-meta">
              <Calendar size={11} class="meta-icon" />
              <span class="trx-date">{trx.date}</span>
              <span class="trx-rate-pill">@{(trx.rate || activeRate).toFixed(2)}</span>
            </div>
          </div>

          <!-- Right Amounts: USD & EGP strictly right-aligned -->
          <div class="trx-amounts">
            <span class="usd-val">{formatUsd(trx.amount)}</span>
            <span class="egp-val">{formatEgp(trx.amount * (trx.rate || activeRate))}</span>
          </div>

          <!-- Action: Delete -->
          <button
            class="delete-btn"
            onclick={() => confirmDelete(trx)}
            title="Delete transaction"
          >
            <Trash2 size={15} />
          </button>
        </div>
      {/each}
    </div>
  {/if}
</div>

<!-- Delete Confirmation Modal -->
{#if itemToDelete !== null}
  <div
    class="modal-overlay"
    onclick={() => itemToDelete = null}
    onkeydown={handleModalKeyDown}
    role="button"
    tabindex="0"
  >
    <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
    <div
      class="modal-content"
      onclick={(e) => e.stopPropagation()}
      onkeydown={(e) => e.stopPropagation()}
      role="dialog"
      aria-modal="true"
      tabindex="-1"
    >
      <div class="modal-header">
        <div class="alert-icon">
          <AlertTriangle size={24} />
        </div>
        <h3>Delete Transaction</h3>
      </div>
      <p>
        Are you sure you want to delete <strong>"{itemToDelete.description}"</strong> ({formatUsd(itemToDelete.amount)})?
        This action cannot be undone.
      </p>
      <div class="modal-actions">
        <button class="cancel-btn" onclick={() => itemToDelete = null}>Cancel</button>
        <button class="confirm-delete-btn" onclick={handleExecuteDelete}>Delete Entry</button>
      </div>
    </div>
  </div>
{/if}

<style>
  .list-container {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
  }

  .control-bar {
    display: flex;
    gap: 0.75rem;
  }

  .search-input-wrapper {
    position: relative;
    flex: 1;
    display: flex;
    align-items: center;
  }

  .search-input-wrapper input {
    width: 100%;
    background: rgba(30, 41, 59, 0.6);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 14px;
    padding: 0.7rem 2.5rem;
    color: #ffffff;
    font-size: 0.9rem;
    outline: none;
    transition: all 0.2s ease;
  }

  .search-input-wrapper input:focus {
    border-color: #10b981;
    background: rgba(15, 23, 42, 0.8);
    box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.15);
  }

  :global(.search-icon) {
    position: absolute;
    left: 0.85rem;
    color: #64748b;
    pointer-events: none;
  }

  .clear-btn {
    position: absolute;
    right: 0.75rem;
    background: transparent;
    border: none;
    color: #94a3b8;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2px;
    border-radius: 50%;
  }

  .clear-btn:hover {
    color: #ffffff;
    background: rgba(255, 255, 255, 0.1);
  }

  .export-btn {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    background: rgba(30, 41, 59, 0.7);
    border: 1px solid rgba(255, 255, 255, 0.1);
    color: #cbd5e1;
    padding: 0.7rem 1.1rem;
    border-radius: 14px;
    font-weight: 600;
    font-size: 0.85rem;
    cursor: pointer;
    white-space: nowrap;
    transition: all 0.2s ease;
  }

  .export-btn:hover {
    background: rgba(51, 65, 85, 0.9);
    color: #ffffff;
    border-color: rgba(16, 185, 129, 0.4);
  }

  .empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 4rem 2rem;
    background: rgba(30, 41, 59, 0.3);
    border: 1px dashed rgba(255, 255, 255, 0.1);
    border-radius: 20px;
    text-align: center;
  }

  .empty-icon-wrapper {
    width: 64px;
    height: 64px;
    border-radius: 20px;
    background: rgba(30, 41, 59, 0.6);
    color: #64748b;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 1rem;
  }

  .empty-state h3 {
    margin: 0 0 0.4rem 0;
    font-size: 1.1rem;
    color: #f1f5f9;
  }

  .empty-state p {
    margin: 0;
    font-size: 0.85rem;
    color: #94a3b8;
    max-width: 360px;
  }

  .items-grid {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  /* Pixel-Perfect Right-Aligned Amounts Card Structure */
  .trx-card {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.85rem 1rem;
    background: rgba(30, 41, 59, 0.5);
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 16px;
    transition: all 0.2s ease;
  }

  .trx-card:hover {
    background: rgba(30, 41, 59, 0.8);
    border-color: rgba(255, 255, 255, 0.12);
  }

  .trx-icon {
    width: 38px;
    height: 38px;
    border-radius: 11px;
    background: rgba(16, 185, 129, 0.12);
    color: #34d399;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  /* Left Column: Description & Date/Rate */
  .trx-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
    min-width: 0;
  }

  .trx-desc {
    margin: 0;
    font-size: 0.95rem;
    font-weight: 700;
    color: #f1f5f9;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    line-height: 1.25;
  }

  .trx-meta {
    display: flex;
    align-items: center;
    gap: 0.35rem;
    font-size: 0.72rem;
    color: #94a3b8;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    line-height: 1.2;
  }

  :global(.meta-icon) {
    flex-shrink: 0;
  }

  .trx-date {
    white-space: nowrap;
  }

  .trx-rate-pill {
    background: rgba(15, 23, 42, 0.7);
    padding: 0.1rem 0.38rem;
    border-radius: 5px;
    font-size: 0.65rem;
    color: #cbd5e1;
    font-weight: 600;
    flex-shrink: 0;
  }

  /* Right Column: USD & EGP Amounts strictly right-aligned to each other */
  .trx-amounts {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    text-align: right;
    gap: 0.15rem;
    flex-shrink: 0;
    line-height: 1.2;
  }

  .usd-val {
    font-size: 1rem;
    font-weight: 800;
    color: #10b981;
    white-space: nowrap;
  }

  .egp-val {
    font-size: 0.75rem;
    color: #94a3b8;
    font-weight: 500;
    white-space: nowrap;
  }

  .delete-btn {
    background: transparent;
    border: none;
    color: #64748b;
    padding: 0.35rem;
    border-radius: 8px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    transition: all 0.2s ease;
    margin-left: 0.25rem;
  }

  .delete-btn:hover {
    background: rgba(239, 68, 68, 0.15);
    color: #ef4444;
  }

  /* Delete Confirmation Modal */
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

  .modal-content {
    background: #1e293b;
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 20px;
    padding: 1.75rem;
    max-width: 420px;
    width: 100%;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.6);
  }

  .modal-header {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    margin-bottom: 1rem;
  }

  .alert-icon {
    width: 40px;
    height: 40px;
    border-radius: 12px;
    background: rgba(239, 68, 68, 0.15);
    color: #ef4444;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .modal-header h3 {
    margin: 0;
    font-size: 1.15rem;
    color: #f1f5f9;
  }

  .modal-content p {
    color: #cbd5e1;
    font-size: 0.9rem;
    line-height: 1.5;
    margin-bottom: 1.5rem;
  }

  .modal-actions {
    display: flex;
    justify-content: flex-end;
    gap: 0.75rem;
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

  .confirm-delete-btn {
    background: #ef4444;
    border: none;
    color: white;
    padding: 0.6rem 1.1rem;
    border-radius: 10px;
    font-weight: 600;
    cursor: pointer;
  }

  @media (max-width: 480px) {
    .control-bar { flex-direction: column; }
  }
</style>
