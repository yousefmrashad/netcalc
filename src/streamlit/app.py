import os
from datetime import datetime

import pandas as pd
import requests
import streamlit as st
from py_expression_eval import Parser
from supabase import create_client

# Page Config
st.set_page_config(page_title="Savings Tracker", page_icon="💰", layout="wide")

# --- 1. Security & Configuration ---


def check_password():
    """Returns `True` if the user had the correct password."""

    # Check if we are running locally with no secrets set up yet
    if "PASSWORD" not in st.secrets and "PASSWORD" not in os.environ:
        st.warning("No password set in secrets. allowing access for setup...")
        return True

    def password_entered():
        """Checks whether a password entered by the user is correct."""
        if st.session_state["password"] == st.secrets.get(
            "PASSWORD", os.getenv("PASSWORD")
        ):
            st.session_state["password_correct"] = True
            del st.session_state["password"]  # don't store password
        else:
            st.session_state["password_correct"] = False

    if "password_correct" not in st.session_state:
        # First run, show input
        st.text_input(
            "Password", type="password", on_change=password_entered, key="password"
        )
        return False
    elif not st.session_state["password_correct"]:
        # Password incorrect, show input again
        st.text_input(
            "Password", type="password", on_change=password_entered, key="password"
        )
        st.error("😕 Password incorrect")
        return False
    else:
        # Password correct
        return True


if not check_password():
    st.stop()

# --- 2. Initialize Supabase ---


@st.cache_resource
def init_supabase():
    url = st.secrets.get("SUPABASE_URL", os.getenv("SUPABASE_URL"))
    key = st.secrets.get("SUPABASE_KEY", os.getenv("SUPABASE_KEY"))

    if not url or not key:
        st.error(
            "Missing Supabase credentials. Please set SUPABASE_URL and SUPABASE_KEY in secrets."
        )
        st.stop()

    return create_client(url, key)


supabase = init_supabase()
parser = Parser()

# --- 3. Helper Functions ---


def get_exchange_rate():
    """Fetches the current USD to EGP exchange rate."""
    api_key = st.secrets.get("API_KEY", os.getenv("API_KEY"))
    if not api_key:
        st.error("API_KEY not found in secrets.")
        return None

    url = f"https://v6.exchangerate-api.com/v6/{api_key}/latest/USD"
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        return data["conversion_rates"]["EGP"]
    except Exception as e:
        st.error(f"Error fetching exchange rate: {e}")
        return None


def load_data():
    """Loads transactions from Supabase."""
    try:
        response = supabase.table("transactions").select("*").execute()
        data = response.data

        if not data:
            return pd.DataFrame(
                columns=["id", "description", "amount", "rate", "date", "created_at"]
            )

        df = pd.DataFrame(data)
        # Ensure 'amount' is numeric
        df["amount"] = pd.to_numeric(df["amount"], errors="coerce").fillna(0)
        return df
    except Exception as e:
        st.error(f"Error loading data from Supabase: {e}")
        return pd.DataFrame(columns=["description", "amount", "rate", "date"])


def add_entry(description, amount, rate, date_str):
    """Inserts a new entry into Supabase."""
    try:
        data = {
            "description": description,
            "amount": round(amount, 2),
            "rate": round(rate, 2),
            "date": date_str,
        }
        supabase.table("transactions").insert(data).execute()
        return True
    except Exception as e:
        st.error(f"Error saving entry to Supabase: {e}")
        return False


def delete_entry(entry_id):
    """Deletes an entry from Supabase by ID."""
    try:
        supabase.table("transactions").delete().eq("id", entry_id).execute()
        return True
    except Exception as e:
        st.error(f"Error deleting entry from Supabase: {e}")
        return False


# --- 4. Main App ---

st.title("💰 Savings Tracker")

# Fetch Data & Rate
rate = get_exchange_rate()
df = load_data()

if rate:
    # Calculate Totals
    total_usd = df["amount"].sum()
    total_egp = total_usd * rate

    # Top Metrics
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric(label="Savings (USD)", value=f"${total_usd:,.2f}")
    with col2:
        st.metric(label="Savings (EGP)", value=f"EGP {total_egp:,.2f}")
    with col3:
        st.metric(label="Exchange Rate (USD → EGP)", value=f"{rate:,.2f}")

    st.divider()

    # Add New Entry Form
    st.subheader("➕ New Entry")

    with st.form("entry_form", clear_on_submit=True):
        col_desc, col_amt, col_curr = st.columns([3, 2, 1])

        with col_desc:
            desc_input = st.text_input("Description")

        with col_amt:
            amt_input = st.text_input("Amount (supports expressions like 5+10)")

        with col_curr:
            currency_input = st.radio("Currency", ["USD", "EGP"], horizontal=True)

        submitted = st.form_submit_button("Add Entry")

        if submitted:
            if not desc_input or not amt_input:
                st.warning("Please fill in both Description and Amount.")
            else:
                try:
                    # Parse Expression
                    amount_val = parser.parse(amt_input).evaluate({})

                    # Convert if EGP
                    final_amount = amount_val
                    if currency_input == "EGP":
                        final_amount = amount_val / rate
                        st.info(f"Converted {amount_val} EGP to {final_amount:.2f} USD")

                    # Save
                    date_now = datetime.now().strftime("%d-%m-%Y %H:%M")
                    if add_entry(desc_input, final_amount, rate, date_now):
                        st.success("Entry added successfully!")
                        st.rerun()

                except Exception as e:
                    st.error(f"Error parsing amount: {e}")

    st.divider()

    # History Table
    st.subheader("📜 Transaction History")

    if not df.empty:
        # Show specific columns and latest first (assuming higher index/ID is later, or we rely on insertion order)
        # If we have created_at, sorting by that is safer.
        if "created_at" in df.columns:
            df = df.sort_values(by="created_at", ascending=False)
        else:
            df = df.iloc[::-1]

        # Add a Delete selection column
        df["Delete"] = False

        edited_df = st.data_editor(
            df,
            column_order=["Delete", "description", "amount", "rate", "date"],
            width="content",
            column_config={
                "Delete": st.column_config.CheckboxColumn("Delete?", default=False),
                "description": st.column_config.TextColumn(
                    "Description", disabled=True
                ),
                "amount": st.column_config.NumberColumn(
                    "Amount ($)", format="$%.2f", disabled=True
                ),
                "rate": st.column_config.NumberColumn(
                    "Ex. Rate", format="%.2f", disabled=True
                ),
                "date": st.column_config.TextColumn("Date", disabled=True),
            },
            hide_index=True,
        )

        to_delete = edited_df[edited_df["Delete"] == True]

        if not to_delete.empty:
            if st.button(f"🗑️ Delete {len(to_delete)} selected entries"):
                for index, row in to_delete.iterrows():
                    # Check if 'id' exists
                    if "id" in row:
                        delete_entry(row["id"])

                st.success("Selected entries deleted.")
                st.rerun()

    else:
        st.info("No transactions found.")

else:
    st.warning("Could not load application due to missing exchange rate.")
