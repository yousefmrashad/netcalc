import Database from '@tauri-apps/plugin-sql';
import { getSupabase } from './supabase';
import type { Transaction } from './types';

export type Backend = 'sqlite' | 'supabase';

export function getBackend(): Backend {
  const stored = localStorage.getItem('storage_backend');
  return stored === 'supabase' ? 'supabase' : 'sqlite';
}

let sqliteDb: Database | null = null;

async function getSqlite(): Promise<Database> {
  if (!sqliteDb) {
    sqliteDb = await Database.load('sqlite:netcalc.db');
    await sqliteDb.execute(`
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        rate REAL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    `);
  }
  return sqliteDb;
}

/**
 * Switches the active storage backend. When selecting Supabase, the
 * credentials are validated first; on failure the selection falls back
 * to SQLite and `false` is returned.
 */
export async function setBackend(backend: Backend): Promise<boolean> {
  localStorage.setItem('storage_backend', backend);
  if (backend === 'supabase') {
    try {
      getSupabase();
      return true;
    } catch {
      localStorage.setItem('storage_backend', 'sqlite');
      return false;
    }
  }
  return true;
}

export async function listTransactions(): Promise<Transaction[]> {
  if (getBackend() === 'supabase') {
    const { data, error } = await getSupabase()
      .from('transactions')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return (data ?? []) as Transaction[];
  }

  const db = await getSqlite();
  return await db.select<Transaction[]>(
    'SELECT id, created_at, description, amount, rate, date FROM transactions ORDER BY id DESC'
  );
}

export async function insertTransaction(entry: {
  description: string;
  amount: number;
  rate: number;
  date: string;
}): Promise<void> {
  if (getBackend() === 'supabase') {
    const { error } = await getSupabase()
      .from('transactions')
      .insert(entry);
    if (error) throw error;
    return;
  }

  const db = await getSqlite();
  await db.execute(
    'INSERT INTO transactions (description, amount, rate, date, created_at) VALUES ($1, $2, $3, $4, $5)',
    [entry.description, entry.amount, entry.rate, entry.date, new Date().toISOString()]
  );
}

export async function deleteTransaction(id: number): Promise<void> {
  if (getBackend() === 'supabase') {
    const { error } = await getSupabase()
      .from('transactions')
      .delete()
      .eq('id', id);
    if (error) throw error;
    return;
  }

  const db = await getSqlite();
  await db.execute('DELETE FROM transactions WHERE id = $1', [id]);
}

/** Returns the user-entered ExchangeRate-API key ('' = free tier). */
export function getExchangeRateApiKey(): string {
  return (
    localStorage.getItem('exchange_rate_api_key') ||
    import.meta.env.VITE_EXCHANGE_RATE_API_KEY ||
    ''
  );
}
