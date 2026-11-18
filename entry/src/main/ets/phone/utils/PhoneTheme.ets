/*
 * Copyright (c) 2026 HypoAlert.
 * Phone Companion — Pastel Bento Wellness & Clinical Precision Design Tokens.
 * Soft alabaster canvas, sky/lavender/sage/peach bento cards, obsidian floating dock, and vivid sky-blue action FAB.
 */

export class PhoneTheme {
  // --- Canvas & Base Surfaces ---
  static readonly BG_PAGE: string = '#F7F8FA';         // Airy cool off-white canvas
  static readonly BG_CARD: string = '#FFFFFF';         // Pure white bento & report surfaces
  static readonly BG_RAISED: string = '#FFFFFF';       // Elevated card alias
  static readonly BG_INSET: string = '#F1F3F7';        // Quiet recessed pill & date chips
  static readonly BG_SUNKEN: string = '#E8ECF2';       // Subtle active neutral chip
  static readonly BG_SUBTLE: string = '#F8F9FB';       // Soft row backing
  static readonly BG_NAV: string = '#111318';          // Obsidian floating dock pill

  // --- Reference Pastel Bento Palette ---
  static readonly HERO_SKY_TOP: string = '#DCE7F2';    // Hero sky-steel gradient start
  static readonly HERO_SKY_BOT: string = '#CEDEEB';    // Hero sky-steel gradient end
  static readonly BENTO_LAV_TOP: string = '#EAE2F8';   // Lavender card start
  static readonly BENTO_LAV_BOT: string = '#DFD3F5';   // Lavender card end
  static readonly BENTO_LAV_LINE: string = '#8B5CF6';  // Lavender curve stroke
  static readonly BENTO_SAGE_TOP: string = '#E2EFE0';  // Sage green card start
  static readonly BENTO_SAGE_BOT: string = '#D5E7D2';  // Sage green card end
  static readonly BENTO_PEACH_TOP: string = '#F8E5DE'; // Peach card start
  static readonly BENTO_PEACH_BOT: string = '#F2D9D0'; // Peach card end

  // --- Hairlines & Borders ---
  static readonly BORDER_SUBTLE: string = '#E6E9EF';   // Crisp subtle hairline
  static readonly BORDER_LIGHT: string = '#EEF0F4';    // Internal divider hairline
  static readonly BORDER_FOCUS: string = '#2A82F0';    // Active blue border

  // --- Text Ink Hierarchy ---
  static readonly TEXT_PRIMARY: string = '#111318';    // Deep obsidian charcoal
  static readonly TEXT_SECONDARY: string = '#4B5563';  // Slate charcoal
  static readonly TEXT_MUTED: string = '#7C8494';      // Calm cool gray
  static readonly TEXT_TERTIARY: string = '#A1A8B5';   // Subtle units & hints
  static readonly TEXT_ON_DARK: string = '#FFFFFF';    // Pure white on dark dock / red crisis

  // --- Brand & Interactive Accents ---
  static readonly BRAND_PRIMARY: string = '#111318';   // Obsidian black active pills & buttons
  static readonly BRAND_ACCENT: string = '#2A82F0';    // Vivid sky-cobalt blue FAB & arc segment
  static readonly BRAND_ACCENT_BG: string = '#EBF4FF'; // Soft sky selection fill

  // --- Semantic Clinical States ---
  static readonly STATE_OK: string = '#22C55E';        // Healthy emerald dot
  static readonly STATE_OK_TEXT: string = '#166534';   // Deep forest green on mint pill
  static readonly STATE_OK_BG: string = '#D9F5D8';     // Soft mint status pill

  static readonly STATE_WARN: string = '#F5B70A';      // Golden amber arc segment & caution
  static readonly STATE_WARN_TEXT: string = '#92400E'; // Deep amber-brown ink
  static readonly STATE_WARN_BG: string = '#FEF3C7';   // Soft amber fill
  static readonly STATE_WARN_BORDER: string = '#FDE68A';

  static readonly STATE_CRIT: string = '#EF4444';      // Coral-red bars & arc critical segment
  static readonly STATE_CRIT_DARK: string = '#DC2626'; // Urgent crimson hero fill
  static readonly STATE_CRIT_TEXT: string = '#B91C1C'; // Deep red ink on light
  static readonly STATE_CRIT_BG: string = '#FEE2E2';   // Soft rose status pill

  // --- Typography Scale (fp / sp) ---
  static readonly FONT_HERO: number = 38;              // Dominant metric reading
  static readonly FONT_DISPLAY: number = 28;           // Screen greeting headline
  static readonly FONT_TITLE: number = 22;             // Page titles
  static readonly FONT_METRIC: number = 26;            // Bento metric figures
  static readonly FONT_SECTION: number = 17;           // Section headers (Overview, Night Summary)
  static readonly FONT_SUBTITLE: number = 14;          // Action button & card headers
  static readonly FONT_BODY: number = 13;              // Body descriptions
  static readonly FONT_CAPTION: number = 11;           // Supporting labels & dates
  static readonly FONT_MICRO: number = 10;             // Badges & units

  // --- Geometry ---
  static readonly CARD_RADIUS: number = 24;            // Generous rounded bento cards
  static readonly TILE_RADIUS: number = 16;            // Inner tiles & action pills
  static readonly PILL_RADIUS: number = 999;           // Full pill capsule
  static readonly CARD_PADDING: number = 18;           // Standard card interior padding
  static readonly TOUCH_MIN: number = 44;              // Minimum tap height
}
