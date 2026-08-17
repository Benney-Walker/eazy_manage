import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import 'semesters_tab.dart';
import 'subjects_tab.dart';
import 'grading_tab.dart';
import 'classes_tab.dart';
import 'holidays_tab.dart';

class _AcademicTab {
  final String label;
  final Widget view;
  const _AcademicTab(this.label, this.view);
}

class AcademicSetupScreen extends StatefulWidget {
  const AcademicSetupScreen({super.key});

  @override
  State<AcademicSetupScreen> createState() => _AcademicSetupScreenState();
}

class _AcademicSetupScreenState extends State<AcademicSetupScreen>
    with SingleTickerProviderStateMixin {
  static const List<_AcademicTab> _tabsSpec = [
    _AcademicTab('Classes', ClassesTab()),
    _AcademicTab('Terms', SemestersTab()),
    _AcademicTab('Subjects', SubjectsTab()),
    _AcademicTab('Grading', GradingTab()),
    _AcademicTab('Holidays', HolidaysTab()),
  ];

  late final TabController _controller =
  TabController(length: _tabsSpec.length, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: c.border, width: AppStroke.hairline),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _controller,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final t in _tabsSpec) Tab(text: t.label),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: [
              for (final t in _tabsSpec) t.view,
            ],
          ),
        ),
      ],
    );
  }
}