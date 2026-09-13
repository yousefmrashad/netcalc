import { createClient, type SupabaseClient } from '@supabase/supabase-js';

let client: SupabaseClient | null = null;

/**
 * Returns the Supabase client, creating it lazily from user-entered
 * credentials stored in localStorage (with .env fallbacks). Throws if
 * the project URL / anon key are not configured.
 */
export function getSupabase(): SupabaseClient {
  if (client) return client;

  const url =
    localStorage.getItem('supabase_url') ||
    import.meta.env.VITE_SUPABASE_URL ||
    '';
  const anonKey =
    localStorage.getItem('supabase_anon_key') ||
    import.meta.env.VITE_SUPABASE_ANON_KEY ||
    '';

  if (!url || !anonKey) {
    throw new Error('Supabase is not configured. Add a URL and anon key in Settings.');
  }

  client = createClient(url, anonKey);
  return client;
}
