# UI Context — Weasly

**Status:** Finalized redesign (v2), designed in Figma, exported to
`design-reference/redesign-v2/`. This supersedes the original
placeholder direction — colors, mascot, and screen details below
reflect the actual approved design.

## Logo & Brand Assets

The Weasly logo is stored at `assets/images/Weasly_Logo.png` (app
icon version: `Weasly_App.png`) — a circular/rounded-square orange
icon with a white illustrated weasel mascot holding a money pouch
marked "W". Register these in `pubspec.yaml`.

Additional mascot pose illustrations, all in `assets/images/`, used
for specific screens/states:

| Filename | Use case |
| --- | --- |
| `Weasly_Dashboard_Welcome.png` | Dashboard greeting/insight bubble area |
| `Weasly_Dashboard_TotalBalance.png` | Dashboard total balance card |
| `Weasly_Dashboard_PayCheck.png` | Days-until-payday card |
| `Weasly_Account_TotalBalance.png` | Account screen total balance card |
| `Weasly_Account_Stashes.png` | Account screen, Stashes section |
| `Weasly_NoTransaction.png` | Empty state (no transactions yet) |
| `Weasly_Logout.png` | Logout confirmation modal (sad pose) |
| `Weasly_Logout_Success.png` | "See you soon!" logout success screen (waving pose) |
| `Weasly (9).png` | Spare/general-purpose pose — confirm intended use before wiring in |

Do not stretch, recolor, or alter any mascot illustration — display
at original proportions, sized appropriately per screen.

## Theme

Light mode as the default. Overall feel: clean, friendly, and
approachable — rounded shapes, generous whitespace, warm orange as
the dominant brand color (pulled directly from the logo).

## Colors

**Status: CONFIRMED from actual Figma CSS export (Dashboard).**
All widgets must use these named colors (defined as Dart
constants in `lib/utils/app_colors.dart`) — never a raw hex code
typed directly inside a widget.

| Role             | Constant Name       | Value (Light) |
| ----------------- | -------------------- | -------------- |
| Page background   | `bgBase`             | `#FAF7F2`      |
| Surface (cards)   | `bgSurface`          | `#FFFFFF`      |
| Primary text      | `textPrimary`        | `#211A16`      |
| Muted text        | `textMuted`          | `#8A7F73`      |
| Muted text (secondary) | `textMutedAlt`   | `#9A9998`      |
| Muted text (tertiary)  | `textMutedLight` | `#BBB6B4` / `#A2A2A2` |
| Primary accent    | `accentPrimary`      | `#E06E03`      |
| Primary accent — light/inactive tint | `accentPrimaryLight` | `#EFD8C2` |
| Icon button background | `iconButtonBg`  | `#EDE0D9`      |
| Border            | `borderDefault`      | `#E8E1D8`      |
| Error / over-budget | `stateError`        | `#D64545`      |
| Success / on-track  | `stateSuccess`      | `#4E8C6E`      |
| Warning / near-limit | `stateWarning`     | `#D9A63D`      |

Card shadow (used on all elevated cards): `0px 4px 12px
rgba(43, 36, 32, 0.04)`.

Reasoning: `accentPrimary` (#E06E03) is the true confirmed brand
orange from the actual Dashboard export — it appears on nearly
every interactive element and highlighted number. `accentPrimaryLight`
(#EFD8C2) is used for inactive donut segments, nav pill
backgrounds, and secondary progress-bar tracks. Green stays
reserved for income/positive/on-track states; red/amber stay
reserved for warnings and over-budget states.

### Category Colors

**Status: PARTIALLY CONFIRMED from Figma CSS export.** The three
categories below have real confirmed values; remaining categories
are still placeholders pending the same kind of export.

| Category | Hex | Status |
| --- | --- | --- |
| Food & Dining | `#EE4818` | Confirmed |
| Transportation | `#E08B03` (text/icon) / `#F59715` (progress fill) | Confirmed |
| Bills & Utilities | `#F48423` | Confirmed |
| Shopping | `#D94A6E` | Placeholder |
| Entertainment | `#8B6BB8` | Placeholder |
| Health | `#D9A63D` | Placeholder |
| Housing | `#A8664A` | Placeholder |
| Education | `#6B8A9E` | Placeholder |
| Other (expense) | `#8A7F73` | Placeholder |
| Salary | `#4E8C6E` | Cool (income) |
| Investment | `#4AD98F` | Placeholder |
| Other Income | `#6FAE8C` | Placeholder |

## Typography

| Role          | Font                          | Notes |
| -------------- | ------------------------------ | ----- |
| UI text        | Quicksand (rounded sans-serif) | Used everywhere except chart percentage labels |
| Chart percentage labels | Amaranth | Used specifically for small "%" labels on donut charts (e.g. "90%", "60%") — bolder, more compact than Quicksand at small sizes |
| Numbers/amounts | Quicksand, tabular-nums style where available | Keeps peso amounts aligned in lists |

## Border Radius

| Context            | Radius |
| -------------------- | ------ |
| Inline / small UI (chips, tags) | 8px |
| Cards / panels        | 16px |
| Buttons                | 12px |
| Modals / bottom sheets | 24px (top corners only) |

## Component Library

No third-party Flutter UI kit — built with Flutter's own Material
widgets, restyled using the color/typography/radius tokens above.
Custom reusable widgets (transaction row, budget progress bar,
account card, etc.) live in `lib/widgets/`.

## Layout Patterns

- **Onboarding**: mascot displayed directly on background (no
  boxed/framed container), auto-advancing slides, single "Get
  Started" button — no Skip, no manual Next button
- **Dashboard**: personalized time-of-day greeting + date on an
  orange background band, mascot insight speech bubble on that
  same band, total balance card (balance + mascot illustration
  only — no action buttons here), income-vs-expense donut chart
  with its own Day/Week/Month toggle, days-until-payday card,
  spending-by-category donut + list with its own Day/Week/Month
  toggle, recent transactions list. No Quick Actions row. Add
  Income/Add Expense buttons live on the Account screen, not the
  Dashboard.
- **Lists** (transactions, bills, accounts): each item is a card
  with rounded corners, an icon on the left (colored per category),
  details in the middle, amount on the right (green for income,
  default text color for expense)
- **Add/Edit forms** (new transaction, new budget, etc.): open as
  a bottom sheet, not a separate full-page navigation
- **Navigation**: bottom navigation bar — Home, Transactions,
  Budgets, Account (renamed from "Accounts")
- **Account screen** (singular; formerly "Accounts"): total balance
  card with mascot illustration, Add Income/Add Expense action
  buttons (moved here from the Dashboard), "Stashes" section
  listing individual accounts (Cash Wallet, E-Wallet, Bank, etc.)
  with a donut chart showing balance distribution
- **Logout flow**: tapping logout opens a confirmation modal (sad
  mascot, "Are you sure you want to sign out Weasly?", Cancel/Log
  Out buttons) → on confirm, shows a "See you soon!" success screen
  (waving mascot) with a button back to Login

## Icons

Material Icons (Flutter's built-in icon set) as the default, with
category icons colored per the Category Colors table above.