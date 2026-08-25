# Design System: Downivo

A dark-first premium media utility. Paste a link, download it, manage the file. The atmosphere is restrained and technical — a precision instrument, not a social network and not an admin dashboard.

Density: Daily App Balanced (6). Variance: Predictable with one offset hero (URL field). Motion: Fluid CSS / spring, restrained (4).

## 1. Visual Theme & Atmosphere

Void-graphite canvas with raised slate surfaces. Hairline borders instead of heavy shadows. One cool cyan accent for progress, focus, and the primary download action. Everything else is neutral. Media thumbnails carry the color; chrome stays quiet.

The Home hero is a large URL field, left-aligned, occupying the top of the content column — not a marketing headline, not a centered splash.

## 2. Color Palette & Roles

Dark (default):

- **Void Graphite** (#12151A) — App canvas, scaffold background
- **Raised Slate** (#1A1F27) — Cards, sheets, app bars
- **Inset Well** (#0E1116) — URL field fill, code-like inputs
- **Porcelain** (#E8ECF1) — Primary text
- **Fog Steel** (#8B95A1) — Secondary text, metadata, timestamps
- **Hairline** (#2A3140) — 1px borders, dividers
- **Signal Cyan** (#2F9EAE) — Single accent: CTAs, progress, focus rings, active nav
- **Cyan Dim** (#1C5F68) — Accent pressed / progress track tint
- **Success Moss** (#3D9A6A) — Completed status only
- **Caution Amber** (#C49A3C) — Paused / verifying
- **Fault Coral** (#C45C5C) — Failed / error text
- **On Accent** (#071416) — Text on filled cyan buttons

Light:

- **Paper** (#F4F6F8) — Canvas
- **White Surface** (#FFFFFF) — Cards
- **Ink** (#1A1F27) — Primary text
- **Slate Mute** (#5C6770) — Secondary text
- **Signal Cyan** (#2F9EAE) — Same accent

Banned: pure black (#000000), neon glow, purple/violet CTAs, per-platform card fills (no YouTube-red rows, no Instagram-pink tiles), rainbow chip walls, glassmorphism overlays, gradient text.

Platform identity: 16–20px glyph + 12px Fog Steel label. Never recolor the card.

## 3. Typography Rules

- **Display / titles:** Outfit, weight 600, tracking tight (−0.02em). Screen titles 22–24px. Section labels 13px uppercase-adjacent, Fog Steel, weight 600, letter-spacing 0.06em.
- **Body:** Outfit, weight 400, 15–16px, line-height 1.45.
- **Metadata / bytes / speed / ETA / progress %:** JetBrains Mono, 12–13px, Fog Steel.
- **Filenames:** Outfit 15px medium, one line ellipsis.
- **Banned:** Inter, generic serifs, decorative display fonts.

## 4. Component Stylings

- **Buttons:** Primary = Signal Cyan fill, 12px radius, 44px min height, tactile press (scale 0.98). Secondary = Hairline border, transparent fill. Destructive = Fault Coral outline. No glow.
- **Cards:** Raised Slate, 12px radius, 1px Hairline, no drop shadow on mobile. Elevation only for sheets (16px top radius).
- **URL input:** Inset Well, 14px radius, 52–56px height, leading link icon, trailing paste/clear. Focus = 1.5px Signal Cyan ring. Resolving = cyan indeterminate bar under the field. Invalid = Fault Coral ring + helper text below.
- **Download card:** Horizontal: 56px thumb (or mime icon well) · title + platform badge · status chip · progress bar full width · mono bytes/speed/ETA · icon actions 44px.
- **Progress:** Track Hairline, fill Signal Cyan. Paused = Caution Amber fill. Completed = Success Moss. Failed = Fault Coral.
- **Status chips:** Quiet pill, 1px border, 11px Outfit medium. Not rainbow blobs.
- **Navigation:** Mobile bottom bar, Void Graphite, cyan indicator. Desktop: 72–88px left rail, icons + labels, same five destinations.
- **Sheets / dialogs:** Raised Slate, 16px top corners, drag handle. Primary action full-width on mobile.
- **Toasts:** Compact snackbars, Hairline border, no giant banners.
- **Skeletons:** Shimmer on Raised Slate matching card geometry. No centered spinners as the only loading treatment on lists.
- **Empty states:** One icon (64px Fog Steel), title, one-line subtitle, one primary CTA max.
- **Platform badge:** Icon + name. Neutral.

## 5. Layout Principles

- Mobile content max width = screen, horizontal padding 16px, vertical rhythm 8pt grid (4/8/12/16/24/32).
- Home order: top bar → URL field → resolved preview (if any) → active downloads (max 3) → recent → storage summary → supported platforms as a quiet wrap of small badges (not marketing tiles).
- Desktop: left rail + 12px padded column. Downloads may split list | detail. Files may use wider rows. Preview media up to 320px.
- Single column below 768px. No horizontal page scroll.
- Touch targets 44px. Body text ≥ 14px.

## 6. Motion & Interaction

- Spring-ish: 200–280ms, ease-out. URL detection: badge fade/slide 160ms.
- Progress width may animate; prefer opacity/transform for cards and sheets.
- Stagger list items max 40ms and only on first populate.
- Honor reduced motion: skip stagger, instant sheets.

## 7. Anti-Patterns (Banned)

- Emojis in UI chrome
- Inter font
- Pure black canvas
- Neon / outer glow / glassmorphism
- Per-platform full-card colors
- Three equal marketing feature cards
- Fake metrics, fake storage %, fake download speeds
- “Elevate / Seamless / Unleash / Next-Gen”
- “Scroll to explore”
- Generic dashboard widgets (charts, KPI tiles)
- Quality pickers or buttons for features the app does not have
- Dailymotion (not in the engine)
- Invented screens: Collections, Activity Center, Notification Center, Media Library tab
