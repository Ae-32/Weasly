# Weasly

## Overview

Weasly is a mobile budget tracking app built with Flutter, using
Firebase for accounts and data sync. It helps a small group of
people (the owner plus a few others) log daily income and
expenses, set budgets per category, track recurring bills, and see
a simple dashboard of where their money is going. It is inspired
by Tarsi (by BryLim) but is an original app with its own name,
mascot concept, and codebase — not a clone.

## Goals

1. Let a signed-in user log a transaction (expense, income, or
   transfer) in under 10 seconds.
2. Let a user set a monthly budget per category and see progress
   toward it at a glance.
3. Let a user see recurring bills/subscriptions in one place so
   nothing gets missed.
4. Give a user a simple dashboard showing balance and spending
   breakdown without needing to dig through raw transaction lists.
5. Support multiple separate users (you + a few others), each with
   their own private data — no one sees another person's finances.

## Core User Flow

1. User opens the app and signs in (or creates an account) via
   Firebase Auth.
2. User lands on the Dashboard — sees current balance and a quick
   spending summary.
3. User adds a transaction (expense, income, or transfer),
   assigning it to a category.
4. User sets up a budget for a category (e.g. "Food — ₱5,000/month")
   and sees a progress bar update as transactions come in.
5. User adds a recurring bill (e.g. "Netflix — ₱149/month") so it's
   tracked without manual re-entry.
6. User checks the Dashboard/Reports view to see a breakdown of
   spending by category over time.

## Features

### Authentication
- Sign up / log in with Firebase Auth (email + password)
- Each user's data is private to their own account

### Transactions
- Add/edit/delete a transaction: expense, income, or transfer
- Assign a category to each transaction
- View transaction history, filterable by category or date

### Categories
- Default set of common categories (Food, Transport, Bills, etc.)
- User can add custom categories

### Budgets
- Set a budget amount per category (monthly)
- Visual progress bar showing amount spent vs. budget
- Warning indicator when a budget is close to or over its limit

### Recurring Bills / Subscriptions
- Add a recurring bill with amount and frequency (e.g. monthly)
- See upcoming bills in one list

### Dashboard / Reports
- Current balance overview
- Spending breakdown by category (this month)
- Simple visual chart (e.g. pie or bar) of category spending

## Scope

### In Scope
- Flutter mobile app (Android first)
- Firebase Authentication (email/password)
- Firebase Firestore for storing transactions, categories, budgets,
  recurring bills
- Manual transaction entry (typing in amount, category, note)
- Per-category monthly budgets with progress tracking
- Recurring bills list (manually added, not auto-detected)
- Basic dashboard with balance + category breakdown chart
- Support for a small, fixed group of individual users, each with
  their own private account and data (no shared/family accounts)

### Out of Scope (for v1)
- AI/voice-based transaction entry (e.g. "Starbucks 250" auto-parsed)
- OCR receipt scanning
- Investment or stock/crypto tracking
- Cashflow forecasting
- In-app financial coaching/tips ("Tarsi Coach" style)
- iOS build (Android first; iOS can come later)
- Shared/family accounts where multiple people see the same data
- Bank account linking / automatic transaction import

## Success Criteria

1. A signed-up user can log in and see only their own data.
2. A user can add a transaction and see it reflected immediately
   in their balance and category totals.
3. A user can set a budget for a category and see an accurate
   progress bar as they log expenses in that category.
4. A user can add a recurring bill and see it listed with its
   next due info.
5. The dashboard accurately reflects the sum of the user's
   transactions, broken down by category, for the current month.
