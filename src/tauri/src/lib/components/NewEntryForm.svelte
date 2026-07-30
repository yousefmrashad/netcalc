<script lang="ts">
  import { Plus, Calculator, Check, AlertCircle, Loader2 } from 'lucide-svelte';
  import { evaluateMathExpression } from '../mathParser';
  import { supabase } from '../supabase';
  import { formatDateNow, formatUsd } from '../formatters';
  import type { Currency } from '../types';

  interface Props {
    rate: number;
    onSuccess: () => void;
    onError: (msg: string) => void;
  }

  let { rate, onSuccess, onError }: Props = $props();

  let description = $state('');
  let amountInput = $state('');
  let selectedCurrency = $state<Currency>('USD');
  let isSaving = $state(false);

  // Live Math Evaluation State
  let mathResult = $state<number | null>(null);
  let mathError = $state<string | null>(null);

  // Re-evaluate expression on input change
  $effect(() => {
    const expr = amountInput.trim();
    if (!expr) {
      mathResult = null;
      mathError = null;
      return;
    }

    let isMounted = true;
    evaluateMathExpression(expr)
      .then(res => {
        if (isMounted) {
          mathResult = res;
          mathError = null;
        }
      })
      .catch(() => {
        if (isMounted) {
          mathResult = null;
          mathError = 'Invalid math formula';
        }
      });

    return () => { isMounted = false; };
  });

  // Dynamic calculation preview
  let convertedUsd = $derived.by(() => {
    if (mathResult === null) return null;
    return selectedCurrency === 'EGP' ? mathResult / rate : mathResult;
  });

  async function handleSubmit(e: SubmitEvent) {
    e.preventDefault();

    if (!description.trim()) {
      onError('Please enter a description (e.g. Salary, Stock Profit)');
      return;
    }

    if (!amountInput.trim()) {
      onError('Please enter an amount');
      return;
    }

    let finalAmountVal: number;
    try {
      finalAmountVal = await evaluateMathExpression(amountInput);
    } catch {
      onError('Invalid mathematical expression. Example: 100 * 2.5');
      return;
    }

    if (isNaN(finalAmountVal) || !isFinite(finalAmountVal)) {
      onError('Calculation resulted in an invalid number');
      return;
    }

    // Convert EGP to base USD if EGP currency selected
    const baseAmountUsd = selectedCurrency === 'EGP' ? finalAmountVal / rate : finalAmountVal;
    const formattedDate = formatDateNow();

    isSaving = true;
    try {
      const { error } = await supabase.from('transactions').insert({
        description: description.trim(),
        amount: baseAmountUsd,
        rate: rate,
        date: formattedDate
      });

      if (error) throw error;

      // Reset form on success
      description = '';
      amountInput = '';
      mathResult = null;
      mathError = null;
      onSuccess();
    } catch (e: any) {
      console.error('Save error:', e);
      onError(e.message || 'Failed to save transaction to database. Check network connection.');
    } finally {
      isSaving = false;
    }
  }
</script>

<form class="entry-card" onsubmit={handleSubmit}>
  <div class="card-title">
    <Plus size={18} class="text-emerald-500" />
    <span>Add New Entry</span>
  </div>

  <div class="form-body">
    <!-- Description Field -->
    <div class="field-group">
      <label for="desc-input">Description</label>
      <input
        id="desc-input"
        type="text"
        placeholder="What did you add? (e.g. Salary, Freelance)"
        bind:value={description}
        disabled={isSaving}
        required
      />
    </div>

    <!-- Amount Field & Currency Toggle -->
    <div class="amount-row">
      <div class="field-group amount-field">
        <label for="amount-input">Amount (Math expression supported)</label>
        <div class="input-with-icon">
          <input
            id="amount-input"
            type="text"
            placeholder="e.g. 100 * 2.5 or 500"
            bind:value={amountInput}
            disabled={isSaving}
            required
          />
          <Calculator size={18} class="field-icon" />
        </div>
      </div>

      <!-- Currency Switcher Segment -->
      <div class="field-group currency-field">
        <span class="field-label">Currency</span>
        <div class="currency-toggle">
          <button
            type="button"
            class="toggle-btn {selectedCurrency === 'USD' ? 'active' : ''}"
            onclick={() => selectedCurrency = 'USD'}
            disabled={isSaving}
          >
            USD
          </button>
          <button
            type="button"
            class="toggle-btn {selectedCurrency === 'EGP' ? 'active' : ''}"
            onclick={() => selectedCurrency = 'EGP'}
            disabled={isSaving}
          >
            EGP
          </button>
        </div>
      </div>
    </div>

    <!-- Smart Math Expression Evaluation Pill -->
    {#if mathResult !== null}
      <div class="eval-preview success">
        <Check size={14} />
        <span>
          Evaluated: <strong>{mathResult.toFixed(2)} {selectedCurrency}</strong>
          {#if selectedCurrency === 'EGP' && convertedUsd !== null}
            &nbsp;&rarr;&nbsp; Base: <strong>{formatUsd(convertedUsd)} USD</strong> (@ {rate.toFixed(2)} rate)
          {/if}
        </span>
      </div>
    {:else if mathError}
      <div class="eval-preview error">
        <AlertCircle size={14} />
        <span>{mathError}</span>
      </div>
    {/if}

    <!-- Submit Button -->
    <button type="submit" class="submit-btn" disabled={isSaving}>
      {#if isSaving}
        <Loader2 size={18} class="animate-spin" />
        <span>Saving to Balance...</span>
      {:else}
        <Plus size={18} />
        <span>Add to Savings Balance</span>
      {/if}
    </button>
  </div>
</form>

<style>
  .entry-card {
    background: rgba(30, 41, 59, 0.6);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 20px;
    padding: 1.5rem;
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
  }

  .card-title {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.95rem;
    font-weight: 700;
    color: #f1f5f9;
    margin-bottom: 1.25rem;
  }

  .form-body {
    display: flex;
    flex-direction: column;
    gap: 1.1rem;
  }

  .field-group {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
  }

  label, .field-label {
    font-size: 0.78rem;
    font-weight: 600;
    color: #94a3b8;
  }

  input {
    background: rgba(15, 23, 42, 0.8);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    padding: 0.75rem 1rem;
    color: #ffffff;
    font-size: 0.95rem;
    outline: none;
    transition: all 0.2s ease;
  }

  input:focus {
    border-color: #10b981;
    box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.15);
  }

  .amount-row {
    display: grid;
    grid-template-columns: 1fr 140px;
    gap: 1rem;
  }

  .input-with-icon {
    position: relative;
    display: flex;
    align-items: center;
  }

  .input-with-icon input {
    width: 100%;
    padding-right: 2.5rem;
  }

  :global(.field-icon) {
    position: absolute;
    right: 0.85rem;
    color: #64748b;
    pointer-events: none;
  }

  .currency-toggle {
    display: flex;
    background: rgba(15, 23, 42, 0.8);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    padding: 3px;
    height: 44px;
  }

  .toggle-btn {
    flex: 1;
    border: none;
    background: transparent;
    color: #94a3b8;
    font-weight: 700;
    font-size: 0.82rem;
    border-radius: 9px;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .toggle-btn.active {
    background: #10b981;
    color: #ffffff;
    box-shadow: 0 2px 8px rgba(16, 185, 129, 0.4);
  }

  .eval-preview {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.6rem 0.85rem;
    border-radius: 10px;
    font-size: 0.8rem;
    animation: fadeIn 0.2s ease;
  }

  .eval-preview.success {
    background: rgba(16, 185, 129, 0.12);
    border: 1px solid rgba(16, 185, 129, 0.25);
    color: #34d399;
  }

  .eval-preview.error {
    background: rgba(239, 68, 68, 0.12);
    border: 1px solid rgba(239, 68, 68, 0.25);
    color: #f87171;
  }

  .submit-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    width: 100%;
    height: 48px;
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    border: none;
    border-radius: 12px;
    color: white;
    font-weight: 700;
    font-size: 0.95rem;
    cursor: pointer;
    transition: all 0.2s ease;
    box-shadow: 0 4px 14px rgba(16, 185, 129, 0.35);
  }

  .submit-btn:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow: 0 6px 20px rgba(16, 185, 129, 0.45);
  }

  .submit-btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  :global(.animate-spin) {
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }

  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(-4px); }
    to { opacity: 1; transform: translateY(0); }
  }

  @media (max-width: 480px) {
    .amount-row { grid-template-columns: 1fr; }
  }
</style>
