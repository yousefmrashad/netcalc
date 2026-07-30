export interface Transaction {
  id: number;
  created_at: string;
  description: string;
  amount: number; // Stored in USD base currency
  rate: number;   // USD to EGP rate at the time of transaction
  date: string;   // Formatted timestamp string e.g. "Jul 30, 2026 • 02:42"
}

export interface Settings {
  useManualRate: boolean;
  manualRate: number;
}

export type Currency = 'USD' | 'EGP';
