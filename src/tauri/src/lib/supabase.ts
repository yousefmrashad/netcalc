import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://xrnorgzempwdyqypszmg.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'sb_publishable_MEmcTMfa94AAy4PFn2fg8Q_30zbjJ4n';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
