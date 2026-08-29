import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import 'sms_tab.dart';
import 'email_tab.dart';

/// One Broadcasts tab: label + view.
class _BroadcastTab {
  final String label;
  final Widget view;
  const _BroadcastTab(this.label, this.view);
}

class BroadcastsScreen extends StatefulWidget {
  const BroadcastsScreen({super.key});

  @override
  State<BroadcastsScreen> createState() => _BroadcastsScreenState();
}

class _BroadcastsScreenState extends State<BroadcastsScreen>
    with SingleTickerProviderStateMixin {
  static const List<_BroadcastTab> _tabsSpec = [
    _BroadcastTab('SMS', SmsTab()),
    _BroadcastTab('Email', EmailTab()),
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
