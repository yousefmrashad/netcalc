# NetCalc

NetCalc is a simple, minimal personal finance application. It allows you to log transactions, track your overall savings, and review your financial history.

### 🌟 Key Features
* **Multi-Currency Support:** Handles entries in both USD and EGP with automatic live conversion.
* **Smart Staging:** Features a math expression parser that lets you evaluate calculations directly in the transaction amount field.
* **Cloud Database:** Backed by Supabase for simple storage management.

### ⚠️ Security Warning

This application relies on packaging environment variables (like API keys and database credentials) directly inside the build. 

Please note that compiling or embedding secret keys into client-side application packages carries **inherent security risks** (as they can potentially be extracted or decompiled by third parties). Use with caution and only in trusted environments.

### Requirements

To run, the app expects the following configuration:
* `PASSWORD`
* `API_KEY`
* `SUPABASE_URL`
* `SUPABASE_KEY`

### License

This project is licensed under the GNU GPLv3 License.
