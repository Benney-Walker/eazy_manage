import 'package:flutter/material.dart';

@immutable
class NavItem {
  /// Stable id — also used as the go_router path (e.g. 'dashboard').
  final String id;
  final String label;
  final IconData icon;

  /// Roles permitted to see this item. Empty = everyone.
  final Set<AppRole> roles;

  const NavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.roles = const {},
  });

  bool availableFor(AppRole role) => roles.isEmpty || roles.contains(role);

  /// Route path with leading slash.
  String get path => '/$id';
}

/// A titled group of nav items (OPERATIONS, RECORDS, …).
@immutable
class NavSection {
  final String title;
  final List<NavItem> items;

  const NavSection({required this.title, required this.items});
}

/// The five roles from the backend. `label` is the display form used in the
/// user footer and role-related UI.
enum AppRole {
  principal('Principal'),
  administrator('Administrator'),
  accountant('Accountant'),
  teachingStaff('Teaching Staff');

  final String label;
  const AppRole(this.label);

  /// The backend enum string form (e.g. AppRole.teachingStaff -> "TEACHING_STAFF").
  String get backendValue => switch (this) {
        AppRole.principal => 'PRINCIPAL',
        AppRole.administrator => 'ADMINISTRATOR',
        AppRole.accountant => 'ACCOUNTANT',
        AppRole.teachingStaff => 'TEACHING_STAFF',
      };

  /// Parse a backend role string (e.g. "TEACHING_STAFF") into an [AppRole].
  static AppRole fromBackend(String? raw) {
    switch (raw?.toUpperCase().trim()) {
      case 'PRINCIPAL':
        return AppRole.principal;
      case 'ADMINISTRATOR':
        return AppRole.administrator;
      case 'ACCOUNTANT':
        return AppRole.accountant;
      case 'TEACHING_STAFF':
        default:
        return AppRole.teachingStaff;
    }
  }
}
