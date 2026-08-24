# UI Design System (as-built)

Package: `packages/design_system`  
Source: `lib/src/theme/udm_colors.dart`, `app_theme.dart`, `spacing.dart`, widgets.

---

# 1. Principles

Material Design 3. Light-first. Dense professional chrome, not playful. No per-network brand colors on entire cards — platform is a small badge + label.

---

# 2. Color tokens (`UdmColors`)

| Token | Hex | Use |
|-------|-----|-----|
| electricBlue | `#1B6EF3` | Light primary seed |
| electricBlueDim | `#1249A8` | Light primary dim |
| signalCyan | `#2F9EAE` | Dark primary seed |
| cyanDim | `#1C5F68` | Dark primary container |
| voidGraphite | `#12151A` | Dark surface |
| raisedSlate | `#1A1F27` | Dark container |
| insetWell | `#0E1116` | Dark input fill |
| porcelain | `#E8ECF1` | Dark on-surface |
| fogSteel | `#8B95A1` | Dark variant |
| hairline | `#2A3140` | Dark outline |
| paper | `#F4F6F8` | Light surface |
| whiteSurface | `#FFFFFF` | Light containers |
| ink | `#1A1F27` | Light on-surface |
| slateMute | `#5C6770` | Light variant |
| lightHairline | `#D5DBE2` | Light outline |
| successMoss | `#3D9A6A` | Success |
| cautionAmber | `#C49A3C` | Tertiary / caution |
| faultCoral | `#C45C5C` | Error |
| onAccent | `#071416` | Text on primary |

Light ColorScheme primaryContainer `#D6E4FF`. Dark surfaceContainerHigh `#222834`, highest `#2A3140`.

---

# 3. Typography

Theme starts from `ThemeData` MD3 type scale, then:

- headlineSmall / titleLarge: w600, tight letter-spacing
- titleSmall: w600, letterSpacing 0.8, fontSize 12, onSurfaceVariant
- labelSmall: w600, letterSpacing 0.6, fontSize 11
- AppBar title: titleLarge w600

---

# 4. Spacing (`UdmSpacing`)

xs 4, sm 8, md 12, lg 16, xl 20, xxl 24, xxxl 32, huge 40, massive 48, giant 64.

---

# 5. Radius (`UdmRadius`)

card 12, button 20, sheet 16.

Theme actually uses:

- Cards 12 + outline
- Buttons 12 (Filled/Outlined `minimumSize` 44×44)
- Input 14
- Dialog 16
- Sheet top 16
- Snackbar 12

Match `AppTheme._baseTheme`, not a second design language.

---

# 6. Components in package

| File | Widgets |
|------|---------|
| `udm_scaffold.dart` | `UdmScaffold` — semantic header/label |
| `empty_state.dart` | `EmptyState` |
| `onboarding_widgets.dart` | Onboarding chrome used by `OnboardingFlow` |
| `udm_components.dart` | Shared buttons/fields/cards as exported |

App-specific cards (`DownloadTaskCard`, `MediaPreviewCard`, `StorageDashboard`, file tiles) live in **app_core**, styled with this theme.

---

# 7. Navigation chrome

`NavigationBar` height 80, elevation 0, labels always shown, indicator primary @ 18% alpha.

`NavigationRail` themed for ≥840dp but **MainShell ships bottom bar only**.

Breakpoints: tablet 600, desktop 840 (`UdmBreakpoints`) — reserved, not a second IA.

---

# 8. Theme API

```dart
AppTheme.light();
AppTheme.dark();
AppTheme.fromPreference(ThemeModePreference preference, {seedColor, platformBrightness});
```

`ThemeModePreference`: light, dark, system (`shared_types`). Unset → light.

---

# 9. Motion

No custom animation system package. Use Flutter implicit animations and Material defaults. Do not add a lottie-heavy motion layer for V1.
