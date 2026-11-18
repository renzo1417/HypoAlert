/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Unified Mobile Design System Tokens.
 * Mobile-first, clinical-grade, anti-slop color palette and typography scale.
 */

export class PhoneTheme {
  // --- Surfaces & Backgrounds (layered: page < sunken < card) ---
  static readonly BG_PAGE: string = '#EDF1F6';        // Deeper cool-slate canvas, lifts white hero
  static readonly BG_CARD: string = '#FFFFFF';        // Hero / elevated only
  static readonly BG_RAISED: string = '#FFFFFF';      // Elevated surface alias
  static readonly BG_SUNKEN: string = '#E2E8F0';      // Quiet secondary tiles, visible separation
  static readonly BG_MUTED: string = '#E2E8F0';       // Input / sunken fill
  static readonly BG_SUBTLE: string = '#F3F6FA';      // Subtle container
  static readonly BG_NAV: string = '#FFFFFF';         // Floating navigation surface

  // --- Borders ---
  static readonly BORDER_SUBTLE: string = '#DCE4EE';   // Slightly deeper for contrast on #EDF1F6
  static readonly BORDER_LIGHT: string = '#E6EDF5';    // Inner dividers
  static readonly BORDER_FOCUS: string = '#0F172A';    // Active border

  // --- Text Hierarchy ---
  static readonly TEXT_PRIMARY: string = '#0F172A';   // Slate 900 for high-contrast titles & metrics
  static readonly TEXT_SECONDARY: string = '#334155'; // Slate 700 for subtitles & section headers
  static readonly TEXT_MUTED: string = '#64748B';     // Slate 500 for descriptions & metadata
  static readonly TEXT_TERTIARY: string = '#94A3B8';  // Slate 400 for units, timestamps & hints
  static readonly TEXT_ON_DARK: string = '#FFFFFF';   // White on dark buttons/chips

  // --- Brand & Primary Interactive ---
  static readonly BRAND_PRIMARY: string = '#0F172A';  // Slate 900 primary button / active tab
  static readonly BRAND_ACCENT: string = '#0284C7';   // Sky 600 active link / sync indicator
  static readonly BRAND_ACCENT_BG: string = '#F0F9FF';// Sky 50 soft badge fill

  // --- Semantic Health States ---
  // Normal / Stable
  static readonly STATE_OK: string = '#10B981';       // Emerald 500
  static readonly STATE_OK_TEXT: string = '#047857';  // Emerald 700
  static readonly STATE_OK_BG: string = '#ECFDF5';    // Emerald 50

  // Warning / Pre-Drop Dip
  static readonly STATE_WARN: string = '#F59E0B';     // Amber 500
  static readonly STATE_WARN_TEXT: string = '#B45309';// Amber 700
  static readonly STATE_WARN_BG: string = '#FFFBEB';  // Amber 50

  // Critical / Hypo Emergency
  static readonly STATE_CRIT: string = '#EF4444';     // Red 500
  static readonly STATE_CRIT_DARK: string = '#DC2626';// Red 600
  static readonly STATE_CRIT_TEXT: string = '#B91C1C';// Red 700
  static readonly STATE_CRIT_BG: string = '#FEF2F2';  // Red 50

  // --- Mobile-First Typography Scale (in fp / sp) ---
  static readonly FONT_HERO: number = 32;             // Main symptom risk reading, single dominant number
  static readonly FONT_TITLE: number = 18;            // Screen headers, quieter
  static readonly FONT_SECTION: number = 14;          // Card titles & section headers
  static readonly FONT_SUBTITLE: number = 13;         // Card subtitle / secondary text
  static readonly FONT_BODY: number = 12;             // Regular descriptions & list items
  static readonly FONT_CAPTION: number = 11;          // Status badges & timestamps
  static readonly FONT_MICRO: number = 10;            // Metric units & compact chips

  // --- Layout & Component Geometry ---
  static readonly CARD_RADIUS: number = 16;           // Consistent card corner radius
  static readonly TILE_RADIUS: number = 12;           // Sub-card / metric tile corner radius
  static readonly PILL_RADIUS: number = 999;          // Rounded badge radius
  static readonly CARD_PADDING: number = 16;          // Standard interior card padding
  static readonly TOUCH_MIN: number = 48;             // Minimum accessible touch target (px)
}
