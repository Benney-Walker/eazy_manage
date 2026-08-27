import 'package:flutter/material.dart';

import '../../../core/navigation/nav_item.dart';

/// A report in the Reporting Center (mirrors the JavaFX `ReportDefinition` +
/// `ReportCatalogue`). Each entry is role-gated and routes to its own screen.
class ReportDefinition {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Set<AppRole> roles;

  const ReportDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.roles,
  });

  bool availableFor(AppRole role) => roles.contains(role);
}

/// The report catalogue. Role sets mirror the JavaFX catalogue exactly.
class ReportCatalogue {
  static const _adminOnly = <AppRole>{AppRole.administrator};
  static const _adminPrincipal = <AppRole>{
    AppRole.administrator,
    AppRole.principal,
  };
  static const _accountantPrincipal = <AppRole>{
    AppRole.accountant,
    AppRole.principal,
  };
  static const _notAccountant = <AppRole>{
    AppRole.principal,
    AppRole.administrator,
    AppRole.teachingStaff,
    AppRole.generalStaff,
  };

  static const all = <ReportDefinition>[
    ReportDefinition(
      id: 'class-results',
      title: 'Class Results',
      description:
      'End-of-term results for a whole class: every student with totals, '
          'averages, and positions.',
      icon: Icons.summarize_rounded,
      roles: _notAccountant,
    ),
    ReportDefinition(
      id: 'master-score-sheet',
      title: 'Master Score Sheet',
      description:
      'Wide spreadsheet of every student in a class against every '
          'subject total — the class teacher\'s end-of-term sheet.',
      icon: Icons.grid_on_rounded,
      roles: _notAccountant,
    ),
    ReportDefinition(
      id: 'sba',
      title: 'SBA Report',
      description:
      'School-based assessment breakdown for one subject: each component '
          'score per student for a class and term.',
      icon: Icons.fact_check_rounded,
      roles: _notAccountant,
    ),
    ReportDefinition(
      id: 'report-card',
      title: 'Student Report Card',
      description:
      'Individual report card for one student and term — subject '
          'scores, conduct, remarks, and attendance.',
      icon: Icons.badge_rounded,
      roles: _notAccountant,
    ),
    ReportDefinition(
      id: 'grade-payments',
      title: 'Class Payments',
      description:
      'Fees paid and outstanding for every student in a class for a '
          'term.',
      icon: Icons.account_balance_wallet_rounded,
      roles: _accountantPrincipal,
    ),
    ReportDefinition(
      id: 'student-payments',
      title: 'Student Payments',
      description:
      'One student\'s fee position and full payment history for a '
          'term.',
      icon: Icons.receipt_rounded,
      roles: _accountantPrincipal,
    ),
    ReportDefinition(
      id: 'expenses-report',
      title: 'Expenses Report',
      description:
      'Every expense recorded for a term, with a downloadable PDF '
          'summary.',
      icon: Icons.receipt_long_rounded,
      roles: _accountantPrincipal,
    ),
  ];

  static List<ReportDefinition> reportsFor(AppRole role) =>
      all.where((r) => r.availableFor(role)).toList();

  static ReportDefinition? findById(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }
}