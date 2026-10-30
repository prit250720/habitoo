---
name: Luminous Habit System
colors:
  surface: '#fff8f3'
  surface-dim: '#e0d9d3'
  surface-bright: '#fff8f3'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#faf2ec'
  surface-container: '#f4ede6'
  surface-container-high: '#eee7e1'
  surface-container-highest: '#e8e1db'
  on-surface: '#1e1b17'
  on-surface-variant: '#3d4a40'
  inverse-surface: '#33302c'
  inverse-on-surface: '#f7efe9'
  outline: '#6c7b6f'
  outline-variant: '#bbcabd'
  surface-tint: '#006d40'
  primary: '#006d40'
  on-primary: '#ffffff'
  primary-container: '#2eca7f'
  on-primary-container: '#004f2d'
  inverse-primary: '#4be092'
  secondary: '#a24000'
  on-secondary: '#ffffff'
  secondary-container: '#fe6b10'
  on-secondary-container: '#581f00'
  tertiary: '#984720'
  on-tertiary: '#ffffff'
  tertiary-container: '#ff976a'
  on-tertiary-container: '#762e08'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#6cfdac'
  primary-fixed-dim: '#4be092'
  on-primary-fixed: '#002110'
  on-primary-fixed-variant: '#00522f'
  secondary-fixed: '#ffdbcc'
  secondary-fixed-dim: '#ffb695'
  on-secondary-fixed: '#351000'
  on-secondary-fixed-variant: '#7b2f00'
  tertiary-fixed: '#ffdbcd'
  tertiary-fixed-dim: '#ffb597'
  on-tertiary-fixed: '#360f00'
  on-tertiary-fixed-variant: '#7a300a'
  background: '#fff8f3'
  on-background: '#1e1b17'
  surface-variant: '#e8e1db'
  surface-soft: '#F8FAFC'
  accent-warm: '#FFEADA'
  success-glow: rgba(46, 202, 127, 0.15)
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-max: 1200px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 40px
---

## Brand & Style

The design system is centered on the concept of "Effortless Momentum." It targets high-achievers and individuals seeking clarity in their daily routines. The brand personality is encouraging, organized, and refreshing, moving away from the "grind" culture toward a philosophy of sustainable growth.

The visual style is a blend of **Modern Minimalism** and **Soft-Tactile UI**. It utilizes expansive white space to reduce cognitive load, paired with vibrant teal accents that symbolize vitality and progress. The interface avoids unnecessary ornamentation, ensuring that the user’s habits remain the focal point. The emotional response should be one of "digital Zen"—a clean slate every morning that feels inviting rather than demanding.

## Colors

The palette is anchored by a high-energy **Teal (#2ECA7F)**, used for primary actions, success states, and progress indicators. This is contrasted against a deep **Charcoal (#2D2A26)** for typography to ensure maximum legibility and a grounded feel.

A secondary **Vibrant Orange (#FF6C11)** is used sparingly for urgent notifications or "streak" highlights, providing a warm energetic counterpoint to the cool teal. The background should remain predominantly **White (#FFFFFF)** or the light **Surface Soft (#F8FAFC)** to maintain a breathable, airy aesthetic. Use the **Accent Warm (#FFEADA)** for subtle container backgrounds when grouping related habit categories.

## Typography

This design system utilizes **Plus Jakarta Sans** for its approachable yet professional geometric structure. It provides a modern, "tech-forward" feel that is highly legible at various scales. For functional elements, **Hanken Grotesk** is introduced to provide a sharp, technical contrast for data-heavy areas like habit frequencies and timestamps.

Headlines should use tighter letter spacing and heavier weights to create a strong visual anchor. Body text maintains a generous line height (1.5x) to ensure the interface feels spacious and unhurried. Use "Display" sizes strictly for motivational milestones or empty-state messaging.

## Layout & Spacing

The design system employs a **Fluid Grid** model with a refined 8px spatial scale. On desktop, content is housed within a 12-column grid with generous 24px gutters to prevent visual clutter. 

**Breakpoints:**
- **Mobile (<600px):** Single column, 16px side margins. Cards span full width.
- **Tablet (600px - 1024px):** 8-column grid, 24px margins. Sidebar navigation collapses into a bottom bar.
- **Desktop (>1024px):** 12-column grid, 40px margins. Persistent left-hand navigation for quick access to habit categories.

Spacing should favor "Large" increments (24px, 32px, 48px) between major sections to emphasize the minimalist aesthetic.

## Elevation & Depth

Depth is communicated through **Tonal Layering** and **Soft Ambient Shadows**. Instead of traditional heavy drop shadows, this design system uses high-blur, low-opacity shadows (e.g., `box-shadow: 0 10px 30px rgba(45, 42, 38, 0.05)`) to make cards appear as if they are floating gently above the surface.

Interactive elements like "Complete Habit" buttons use a subtle **Inner Glow** when active, mimicking a physical press. Secondary containers use a 1px border in a very light grey or a subtle background tint (`#F8FAFC`) rather than shadows to maintain a flat, clean hierarchy for non-critical information.

## Shapes

The shape language is consistently **Rounded (0.5rem / 8px)**. This choice balances the professional nature of a productivity tool with the friendly, encouraging tone of a habit tracker. 

- **Small elements (Checkboxes, Tags):** 4px - 6px radius.
- **Standard elements (Buttons, Input Fields):** 8px radius.
- **Large elements (Cards, Modals):** 16px - 24px radius.

Interactive progress rings and "streak" badges should remain perfectly circular to provide a geometric contrast to the rectangular grid of the dashboard.

## Components

### Buttons
Primary buttons use the Teal (#2ECA7F) background with white text, featuring a subtle lift on hover. Secondary buttons use a Teal outline with a transparent background. All buttons have a minimum height of 48px to ensure ease of use on mobile devices.

### Habit Cards
Cards are the primary unit of the interface. They feature a white background, a soft ambient shadow, and a 16px internal padding. The left edge may feature a vertical color-coded bar indicating the habit category.

### Input Fields
Inputs utilize a light grey border (`#E2E8F0`) that transitions to a 2px Teal border on focus. Labels are placed above the field using the `label-md` typography style.

### Progress Indicators
Progress is visualized through "Luminous Rings." As a user nears habit completion, the ring fills with a gradient transition from a soft mint to the primary Teal, creating a rewarding visual "glow" effect.

### Chips/Tags
Used for habit categories (e.g., "Health," "Work"). These use a desaturated version of the category color with high-contrast text for maximum readability without distracting from the main habit title.