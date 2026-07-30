<script lang="ts">
  import { CheckCircle2, AlertCircle, Info, X } from 'lucide-svelte';

  export interface ToastMessage {
    id: string;
    type: 'success' | 'error' | 'info';
    text: string;
  }

  interface Props {
    toasts: ToastMessage[];
    onDismiss: (id: string) => void;
  }

  let { toasts, onDismiss }: Props = $props();
</script>

<div class="toast-container">
  {#each toasts as toast (toast.id)}
    <div class="toast-card {toast.type}">
      {#if toast.type === 'success'}
        <CheckCircle2 size={18} />
      {:else if toast.type === 'error'}
        <AlertCircle size={18} />
      {:else}
        <Info size={18} />
      {/if}

      <span class="toast-text">{toast.text}</span>

      <button class="toast-close" onclick={() => onDismiss(toast.id)}>
        <X size={14} />
      </button>
    </div>
  {/each}
</div>

<style>
  .toast-container {
    position: fixed;
    bottom: 1.5rem;
    right: 1.5rem;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    z-index: 200;
    pointer-events: none;
  }

  .toast-card {
    pointer-events: auto;
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.75rem 1rem;
    border-radius: 12px;
    font-size: 0.85rem;
    font-weight: 600;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.4);
    animation: slideIn 0.3s cubic-bezier(0.16, 1, 0.3, 1);
    max-width: 380px;
  }

  .toast-card.success {
    background: #064e3b;
    color: #6ee7b7;
    border: 1px solid rgba(52, 211, 153, 0.3);
  }

  .toast-card.error {
    background: #7f1d1d;
    color: #fca5a5;
    border: 1px solid rgba(248, 113, 113, 0.3);
  }

  .toast-card.info {
    background: #1e293b;
    color: #93c5fd;
    border: 1px solid rgba(147, 197, 253, 0.3);
  }

  .toast-text {
    flex: 1;
    line-height: 1.3;
  }

  .toast-close {
    background: transparent;
    border: none;
    color: currentColor;
    opacity: 0.7;
    cursor: pointer;
    padding: 2px;
    border-radius: 4px;
    display: flex;
  }

  .toast-close:hover {
    opacity: 1;
  }

  @keyframes slideIn {
    from { opacity: 0; transform: translateY(12px) scale(0.95); }
    to { opacity: 1; transform: translateY(0) scale(1); }
  }
</style>
