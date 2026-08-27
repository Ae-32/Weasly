# Progress Tracker — Weasly

Update this file after every meaningful implementation change.

## Current Phase

- Unit 07 — Dashboard/Reports Preparation

## Current Goal

- Begin Unit 07: Dashboard/Reports (balance overview, category spending breakdown chart).

## Completed

- `project-overview.md` — product definition, features, scope
- `architecture.md` — tech stack, folder structure, storage model, auth model, invariants
- `code-standards.md` — Dart/Flutter/Riverpod/Firestore coding conventions
- `ai-workflow-rules.md` — how the AI should behave while building this project
- `ui-context.md` — visual design tokens and UI conventions
- Project Setup — Flutter scaffolding, Riverpod + Firebase dependencies, folder structure (`lib/models`, `lib/services`, `lib/providers`, `lib/screens`, `lib/widgets`, `lib/utils`), theme tokens (`AppColors`, `AppTheme`), clean `flutter analyze` & test status.
- Unit 01 — Authentication: Login & Sign Up screens matching `design-reference/` exact layout and colors, email/password & Google Sign-In via `AuthService` in `lib/services/`, Riverpod state management in `lib/providers/`, Firestore profile syncing under `users/{userId}`, plain-language error mapping, and auto-navigation to Dashboard upon login.
- Unit 02 — Accounts: `AccountModel`, Firestore `AccountService` under `users/{userId}/accounts/`, `accountsStreamProvider`, `totalBalanceProvider`, `AccountCard` widget, `AccountsScreen` matching `design-reference/accounts_overview/code.html`, bottom navigation bar (`BottomNavBar` & `HomeShellScreen`), add/edit/delete bottom sheet modal, and auto-seeding default stashes (Cash, GCash, Main Bank).
- Unit 03 — Categories: `CategoryModel`, default 8 preset financial categories (`Food & Dining`, `Shopping`, `Bills & Utilities`, `Transportation`, `Entertainment`, `Health`, `Salary`, `Investment`), `CategoryService` under `users/{userId}/categories/` with auto-seeding, Riverpod state management (`categoriesStreamProvider`, `expenseCategoriesProvider`, `incomeCategoriesProvider`), `CategoriesScreen` with expense/income tabbed listing, custom category modal (`AddEditCategoryModal`) with color chip and icon grid picker, and default category protection rule (preset categories are editable, but non-deletable).
- Unit 04 — Transactions: `TransactionModel`, `TransactionService` under `users/{userId}/transactions/` with atomic Firestore transactions (`runTransaction`) ensuring account balances update safely for Expense, Income, and Transfer types, Riverpod state management (`transactionsStreamProvider`, `filteredTransactionsProvider` with search, category, account, and type filtering), `AddEditTransactionModal` matching `design-reference/add_transaction/code.html`, and `TransactionsScreen` matching `design-reference/transactions_history/code.html` with date grouping and color-coded amounts.
- Unit 05 — Budgets: `BudgetModel`, `BudgetService` under `users/{userId}/budgets/`, dynamic spending calculation from live `transactionsStreamProvider` expenses within weekly/monthly/custom period boundaries, Riverpod state management (`budgetsWithSpentProvider`), status classification (On track / Nearing limit / Over budget), `AddEditBudgetModal` matching `design-reference/set_budget/code.html`, and `BudgetsScreen` matching `design-reference/budgets_overview/code.html`.
- Unit 06 — Recurring Bills: `RecurringBillModel`, Firestore `RecurringBillService` under `users/{userId}/recurringBills/`, `recurringBillsStreamProvider`, `NotificationService` integration with `flutter_local_notifications` for local due date reminders, `RecurringBillCard` widget, `AddEditRecurringBillModal` bottom sheet form, `RecurringBillsScreen` with estimated monthly commitment calculation, Android 13+ runtime notification permission handling, and Unit 06 test suite (`recurring_bill_model_test.dart`).

## In Progress

- Unit 07 — Dashboard/Reports

## Next Up

1. Unit 07 — Dashboard/Reports (balance overview, category spending breakdown chart)


This order follows the "dependencies first, security before
functionality" rule from the build methodology — auth and
accounts come before anything that depends on them.

## Open Questions

- None currently — all major product and architecture decisions
  have been made. New questions should be added here as they come
  up during building.

## Architecture Decisions

- Flutter + Firebase (Auth + Firestore) instead of a Laravel
  backend or fully offline-only storage — chosen for built-in
  multi-user support with less custom backend work
- Riverpod for state management — modern, still beginner-friendly
- Firestore's built-in offline cache used for offline support,
  instead of a separate local database (Hive/SQLite) — simpler
  setup, less custom sync logic to maintain
- Multiple accounts per user (Cash, GCash, Bank, etc.), each
  transaction tied to a specific account — matches Tarsi-style
  behavior
- Budgets use a user-chosen period (weekly/monthly/custom), not
  fixed to monthly
- Push notifications for recurring bill reminders included in v1
- Default currency is Philippine Peso (₱)
- App name is "Weasly" — inspired by Genshin Impact's Weasel
  Thief creature; original name/branding, not using any Genshin
  IP directly

## Session Notes

- This project follows the Six-File Context System from the
  "How Senior Engineers Actually Build With AI in 2026"
  methodology (JavaScript Mastery playbook)
- Reference app for feature inspiration: Tarsi, by BryLim (not
  being cloned — original UI, branding, and code)
- User is not a professional developer (knows basics only) — all
  implementation explanations must be in plain, non-technical
  language, per `ai-workflow-rules.md`
- Android is the primary target for v1; iOS is out of scope for
  now
