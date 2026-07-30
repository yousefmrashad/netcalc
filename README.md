# NetCalc

NetCalc is a modern personal finance and savings application. It allows you to log transactions, track overall savings with base-currency normalization, dynamically convert between USD and EGP, and evaluate mathematical expressions directly inside transaction inputs.

> [!NOTE]
> This branch tracks the Svelte 5 + Tauri v2 desktop app rewrite (located under `src/tauri/`). The Flutter app under `src/flutter/` and the legacy Streamlit dashboard under `src/streamlit/` are also included.

### 🚀 Implementations
* **Svelte 5 + Tauri v2 Desktop App (Primary):** Located under `src/tauri/`. Built with **Svelte 5** (runes: `$state`, `$derived`, `$effect`), **TypeScript**, **Tauri 2**, and **Vite**, featuring a Rust math evaluation backend, Supabase sync, and local storage caching.
* **Flutter App:** Located under `src/flutter/`.
* **Streamlit App (Legacy):** Located under `src/streamlit/`.

---

### 🌟 Key Features
* **Base Currency Architecture:** Normalizes and stores all transaction amounts in **USD** as the base currency while recording the exact exchange rate at the time of the transaction.
* **Multi-Currency Support:** Instant conversion between USD and EGP with live exchange rates from [ExchangeRate-API](https://www.exchangerate-api.com/) and optional manual rate override.
* **Smart Math Staging:** Math expression parser in amount input fields (e.g. `100 * 2.5 + (50 / 2)`), with live preview and Rust backend evaluation via Tauri.
* **Local-First Storage:** The Flutter app stores transactions by default in an on-device **SQLite** database (`netcalc.db`), so it works fully offline.
* **Optional Cloud Sync:** Supabase can optionally be enabled as the storage backend from the in-app Settings page.
* **Interactive Controls:** Real-time search filtering, delete confirmation modal, and one-click CSV export to clipboard.

---

### ⚙️ Flutter App Configuration (in-app Settings)

All credentials are entered by the user in the app's **Settings** page (no `.env` or build-time configuration required):

* **ExchangeRate-API Key** — API key from [ExchangeRate-API](https://www.exchangerate-api.com/) for fetching live conversion rates. Leave empty to fall back to a static rate.
* **Storage Backend** — choose between:
  * **Local (SQLite)** *(default)* — everything is stored on-device, no setup needed.
  * **Supabase** — requires your project's **URL** and **anon key** (entered in Settings). If Supabase can't be reached or configured, the app automatically falls back to local SQLite.

### 🗄️ Database Schema (Supabase)

The application expects a `transactions` table in Supabase:

```sql
create table transactions (
  id bigint generated always as identity primary key,
  created_at timestamptz default now() not null,
  description text not null,
  amount float8 not null,
  rate float8 not null,
  date text not null
);
```

---

### 🛠️ Running the Svelte 5 + Tauri App

```bash
cd src/tauri

# Install dependencies
npm install

# Run web development server
npm run dev

# Run Tauri desktop app
npm run tauri dev

# Build production app
npm run build
```

---

### License

This project is licensed under the GNU GPLv3 License.
