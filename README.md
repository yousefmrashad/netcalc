# NetCalc

NetCalc is a simple, minimal personal finance application. It allows you to log transactions, track your overall savings, and review your financial history.

> [!NOTE]
> The primary app is built with Flutter (located under `src/flutter/`). A legacy/deprecated Python Streamlit dashboard is also available under `src/streamlit/`.

### 🌟 Key Features
* **Multi-Currency Support:** Handles entries in both USD and EGP with automatic live conversion.
* **Base Currency Architecture:** Normalizes and stores all transaction amounts in **USD** as the base currency (ideal for tracking savings in a stable asset) while recording the exact exchange rate at the time of the transaction. This preserves the historical context of what your savings were worth in your local currency (EGP).
* **Smart Staging:** Features a math expression parser that lets you evaluate calculations directly in the transaction amount field.
* **Local-First Storage:** Transactions are stored by default in an on-device **SQLite** database (`netcalc.db`), so the app works fully offline.
* **Optional Cloud Sync:** Supabase can optionally be enabled as the storage backend from the in-app Settings page.

### ⚙️ Configuration (in-app Settings)

All credentials are entered by the user in the app's **Settings** page (no `.env` or build-time configuration required):

* **ExchangeRate-API Key** — API key from [ExchangeRate-API](https://www.exchangerate-api.com/) for fetching live conversion rates. Leave empty to fall back to a static rate.
* **Storage Backend** — choose between:
  * **Local (SQLite)** *(default)* — everything is stored on-device, no setup needed.
  * **Supabase** — requires your project's **URL** and **anon key** (entered in Settings). If Supabase can't be reached or configured, the app automatically falls back to local SQLite.

### 🗄️ Database Setup (optional Supabase sync)

The application expects a table named `transactions` to exist in your Supabase database. You can create it by running the following query in your Supabase **SQL Editor**:

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

*(Note: `id` and `created_at` are default columns in Supabase. If you are creating the table using the Supabase visual Table Editor UI, you only need to manually add the `description`, `amount`, `rate`, and `date` columns.)*

### 📦 Download & Install

Grab the latest build from the [Releases](https://github.com/yousefmrashad/netcalc/releases/latest) page:

**Android**
1. Download the APK matching your device — most modern phones use `arm64-v8a`; older devices use `armeabi-v7a`; emulators use `x86_64`.
2. Open the APK and allow installs from unknown sources when prompted (the app is not distributed through the Play Store).

**Windows**
1. Download `netcalc-windows-x64.zip` and extract it anywhere.
2. Run `NetCalc.exe`. If SmartScreen shows a "Windows protected your PC" warning, click **More info → Run anyway** — the app is not code-signed, so this warning is expected.

**Linux**
1. Download `netcalc-linux-x64.tar.gz` and extract it: `tar -xzf netcalc-linux-x64.tar.gz`
2. Run the `NetCalc` binary inside. GTK3 libraries are required (installed by default on all major desktop distributions).

### License

This project is licensed under the GNU GPLv3 License.
