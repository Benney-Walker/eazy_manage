import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import 'finance_context_bar.dart';
import 'fees_setup_tab.dart';
import 'record_payments_tab.dart';

/// One Finance tab: label + view.
class _FinanceTab {
  final String label;
  final Widget view;
  const _FinanceTab(this.label, this.view);
}

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  static const List<_FinanceTab> _tabsSpec = [
    _FinanceTab('Fees Setup', FeesSetupTab()),
    _FinanceTab('Record Payments', RecordPaymentsTab()),
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
        // Shared context bar under the tabs, above the tab content.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            0,
          ),
          child: const FinanceContextBar(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: TabBarView(
              controller: _controller,
              children: [
                for (final t in _tabsSpec) t.view,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
