# NetCalc

NetCalc is a simple, minimal personal finance application. It allows you to log transactions, track your overall savings, and review your financial history.

> [!NOTE]
> The primary app is built with Flutter (located under `src/flutter/`). A legacy/deprecated Python Streamlit dashboard is also available under `src/streamlit/` (the Streamlit version relied on Streamlit secrets (`st.secrets`) for configuration rather than a `.env` file).

### 🌟 Key Features
* **Multi-Currency Support:** Handles entries in both USD and EGP with automatic live conversion.
* **Base Currency Architecture:** Normalizes and stores all transaction amounts in **USD** as the base currency (ideal for tracking savings in a stable asset) while recording the exact exchange rate at the time of the transaction. This preserves the historical context of what your savings were worth in your local currency (EGP).
* **Smart Staging:** Features a math expression parser that lets you evaluate calculations directly in the transaction amount field.
* **Cloud Database:** Backed by Supabase for simple storage management.

### ⚠️ Security Warning

This application relies on packaging environment variables (like API keys and database credentials) directly inside the build. 

Please note that compiling or embedding secret keys into client-side application packages carries **inherent security risks** (as they can potentially be extracted or decompiled by third parties). Use with caution and only in trusted environments.

### Requirements

To run the Flutter app, you must configure the following environment variables:
* `EXCHANGE_RATE_API_KEY` — API key from [ExchangeRate-API](https://www.exchangerate-api.com/) for fetching conversion rates.
* `SUPABASE_URL` — The URL of your Supabase database instance.
* `SUPABASE_ANON_KEY` — The public anonymous key for your Supabase database.

### 🗄️ Database Setup (Supabase)

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

### License

This project is licensed under the GNU GPLv3 License.
