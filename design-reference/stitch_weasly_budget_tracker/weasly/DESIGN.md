---
name: Weasly
colors:
  surface: '#fff8f5'
  surface-dim: '#e5d7d1'
  surface-bright: '#fff8f5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fff1ea'
  surface-container: '#f9ebe5'
  surface-container-high: '#f3e5df'
  surface-container-highest: '#ede0d9'
  on-surface: '#211a16'
  on-surface-variant: '#534438'
  inverse-surface: '#362f2b'
  inverse-on-surface: '#fceee7'
  outline: '#867466'
  outline-variant: '#d8c2b3'
  surface-tint: '#8e4e00'
  primary: '#8e4e00'
  on-primary: '#ffffff'
  primary-container: '#d98a3d'
  on-primary-container: '#512a00'
  inverse-primary: '#ffb778'
  secondary: '#2b694e'
  on-secondary: '#ffffff'
  secondary-container: '#aff1cd'
  on-secondary-container: '#317054'
  tertiary: '#7b5800'
  on-tertiary: '#ffffff'
  tertiary-container: '#c5942c'
  on-tertiary-container: '#453000'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdcc1'
  primary-fixed-dim: '#ffb778'
  on-primary-fixed: '#2e1500'
  on-primary-fixed-variant: '#6c3a00'
  secondary-fixed: '#aff1cd'
  secondary-fixed-dim: '#94d4b2'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#0b5137'
  tertiary-fixed: '#ffdea6'
  tertiary-fixed-dim: '#f4be53'
  on-tertiary-fixed: '#271900'
  on-tertiary-fixed-variant: '#5d4200'
  background: '#fff8f5'
  on-background: '#211a16'
  surface-variant: '#ede0d9'
  bgBase: '#FAF7F2'
  bgSurface: '#FFFFFF'
  textMuted: '#8A7F73'
  borderDefault: '#E8E1D8'
  stateError: '#D64545'
typography:
  headline-lg:
    fontFamily: Quicksand
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Quicksand
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-sm:
    fontFamily: Quicksand
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Quicksand
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 26px
  body-md:
    fontFamily: Quicksand
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Quicksand
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Quicksand
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  numeric-display:
    fontFamily: Quicksand
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
  numeric-body:
    fontFamily: Quicksand
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base-unit: 4px
  margin-mobile: 20px
  margin-tablet: 32px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style

The design system is built for a friendly, approachable mobile budget tracker. The brand personality is grounded in a "story-book warmth"—reliable but never cold, professional but inherently inviting. It shifts the perception of finance from a stressful chore to a gentle act of "stashing" and caring for one's resources.

The chosen style is **Modern Tactile**, blending clean layouts with soft, rounded geometry and organic, warm color tones. It avoids the clinical austerity of traditional fintech by using generous whitespace and high-quality, friendly typography.

### Design Principles
- **Approachable Utility:** Functionality is primary, but it is delivered through soft edges and warm interactions.
- **Narrative Warmth:** The UI supports the presence of a mascot through the use of natural, earthy accents (Ambers and Greens).
- **Clarity through Breathing Room:** Information density is kept low to reduce financial anxiety.

## Colors

The palette is inspired by natural, earthy tones to reinforce the "Weasly" mascot concept. 

- **Primary (Warm Amber):** Used for primary actions and brand presence. It reflects the coat of the mascot and evokes a sense of activity and warmth.
- **Secondary (Soft Green):** Reserved for positive financial states—income, "on-track" budget statuses, and success confirmations.
- **Tertiary (Muted Gold):** Specifically for warning states and near-limit indicators.
- **Backgrounds:** A soft cream (`bgBase`) provides a warmer, less fatiguing canvas than pure white, while `bgSurface` (pure white) is used to lift cards and interactive elements.
- **Neutral:** A deep chocolate-charcoal is used for text to maintain high legibility without the harshness of pure black.

## Typography

This design system utilizes **Quicksand** for its rounded terminals and open apertures, which match the friendly brand persona.

### Tabular Figures
Crucially, all numeric values (balances, transaction amounts, dates) must use `tabular-nums` settings. This ensures that columns of numbers align perfectly in lists and dashboard summaries, providing the precision required for a financial app despite the "soft" typeface.

### Scaling
Headlines use a tighter letter spacing and heavier weights to provide clear hierarchy. Body text remains airy. For mobile-specific scaling, `headline-lg` should scale down to 28px on devices with a width of less than 360px.

## Layout & Spacing

The layout philosophy follows a **Fluid Grid** model with a focus on single-column vertical rhythm, optimized for quick mobile entry.

- **Mobile (Default):** A 4-column fluid grid with 20px side margins and 16px gutters.
- **Tablet/Large Screen:** A max-width container of 600px is centered on the screen to prevent the UI from becoming uncomfortably wide, maintaining the focused mobile experience.

### Spacing Rhythm
Spacing follows a 4px baseline. Components are grouped using `stack-sm` (8px) for internal relationships, `stack-md` (16px) for standard vertical separation, and `stack-lg` (24px) for distinct section breaks.

## Elevation & Depth

This design system uses **Tonal Layering** combined with **Soft Ambient Shadows** to convey depth.

- **Level 0 (Base):** Uses `#FAF7F2`. No elevation. This is the "ground" where the mascot illustrations and page background sit.
- **Level 1 (Cards/Surfaces):** Pure white (`#FFFFFF`) surfaces with a very soft, diffused shadow (Blur: 12px, Y: 4, Opacity: 4% of `#2B2420`). These are the primary containers for transactions and summaries.
- **Level 2 (Floating Actions/Modals):** A more pronounced shadow (Blur: 20px, Y: 8, Opacity: 8% of `#2B2420`) to indicate interactive priority.

Avoid heavy borders; instead, use the `borderDefault` (`#E8E1D8`) as a subtle "ghost outline" only when white surfaces overlap to maintain definition without visual clutter.

## Shapes

The shape language is consistently rounded to mirror the Quicksand typeface and the friendly "Weasly" persona.

- **Small UI (Chips, Tags, Checkboxes):** 8px radius.
- **Buttons:** 12px radius, providing a distinct "squishy" but modern look.
- **Cards & Panels:** 16px radius.
- **Modals & Bottom Sheets:** 24px radius on the top corners only to create a "nested" feel when pulled from the bottom of the screen.

Iconography should follow a **Material-style stroke** with rounded caps and joins.

## Components

### Buttons
- **Primary:** Background `accentPrimary`, text `#FFFFFF`. High-contrast, rounded 12px.
- **Secondary:** Background `bgBase`, border `borderDefault`, text `textPrimary`. 
- **Success/Action:** Background `accentSecondary`, text `#FFFFFF`, used for "Add Income" or "Budget Met."

### Cards
- Always use `bgSurface` with 16px roundedness.
- Padding should be a uniform 16px (`stack-md`).
- Transactions within a card use a horizontal layout: Leading icon (rounded-8 background), middle text stack (Title + Muted Subtitle), trailing numeric amount (tabular-nums).

### Input Fields
- Filled style using `bgBase` or white with a `borderDefault`.
- On focus, the border transitions to `accentPrimary` with a 1px weight.
- Error states use `stateError` for both the border and the helper text.

### Progress Bars (Budgets)
- Track: `borderDefault` or a 10% opacity of the secondary color.
- Indicator: `accentSecondary` (safe), transitioning to `stateWarning` (>80%) and `stateError` (>100%).
- Rounded 8px caps on both track and indicator.

### Chips & Tags
- 8px roundedness. Used for categories. Use a low-opacity tint of the category color as the background and the full-saturation color for the text/icon.