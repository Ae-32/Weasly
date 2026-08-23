# Architecture Context — Weasly

## Stack

| Layer            | Technology                          | Role |
| ----------------- | ------------------------------------ | ---- |
| Framework         | Flutter (Dart)                       | Builds the mobile app UI and logic, runs on Android (iOS later) |
| State Management  | Riverpod                             | Keeps track of app data in memory while the app is open (balance, transaction lists, budgets) and updates the UI automatically when that data changes |
| Auth              | Firebase Authentication (email/password) | Handles sign up, login, and identifying which user owns which data |
| Database          | Cloud Firestore                      | Stores all user data (transactions, accounts, categories, budgets, recurring bills) online, with automatic offline caching |
| Offline Support   | Firestore offline persistence (built-in) | Lets the app read/write data with no internet; changes sync automatically once the connection returns |
| Notifications     | Firebase Cloud Messaging + local notification scheduling | Sends reminders before a recurring bill is due |
| Charts            | A Flutter charting package (e.g. `fl_chart`) | Renders the spending-by-category chart on the dashboard |

## System Boundaries

In Flutter, code is organized into folders by responsibility so
each part of the app has one clear job:

- `lib/models/` — plain data definitions (what a "Transaction",
  "Account", "Category", "Budget", and "Recurring Bill" look
  like as objects in code). No logic here, just shape of data.
- `lib/services/` — code that talks to Firebase directly (reading
  and writing to Firestore, handling login/logout with Firebase
  Auth, scheduling notifications). Nothing in the UI talks to
  Firebase directly — it always goes through this layer.
- `lib/providers/` — Riverpod providers. This is the "memory" of
  the running app — it holds the current transactions, budgets,
  etc. in a form the UI can watch and react to. Providers call
  into `services/` to actually fetch or save data.
- `lib/screens/` — one folder per app screen (Dashboard, Add
  Transaction, Budgets, Accounts, Recurring Bills, Login/Signup).
  Screens display data from `providers/` and send user actions
  (like "save this transaction") back to `providers/`.
- `lib/widgets/` — small reusable UI pieces used across multiple
  screens (e.g. a transaction list item, a budget progress bar).

## Storage Model

Everything lives in **Cloud Firestore**, Firebase's cloud
database. Firestore stores data as documents grouped into
collections — think of a collection like a folder, and a document
like a single record inside it.

- **users/{userId}** — basic profile info for each signed-in user
  (email, display name, default currency).
- **users/{userId}/accounts/{accountId}** — a user's accounts
  (Cash, GCash, Bank, etc.), each with a name, type, and running
  balance.
- **users/{userId}/transactions/{transactionId}** — every expense,
  income, or transfer entry: amount, type, category, account(s)
  involved, date, and optional note.
- **users/{userId}/categories/{categoryId}** — a user's spending
  categories (default ones plus any custom ones they add).
- **users/{userId}/budgets/{budgetId}** — a budget: category,
  amount, and period (weekly/monthly/custom date range).
- **users/{userId}/recurringBills/{billId}** — a recurring bill:
  name, amount, frequency, next due date.

All of a user's data lives nested under their own `users/{userId}`
record, which is what makes it easy to enforce "you can only see
your own data" (see Auth and Access Model below).

No separate local database is used — Firestore's built-in offline
cache handles storing data on the device automatically when
there's no internet, and syncs it once the connection is back.

## Auth and Access Model

- Every user signs up and logs in through Firebase Authentication
  using email and password.
- Firebase gives each signed-in user a unique ID (`userId`). All
  of that user's data is stored under `users/{userId}/...` in
  Firestore, as described above.
- **Firestore Security Rules** (configured in the Firebase
  console, not in the Flutter app itself) enforce that a user can
  only read or write documents under their own `users/{userId}`
  path. This is what actually keeps one person's finances private
  from another's — the app UI trusting "this is my data" is not
  enough on its own; the rule must be enforced on Firebase's side.
- There are no shared/family accounts in v1 — each person's data
  is fully separate, even though several people use the same app.

## Invariants

Rules the code must never break, no matter which unit is being
built:

1. **The UI never talks to Firebase directly.** All reads/writes
   go through `lib/services/`, never called straight from a
   screen or widget. This keeps Firebase logic in one place so it
   can be changed later without touching every screen.
2. **All user data is scoped under `users/{userId}/...`.** No
   feature may read or write data outside the signed-in user's own
   path — this is what keeps each user's finances private.
3. **Every transaction must belong to exactly one category and
   one account** (or two accounts, for a transfer). A transaction
   with no category or no account is invalid and must not be
   saved.
4. **Money amounts are never estimated or rounded silently.**
   Balances and budget totals are always calculated as an exact
   sum of the underlying transactions — never approximated.
5. **The app must remain usable with no internet connection.**
   Any new feature must work against Firestore's offline cache; a
   feature that hard-fails without internet is a bug.
6. **Notifications are scheduled locally based on due dates, not
   assumed.** A recurring bill's reminder must be recalculated
   whenever its due date or frequency changes.
