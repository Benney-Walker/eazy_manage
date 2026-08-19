import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notification/notifications.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// Open the notification panel and mark everything read (the badge clears).
void openNotificationPanel(BuildContext context, WidgetRef ref) {
  ref.read(notificationsProvider.notifier).markAllRead();
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.08),
    builder: (_) => const _NotificationPanel(),
  );
}

String _relativeTime(DateTime at) {
  final d = DateTime.now().difference(at);
  if (d.inSeconds < 45) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

class _NotificationPanel extends ConsumerWidget {
  const _NotificationPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final items = ref.watch(notificationsProvider);

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 64, right: 16),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 380,
            constraints: const BoxConstraints(maxHeight: 480),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.all(AppRadius.lgR),
              border: Border.all(color: c.border, width: AppStroke.hairline),
              boxShadow: [
                BoxShadow(
                    color: c.shadow,
                    blurRadius: 28,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(context, ref, c, items.isNotEmpty),
                Divider(height: 1, color: c.divider),
                Flexible(
                  child: items.isEmpty
                      ? _empty(c)
                      : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: c.divider),
                    itemBuilder: (_, i) => _row(c, items[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(
      BuildContext context, WidgetRef ref, AppColors c, bool hasItems) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      child: Row(
        children: [
          Text('Notifications',
              style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
          const Spacer(),
          if (hasItems)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).clearAll(),
              child: Text('Clear all',
                  style: AppTypography.button.copyWith(color: c.textSecondary)),
            ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: c.textSecondary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _empty(AppColors c) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.notifications_none_rounded, size: 28, color: c.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text('Nothing yet',
              style: AppTypography.body.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Text('Messages shown to you will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }

  Widget _row(AppColors c, AppNotification n) {
    final dot = n.isError ? c.danger : c.success;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.message,
                    style: AppTypography.body.copyWith(color: c.textPrimary)),
                const SizedBox(height: 2),
                Text('${n.action}  ·  ${_relativeTime(n.at)}',
                    style:
                    AppTypography.caption.copyWith(color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
