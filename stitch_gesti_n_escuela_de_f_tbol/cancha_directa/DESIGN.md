---
name: Cancha Directa
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f3'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#40493d'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f1f1f1'
  outline: '#707a6c'
  outline-variant: '#bfcaba'
  surface-tint: '#1b6d24'
  primary: '#0d631b'
  on-primary: '#ffffff'
  primary-container: '#2e7d32'
  on-primary-container: '#cbffc2'
  inverse-primary: '#88d982'
  secondary: '#5f5e5e'
  on-secondary: '#ffffff'
  secondary-container: '#e5e2e1'
  on-secondary-container: '#656464'
  tertiary: '#7e4900'
  on-tertiary: '#ffffff'
  tertiary-container: '#a05e00'
  on-tertiary-container: '#ffeee2'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#a3f69c'
  primary-fixed-dim: '#88d982'
  on-primary-fixed: '#002204'
  on-primary-fixed-variant: '#005312'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#474646'
  tertiary-fixed: '#ffdcbe'
  tertiary-fixed-dim: '#ffb870'
  on-tertiary-fixed: '#2c1600'
  on-tertiary-fixed-variant: '#693c00'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  data-display:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '800'
    lineHeight: 28px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  touch-target-min: 48px
  grid-margin: 16px
  grid-gutter: 12px
---

## Brand & Style
The design system is engineered for efficiency and clarity in the high-energy environment of soccer school management. The target audience includes coaches, administrators, and parents who require immediate access to payment status, attendance, and scheduling. 

The style is **Corporate / Modern** with a lean toward **Minimalism**, prioritizing high contrast and functional density over decorative elements. It draws inspiration from high-utility apps like WhatsApp, utilizing a clean white-label aesthetic that feels familiar, reliable, and accessible. The interface focuses on "Direct Action"—reducing the number of taps required to complete administrative tasks through clear visual hierarchies and robust touch targets.

## Colors
The palette is grounded in "Field Green," providing an immediate mental connection to the sport. 

- **Primary (#2E7D32):** Used for main actions, headers, and active navigation states.
- **Secondary (#121212):** Reserved for high-contrast typography and critical UI boundaries.
- **Accent (#FF9800):** A warm, high-visibility color used exclusively for Call-to-Action (CTA) buttons and urgent alerts.
- **Backgrounds:** Pure white (#FFFFFF) for the primary canvas to ensure maximum readability under outdoor lighting conditions.
- **Surface:** Soft Gray (#F5F5F5) is used for card containers and secondary input backgrounds to create subtle grouping without heavy borders.
- **Semantic Dots:** A strict status system using Green (Paid), Yellow (Partial/Warning), and Red (Overdue) for rapid scanning of lists.

## Typography
This design system uses **Inter** for its exceptional legibility and neutral, professional tone. 

- **Financial Data:** A specific `data-display` style is used for currency and metrics. It utilizes a heavier weight (Extra Bold) to ensure numbers stand out at a glance.
- **Language:** All microcopy and labels are in Latin American Spanish, utilizing direct, action-oriented verbs (e.g., "Cobrar," "Inscribir," "Asistencia").
- **Scale:** Sizes are optimized for a 360px width, ensuring that even at the smallest label size, text remains legible in high-glare environments.

## Layout & Spacing
The layout follows a **Fluid Grid** model optimized for Android handheld devices (360x800).

- **Margins:** A standard 16px lateral margin is applied to all screens.
- **Gutter:** 12px spacing between elements in a vertical list or grid.
- **Touch Targets:** All interactive elements (buttons, icons, list items) must maintain a minimum height/width of 48px to accommodate rapid use during active training sessions.
- **Density:** High-density lists are preferred for student rosters, but individual cards must have ample internal padding (16px) to maintain a clean, "WhatsApp-like" simplicity.

## Elevation & Depth
The design system uses a **Tonal Layering** approach combined with subtle ambient shadows to define hierarchy.

- **Level 0 (Background):** Pure White (#FFFFFF).
- **Level 1 (Cards/Containers):** Soft Gray (#F5F5F5) with no shadow. Used for secondary information groups.
- **Level 2 (Active Cards):** White (#FFFFFF) with a subtle shadow (Blur: 4px, Y: 2px, Opacity: 8% Black). Used for primary interactive items like student profiles or payment entries.
- **Floating Action Buttons (FAB):** Higher elevation (Blur: 8px, Y: 4px, Opacity: 15% Primary Color) to signify the primary action of the screen (e.g., "Add Student").

## Shapes
The shape language is friendly yet structured. 

- **Standard Elements:** A consistent 12px (0.75rem) corner radius is applied to cards, input fields, and buttons. This provides a modern, approachable feel while maintaining professional structure.
- **Status Indicators:** Small circular dots (radius: 100%) are used for status signaling to differentiate them from interactive buttons.
- **Selection States:** Checkboxes and radio buttons use standard circular or slightly rounded-square geometry for platform familiarity.

## Components
- **Buttons:**
    - *Primary:* Field Green background, White text, 12px corners, 48px height.
    - *CTA:* Warm Orange (#FF9800) background for "Pay Now" or "Urgent" actions.
- **Status Indicators:**
    - Located at the leading or trailing edge of list items. A solid 10px circle.
    - Colors: Success (Green), Warning (Yellow), Error (Red).
- **Cards:**
    - Primary cards are White with a Level 2 shadow.
    - Secondary cards use the Soft Gray (#F5F5F5) surface with no shadow for "read-only" data.
- **Input Fields:**
    - Outlined style with a 1px Soft Gray border.
    - On focus: Border thickens to 2px Primary Green.
    - Error state: Border becomes Red with accompanying text.
- **Lists:**
    - High-contrast list items with 16px vertical padding. 
    - Divider lines are 1px thick in Soft Gray, inset 16px from the left to align with text.
- **Chips:**
    - Small 32px height pills used for category filtering (e.g., "Categoría U-10," "Categoría U-12").