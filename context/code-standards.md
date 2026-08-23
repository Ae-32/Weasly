# Code Standards — Weasly

## General

- Keep files small and single-purpose — one screen, one widget,
  or one service per file. If a file is doing two unrelated
  jobs, split it.
- Fix the actual cause of a bug, don't patch around it with a
  quick workaround that hides the real problem.
- Don't mix concerns — a screen file displays UI and reacts to
  user taps; it does not contain Firebase calls or business math
  directly (that belongs in `services/` and `providers/`).
- Every new file should look and feel like it was written by the
  same person as the rest of the app — consistent naming,
  consistent structure, no unexplained one-off patterns.

## Dart Language Rules

- Use `null safety` properly — no `!` (force-unwrap) unless it is
  genuinely impossible for the value to be null; prefer safe
  handling (`??`, `if (x != null)`).
- Every data model (`Transaction`, `Account`, `Category`, `Budget`,
  `RecurringBill`) must have an explicit class with named,
  typed fields — never pass raw `Map<String, dynamic>` around
  the app outside of the `services/` layer that talks to
  Firestore.
- Use `final` for anything that doesn't change after it's created.
- Avoid `dynamic` types — every variable and function should have
  a clear, specific type so mistakes get caught before running
  the app.

## Flutter & Riverpod Conventions

- All app state (transactions, budgets, accounts, etc.) is
  exposed through Riverpod providers — widgets read data via
  `ref.watch(...)`, they never hold their own copies of app data
  in local state.
- A widget only rebuilds what it needs — watch the smallest
  provider necessary, not one giant "app state" provider for
  everything.
- Keep widgets focused: if a `build()` method is getting long or
  hard to read, break it into smaller private widgets.
- Business logic (e.g. "is this budget over its limit?",
  "what's the running balance for this account?") lives in
  providers or a small helper/util file — never computed inline
  inside a widget's `build()` method.

## Firestore & Data Rules

- All reads and writes to Firestore happen inside
  `lib/services/`, never directly from a screen, widget, or
  provider callback.
- Every document written to Firestore must match its
  corresponding Dart model exactly — no ad-hoc fields added on
  the fly.
- Validate input (e.g. amount must be a positive number, a
  category must be selected) before saving — never trust that
  the UI already guaranteed valid data.
- Timestamps use Firestore's `Timestamp` type, not raw strings,
  so dates sort and filter correctly.

## Styling & UI

- Use the color tokens, spacing, and type scale defined in
  `ui-context.md` — no hardcoded hex colors or one-off font
  sizes inside widgets.
- Reusable UI pieces (a transaction row, a budget progress bar,
  a category icon) live in `lib/widgets/` and get reused across
  screens — never copy-pasted between screens.
- Follow Flutter's standard widget naming: `PascalCase` for
  widget class names, one public widget per file, file name in
  `snake_case` matching the widget (e.g. `budget_progress_bar.dart`
  → `BudgetProgressBar`).

## File Organization

- `lib/models/` — data class definitions only (Transaction,
  Account, Category, Budget, RecurringBill). No logic.
- `lib/services/` — all Firebase/Firestore/Auth/notification
  code. This is the only layer allowed to import Firebase
  packages directly.
- `lib/providers/` — Riverpod providers that hold and expose app
  state to the UI, calling into `services/` as needed.
- `lib/screens/` — one subfolder per feature area (e.g.
  `screens/dashboard/`, `screens/transactions/`,
  `screens/budgets/`), each containing that feature's screen(s).
- `lib/widgets/` — small, reusable UI components shared across
  more than one screen.
- `lib/utils/` — small helper functions (currency formatting,
  date formatting, validation helpers) with no Firebase or UI
  dependencies.
