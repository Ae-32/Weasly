# UI Context — Weasly

**Note:** This is a placeholder starting point — the user plans to
redesign/customize this further. It defines an original visual
direction (not copied from Tarsi or any other app) so the AI has
consistent tokens to work with instead of guessing colors and
styles unit by unit. Update this file whenever the real design is
finalized.

## Theme

Light mode as the default, with dark mode supported. Overall feel:
clean, friendly, and approachable — rounded shapes, generous
whitespace, soft warm accent colors (fitting a "weasel stashing
money" mascot concept) rather than a cold, corporate finance look.

## Colors

All widgets must use these named colors (defined as Dart
constants in `lib/utils/app_colors.dart`) — never a raw hex code
typed directly inside a widget.

| Role             | Constant Name       | Value (Light) | Value (Dark) |
| ----------------- | -------------------- | -------------- | -------------- |
| Page background   | `bgBase`             | `#FAF7F2`      | `#1A1714`      |
| Surface (cards)   | `bgSurface`          | `#FFFFFF`      | `#26221E`      |
| Primary text      | `textPrimary`        | `#2B2420`      | `#F5F1EC`      |
| Muted text        | `textMuted`          | `#8A7F73`      | `#A69A8C`      |
| Primary accent    | `accentPrimary`      | `#D98A3D`      | `#E8A85C`      |
| Secondary accent  | `accentSecondary`    | `#4E8C6E`      | `#6FAE8C`      |
| Border            | `borderDefault`      | `#E8E1D8`      | `#3A342E`      |
| Error / over-budget | `stateError`        | `#D64545`      | `#E5695B`      |
| Success / on-track  | `stateSuccess`      | `#4E8C6E`      | `#6FAE8C`      |
| Warning / near-limit | `stateWarning`     | `#D9A63D`      | `#E8C05C`      |

Reasoning in plain terms: the accent color (warm amber/orange) ties
into the "weasel/stash" mascot idea, the secondary green is used
for positive numbers/income and "on budget" states, and red/amber
are used only for warnings and over-budget states so they stay
meaningful instead of decorative.

## Typography

| Role          | Font                          | Notes |
| -------------- | ------------------------------ | ----- |
| UI text        | A rounded sans-serif (e.g. Google Fonts "Nunito" or "Quicksand") | Matches the friendly, approachable feel |
| Numbers/amounts | Same font, but numeric values use `tabular-nums` style/monospaced digits where available | Keeps peso amounts aligned in lists |

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
account card, etc.) live in `lib/widgets/` as described in
`architecture.md`.

## Layout Patterns

- **Dashboard**: scrollable single column — balance summary card
  at top, spending chart below it, recent transactions list at
  the bottom
- **Lists** (transactions, bills, accounts): each item is a card
  with rounded corners, an icon on the left, details in the
  middle, amount on the right (green for income, default text
  color for expense)
- **Add/Edit forms** (new transaction, new budget, etc.): open as
  a bottom sheet or full modal, not a separate full-page
  navigation, to keep quick entry fast
- **Navigation**: bottom navigation bar with icons for Dashboard,
  Transactions, Budgets, and Accounts/Settings

## Icons

Material Icons (Flutter's built-in icon set) as the default —
free, no extra package needed, and consistent stroke weight.
Category icons (Food, Transport, etc.) can later be swapped for
custom illustrated icons once the visual identity is finalized.
