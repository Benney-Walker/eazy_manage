import 'package:flutter/material.dart';

/// EazyManage color system — "Proposal A": deep-teal brand split from a
/// bright-green success state, warm neutrals, real elevation.
///
/// Every widget reads colors through [Theme.of] / [AppColors.of], never a
/// hard-coded hex. To retune a color across the whole app, change it here
/// once. Two instances are provided: [AppColors.light] and [AppColors.dark].
///
/// This is the Flutter equivalent of the JavaFX tokens.css + light/dark
/// theme files — same discipline, one source of truth.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // ---- Brand / primary ramp (deep teal-green) -----------------------------
  final Color brand50;
  final Color brand200;
  final Color brand400;
  final Color brand; // 600 — the primary action color
  final Color brand700;
  final Color brand800;
  final Color onBrand; // text/icon on a brand-filled surface

  // ---- Semantic accents ---------------------------------------------------
  final Color success;
  final Color successSubtle;
  final Color info;
  final Color infoSubtle;
  final Color warning;
  final Color warningSubtle;
  final Color danger;
  final Color dangerSubtle;
  final Color onSuccess;
  final Color onWarning;
  final Color onDanger;

  // ---- Surfaces -----------------------------------------------------------
  final Color bg; // outermost page background
  final Color bgAlt; // inset / alternate background
  final Color surface; // cards, panels, dialogs
  final Color surfaceAlt; // striped rows, subtle panels
  final Color surfaceElevated; // dropdowns, popovers

  // ---- Text ---------------------------------------------------------------
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;

  // ---- Lines & states -----------------------------------------------------
  final Color border;
  final Color borderStrong;
  final Color divider;
  final Color hover;
  final Color pressed;
  final Color selected;
  final Color focusRing;

  // ---- Inputs -------------------------------------------------------------
  final Color inputBg;
  final Color inputBorder;
  final Color inputBorderFocus;
  final Color inputPlaceholder;
  final Color inputDisabledBg;

  // ---- Tables -------------------------------------------------------------
  final Color tableHeaderBg;
  final Color tableHeaderText;
  final Color tableRow;
  final Color tableRowAlt;
  final Color tableRowHover;
  final Color tableRowSelected;
  final Color tableBorder;

  // ---- Sidebar (always dark slate in both themes) -------------------------
  final Color sidebar;
  final Color sidebarHover;
  final Color sidebarActive;
  final Color sidebarText;
  final Color sidebarTextActive;
  final Color sidebarTextMuted;
  final Color sidebarDivider;

  // ---- Sync status (offline engine, used later) ---------------------------
  final Color syncSynced;
  final Color syncPending;
  final Color syncFailed;
  final Color syncOffline;

  // ---- Elevation ----------------------------------------------------------
  final Color shadow;

  const AppColors({
    required this.brand50,
    required this.brand200,
    required this.brand400,
    required this.brand,
    required this.brand700,
    required this.brand800,
    required this.onBrand,
    required this.success,
    required this.successSubtle,
    required this.info,
    required this.infoSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.danger,
    required this.dangerSubtle,
    required this.onSuccess,
    required this.onWarning,
    required this.onDanger,
    required this.bg,
    required this.bgAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.hover,
    required this.pressed,
    required this.selected,
    required this.focusRing,
    required this.inputBg,
    required this.inputBorder,
    required this.inputBorderFocus,
    required this.inputPlaceholder,
    required this.inputDisabledBg,
    required this.tableHeaderBg,
    required this.tableHeaderText,
    required this.tableRow,
    required this.tableRowAlt,
    required this.tableRowHover,
    required this.tableRowSelected,
    required this.tableBorder,
    required this.sidebar,
    required this.sidebarHover,
    required this.sidebarActive,
    required this.sidebarText,
    required this.sidebarTextActive,
    required this.sidebarTextMuted,
    required this.sidebarDivider,
    required this.syncSynced,
    required this.syncPending,
    required this.syncFailed,
    required this.syncOffline,
    required this.shadow,
  });

  /// Convenience accessor: `AppColors.of(context)`.
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  // =========================================================================
  // LIGHT
  // =========================================================================
  static const AppColors light = AppColors(
    brand50: Color(0xFFE6F4F1),
    brand200: Color(0xFFA7D9CF),
    brand400: Color(0xFF4FB09B),
    brand: Color(0xFF0E7C66),
    brand700: Color(0xFF0A5C4C),
    brand800: Color(0xFF073E33),
    onBrand: Color(0xFFFFFFFF),

    success: Color(0xFF16A34A),
    successSubtle: Color(0x1F16A34A),
    info: Color(0xFF0EA5E9),
    infoSubtle: Color(0x1F0EA5E9),
    warning: Color(0xFFF59E0B),
    warningSubtle: Color(0x24F59E0B),
    danger: Color(0xFFE5484D),
    dangerSubtle: Color(0x1FE5484D),
    onSuccess: Color(0xFFFFFFFF),
    onWarning: Color(0xFF3D2A02),
    onDanger: Color(0xFFFFFFFF),

    bg: Color(0xFFFCFCFB),
    bgAlt: Color(0xFFF5F4F0),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFCFCFB),
    surfaceElevated: Color(0xFFFFFFFF),

    textPrimary: Color(0xFF1A1A17),
    textSecondary: Color(0xFF57564F),
    textMuted: Color(0xFF8C8B83),
    textInverse: Color(0xFFFFFFFF),

    border: Color(0xFFEDEBE6),
    borderStrong: Color(0xFFD8D6CF),
    divider: Color(0xFFEDEBE6),
    hover: Color(0xFFF5F4F0),
    pressed: Color(0xFFEDEBE6),
    selected: Color(0x1A0E7C66),
    focusRing: Color(0x660E7C66),

    inputBg: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFD8D6CF),
    inputBorderFocus: Color(0xFF0E7C66),
    inputPlaceholder: Color(0xFF8C8B83),
    inputDisabledBg: Color(0xFFF5F4F0),

    tableHeaderBg: Color(0xFFFCFCFB),
    tableHeaderText: Color(0xFF57564F),
    tableRow: Color(0xFFFFFFFF),
    tableRowAlt: Color(0xFFFCFCFB),
    tableRowHover: Color(0xFFF5F4F0),
    tableRowSelected: Color(0x140E7C66),
    tableBorder: Color(0xFFEDEBE6),

    // Sidebar stays dark slate in both themes.
    sidebar: Color(0xFF0A0F16),
    sidebarHover: Color(0xFF1B2530),
    sidebarActive: Color(0xFF12B893),
    sidebarText: Color(0xFF93A1B0),
    sidebarTextActive: Color(0xFFFFFFFF),
    sidebarTextMuted: Color(0xFF5E6B78),
    sidebarDivider: Color(0xFF1E2A36),

    syncSynced: Color(0xFF16A34A),
    syncPending: Color(0xFFF59E0B),
    syncFailed: Color(0xFFE5484D),
    syncOffline: Color(0xFF8C8B83),

    shadow: Color(0x14171310),
  );

  // =========================================================================
  // DARK
  // =========================================================================
  static const AppColors dark = AppColors(
    // Brand brightens in dark mode for adequate contrast on dark surfaces.
    brand50: Color(0xFF0E2B24),
    brand200: Color(0xFF1D5646),
    brand400: Color(0xFF2E8A72),
    brand: Color(0xFF12B893),
    brand700: Color(0xFF0E9A7B),
    brand800: Color(0xFF5DCAA5),
    onBrand: Color(0xFF04342C),

    success: Color(0xFF22C55E),
    successSubtle: Color(0x2922C55E),
    info: Color(0xFF38BDF8),
    infoSubtle: Color(0x2938BDF8),
    warning: Color(0xFFF59E0B),
    warningSubtle: Color(0x33F59E0B),
    danger: Color(0xFFF3676B),
    dangerSubtle: Color(0x29F3676B),
    onSuccess: Color(0xFF04240F),
    onWarning: Color(0xFF3D2A02),
    onDanger: Color(0xFF3A0C0D),

    bg: Color(0xFF0A0F16),
    bgAlt: Color(0xFF121A24),
    surface: Color(0xFF121A24),
    surfaceAlt: Color(0xFF1B2530),
    surfaceElevated: Color(0xFF1B2530),

    textPrimary: Color(0xFFE8EDF2),
    textSecondary: Color(0xFF93A1B0),
    textMuted: Color(0xFF5E6B78),
    textInverse: Color(0xFF0A0F16),

    border: Color(0xFF1E2A36),
    borderStrong: Color(0xFF2C3B49),
    divider: Color(0xFF1E2A36),
    hover: Color(0xFF1B2530),
    pressed: Color(0xFF2C3B49),
    selected: Color(0x2912B893),
    focusRing: Color(0x8012B893),

    inputBg: Color(0xFF0A0F16),
    inputBorder: Color(0xFF2C3B49),
    inputBorderFocus: Color(0xFF12B893),
    inputPlaceholder: Color(0xFF5E6B78),
    inputDisabledBg: Color(0xFF1B2530),

    tableHeaderBg: Color(0xFF0A0F16),
    tableHeaderText: Color(0xFF93A1B0),
    tableRow: Color(0xFF121A24),
    tableRowAlt: Color(0xFF0F1620),
    tableRowHover: Color(0xFF1B2530),
    tableRowSelected: Color(0x2912B893),
    tableBorder: Color(0xFF1E2A36),

    sidebar: Color(0xFF060A10),
    sidebarHover: Color(0xFF1B2530),
    sidebarActive: Color(0xFF12B893),
    sidebarText: Color(0xFF93A1B0),
    sidebarTextActive: Color(0xFFFFFFFF),
    sidebarTextMuted: Color(0xFF5E6B78),
    sidebarDivider: Color(0xFF1E2A36),

    syncSynced: Color(0xFF22C55E),
    syncPending: Color(0xFFF59E0B),
    syncFailed: Color(0xFFF3676B),
    syncOffline: Color(0xFF5E6B78),

    shadow: Color(0x73000000),
  );

  // =========================================================================
  // ThemeExtension plumbing
  // =========================================================================
  @override
  AppColors copyWith({
    Color? brand50,
    Color? brand200,
    Color? brand400,
    Color? brand,
    Color? brand700,
    Color? brand800,
    Color? onBrand,
    Color? success,
    Color? successSubtle,
    Color? info,
    Color? infoSubtle,
    Color? warning,
    Color? warningSubtle,
    Color? danger,
    Color? dangerSubtle,
    Color? onSuccess,
    Color? onWarning,
    Color? onDanger,
    Color? bg,
    Color? bgAlt,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textInverse,
    Color? border,
    Color? borderStrong,
    Color? divider,
    Color? hover,
    Color? pressed,
    Color? selected,
    Color? focusRing,
    Color? inputBg,
    Color? inputBorder,
    Color? inputBorderFocus,
    Color? inputPlaceholder,
    Color? inputDisabledBg,
    Color? tableHeaderBg,
    Color? tableHeaderText,
    Color? tableRow,
    Color? tableRowAlt,
    Color? tableRowHover,
    Color? tableRowSelected,
    Color? tableBorder,
    Color? sidebar,
    Color? sidebarHover,
    Color? sidebarActive,
    Color? sidebarText,
    Color? sidebarTextActive,
    Color? sidebarTextMuted,
    Color? sidebarDivider,
    Color? syncSynced,
    Color? syncPending,
    Color? syncFailed,
    Color? syncOffline,
    Color? shadow,
  }) {
    return AppColors(
      brand50: brand50 ?? this.brand50,
      brand200: brand200 ?? this.brand200,
      brand400: brand400 ?? this.brand400,
      brand: brand ?? this.brand,
      brand700: brand700 ?? this.brand700,
      brand800: brand800 ?? this.brand800,
      onBrand: onBrand ?? this.onBrand,
      success: success ?? this.success,
      successSubtle: successSubtle ?? this.successSubtle,
      info: info ?? this.info,
      infoSubtle: infoSubtle ?? this.infoSubtle,
      warning: warning ?? this.warning,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      danger: danger ?? this.danger,
      dangerSubtle: dangerSubtle ?? this.dangerSubtle,
      onSuccess: onSuccess ?? this.onSuccess,
      onWarning: onWarning ?? this.onWarning,
      onDanger: onDanger ?? this.onDanger,
      bg: bg ?? this.bg,
      bgAlt: bgAlt ?? this.bgAlt,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textInverse: textInverse ?? this.textInverse,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      divider: divider ?? this.divider,
      hover: hover ?? this.hover,
      pressed: pressed ?? this.pressed,
      selected: selected ?? this.selected,
      focusRing: focusRing ?? this.focusRing,
      inputBg: inputBg ?? this.inputBg,
      inputBorder: inputBorder ?? this.inputBorder,
      inputBorderFocus: inputBorderFocus ?? this.inputBorderFocus,
      inputPlaceholder: inputPlaceholder ?? this.inputPlaceholder,
      inputDisabledBg: inputDisabledBg ?? this.inputDisabledBg,
      tableHeaderBg: tableHeaderBg ?? this.tableHeaderBg,
      tableHeaderText: tableHeaderText ?? this.tableHeaderText,
      tableRow: tableRow ?? this.tableRow,
      tableRowAlt: tableRowAlt ?? this.tableRowAlt,
      tableRowHover: tableRowHover ?? this.tableRowHover,
      tableRowSelected: tableRowSelected ?? this.tableRowSelected,
      tableBorder: tableBorder ?? this.tableBorder,
      sidebar: sidebar ?? this.sidebar,
      sidebarHover: sidebarHover ?? this.sidebarHover,
      sidebarActive: sidebarActive ?? this.sidebarActive,
      sidebarText: sidebarText ?? this.sidebarText,
      sidebarTextActive: sidebarTextActive ?? this.sidebarTextActive,
      sidebarTextMuted: sidebarTextMuted ?? this.sidebarTextMuted,
      sidebarDivider: sidebarDivider ?? this.sidebarDivider,
      syncSynced: syncSynced ?? this.syncSynced,
      syncPending: syncPending ?? this.syncPending,
      syncFailed: syncFailed ?? this.syncFailed,
      syncOffline: syncOffline ?? this.syncOffline,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      brand50: Color.lerp(brand50, other.brand50, t)!,
      brand200: Color.lerp(brand200, other.brand200, t)!,
      brand400: Color.lerp(brand400, other.brand400, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brand700: Color.lerp(brand700, other.brand700, t)!,
      brand800: Color.lerp(brand800, other.brand800, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSubtle: Color.lerp(successSubtle, other.successSubtle, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSubtle: Color.lerp(infoSubtle, other.infoSubtle, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSubtle: Color.lerp(dangerSubtle, other.dangerSubtle, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      bgAlt: Color.lerp(bgAlt, other.bgAlt, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      pressed: Color.lerp(pressed, other.pressed, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputBorderFocus: Color.lerp(inputBorderFocus, other.inputBorderFocus, t)!,
      inputPlaceholder: Color.lerp(inputPlaceholder, other.inputPlaceholder, t)!,
      inputDisabledBg: Color.lerp(inputDisabledBg, other.inputDisabledBg, t)!,
      tableHeaderBg: Color.lerp(tableHeaderBg, other.tableHeaderBg, t)!,
      tableHeaderText: Color.lerp(tableHeaderText, other.tableHeaderText, t)!,
      tableRow: Color.lerp(tableRow, other.tableRow, t)!,
      tableRowAlt: Color.lerp(tableRowAlt, other.tableRowAlt, t)!,
      tableRowHover: Color.lerp(tableRowHover, other.tableRowHover, t)!,
      tableRowSelected: Color.lerp(tableRowSelected, other.tableRowSelected, t)!,
      tableBorder: Color.lerp(tableBorder, other.tableBorder, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      sidebarHover: Color.lerp(sidebarHover, other.sidebarHover, t)!,
      sidebarActive: Color.lerp(sidebarActive, other.sidebarActive, t)!,
      sidebarText: Color.lerp(sidebarText, other.sidebarText, t)!,
      sidebarTextActive: Color.lerp(sidebarTextActive, other.sidebarTextActive, t)!,
      sidebarTextMuted: Color.lerp(sidebarTextMuted, other.sidebarTextMuted, t)!,
      sidebarDivider: Color.lerp(sidebarDivider, other.sidebarDivider, t)!,
      syncSynced: Color.lerp(syncSynced, other.syncSynced, t)!,
      syncPending: Color.lerp(syncPending, other.syncPending, t)!,
      syncFailed: Color.lerp(syncFailed, other.syncFailed, t)!,
      syncOffline: Color.lerp(syncOffline, other.syncOffline, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
