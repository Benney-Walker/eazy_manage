import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import 'semesters_tab.dart';
import 'subjects_tab.dart';
import 'grading_tab.dart';
import 'classes_tab.dart';
import 'holidays_tab.dart';

/// The Academic Setup surface. Phase 6a covers three of the five JavaFX tabs:
/// Semesters, Subjects, Grading. (Classes + Holidays land in Phase 6b.)
class AcademicSetupScreen extends StatefulWidget {
  const AcademicSetupScreen({super.key});

  @override
  State<AcademicSetupScreen> createState() => _AcademicSetupScreenState();
}

class _AcademicSetupScreenState extends State<AcademicSetupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
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
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Classes'),
                Tab(text: 'Semesters'),
                Tab(text: 'Subjects'),
                Tab(text: 'Grading'),
                Tab(text: 'Holidays'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              ClassesTab(),
              SemestersTab(),
              SubjectsTab(),
              GradingTab(),
              HolidaysTab(),
            ],
          ),
        ),
      ],
    );
  }
}