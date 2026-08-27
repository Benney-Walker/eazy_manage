import 'package:flutter/material.dart';

import 'nav_item.dart';

abstract final class NavRegistry {
  // Role bundles, matching the JavaFX sets.
  static const _all = <AppRole>{
    AppRole.principal,
    AppRole.administrator,
    AppRole.accountant,
    AppRole.teachingStaff,
  };
  static const _principalAdmin = <AppRole>{
    AppRole.principal,
    AppRole.administrator,
  };
  static const _adminOnly = <AppRole>{AppRole.administrator};
  static const _notAccountant = <AppRole>{
    AppRole.principal,
    AppRole.administrator,
    AppRole.teachingStaff,
  };
  static const _accountantOnly = <AppRole>{AppRole.accountant};
  static const _teachingOnly = <AppRole>{AppRole.teachingStaff};

  static const List<NavSection> _sections = [
    NavSection(
      title: 'OPERATIONS',
      items: [
        NavItem(id: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_rounded, roles: _all),
        NavItem(id: 'attendance', label: 'Attendance', icon: Icons.event_available_rounded, roles: _notAccountant),
        NavItem(id: 'results', label: 'Results', icon: Icons.star_rounded, roles: _teachingOnly),
        NavItem(id: 'finance', label: 'Finance', icon: Icons.payments_rounded, roles: _accountantOnly),
        NavItem(id: 'students', label: 'Students', icon: Icons.groups_rounded, roles: _notAccountant),
        NavItem(id: 'staff', label: 'Staff', icon: Icons.badge_rounded, roles: _principalAdmin),
        NavItem(id: 'conduct', label: 'Conduct', icon: Icons.flag_rounded, roles: _teachingOnly),
      ],
    ),
    NavSection(
      title: 'RECORDS',
      items: [
        NavItem(id: 'reports', label: 'Reporting Center', icon: Icons.assessment_rounded, roles: _all),
        NavItem(id: 'audit-logs', label: 'Audit Logs', icon: Icons.receipt_long_rounded, roles: _adminOnly),
      ],
    ),
    NavSection(
      title: 'COMMUNICATION',
      items: [
        NavItem(id: 'broadcasts', label: 'Broadcasts', icon: Icons.campaign_rounded, roles: _principalAdmin),
        //NavItem(id: 'active-sessions', label: 'Active Sessions', icon: Icons.wifi_tethering_rounded, roles: _adminOnly),
      ],
    ),
    NavSection(
      title: 'SYSTEM',
      items: [
        NavItem(id: 'academic-setup', label: 'Academic Setup', icon: Icons.edit_note_rounded, roles: _adminOnly),
        NavItem(id: 'settings', label: 'Settings', icon: Icons.settings_rounded, roles: _all),
      ],
    ),
  ];

  /// Sections visible to [role], with empty sections removed.
  static List<NavSection> sectionsFor(AppRole role) {
    final result = <NavSection>[];
    for (final section in _sections) {
      final visible = section.items.where((i) => i.availableFor(role)).toList();
      if (visible.isNotEmpty) {
        result.add(NavSection(title: section.title, items: visible));
      }
    }
    return result;
  }

  /// Flat list of every item (unfiltered) — handy for route generation.
  static List<NavItem> get allItems =>
      _sections.expand((s) => s.items).toList(growable: false);

  /// Look up an item by id.
  static NavItem? findById(String id) {
    for (final section in _sections) {
      for (final item in section.items) {
        if (item.id == id) return item;
      }
    }
    return null;
  }

  /// The landing route every role can see.
  static const String home = 'dashboard';
}