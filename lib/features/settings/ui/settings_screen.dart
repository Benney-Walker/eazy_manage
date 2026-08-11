import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_providers.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/connectivity/sync_engine.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/session/session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

/// Settings: account details, active-role switching, appearance (theme), the
/// connectivity/sync panel, and about. Theme and connectivity controls used to
/// live in the top bar; they now live here (connectivity is auto-detected and
/// shown read-only, with a manual "Sync now").
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final session = ref.watch(sessionProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Settings',
                  style: AppTypography.display.copyWith(color: c.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text('Account, role, and app preferences.',
                  style: AppTypography.body.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.xl),

              _AccountSection(session: session),
              const SizedBox(height: AppSpacing.lg),
              const _AppearanceSection(),
              const SizedBox(height: AppSpacing.lg),
              const _ConnectivitySection(),
              const SizedBox(height: AppSpacing.lg),
              const _AboutSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled settings card.
class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _Section({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: AppTypography.caption.copyWith(color: c.textSecondary)),
          ],
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

/// A label / value row used across sections.
class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: AppTypography.body.copyWith(color: c.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: AppTypography.bodyStrong.copyWith(color: c.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ---- Account ---------------------------------------------------------------

class _AccountSection extends ConsumerWidget {
  final Session? session;
  const _AccountSection({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Section(
      title: 'Account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row('Signed in as', session?.fullName ?? '—'),
          _Row('Organisation', session?.organizationName ?? '—'),
          _Row('Staff ID', session?.staffId ?? '—'),
          const SizedBox(height: AppSpacing.lg),
          AppButton.danger(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            onPressed: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final c = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Sign out?',
            style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
        content: Text(
          'You\'ll need to sign in again to continue.',
          style: AppTypography.body.copyWith(color: c.textSecondary),
        ),
        actions: [
          AppButton.ghost(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton.danger(
            label: 'Sign out',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}

// ---- Appearance (theme) ----------------------------------------------------

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final mode = ref.watch(themeModeProvider);

    Widget option(String label, IconData icon, ThemeMode value) {
      final selected = mode == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => ref.read(themeModeProvider.notifier).set(value),
          child: Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md, horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? c.brand50 : c.surfaceAlt,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
              border: Border.all(
                color: selected ? c.brand : c.border,
                width: AppStroke.hairline,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18, color: selected ? c.brand : c.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Text(label,
                    style: AppTypography.body.copyWith(
                      color: selected ? c.brand : c.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    )),
              ],
            ),
          ),
        ),
      );
    }

    return _Section(
      title: 'Appearance',
      subtitle: 'Choose how EazyManage looks.',
      child: Row(
        children: [
          option('Light', Icons.light_mode_rounded, ThemeMode.light),
          option('Dark', Icons.dark_mode_rounded, ThemeMode.dark),
          option('System', Icons.brightness_auto_rounded, ThemeMode.system),
        ],
      ),
    );
  }
}

// ---- Connectivity + Sync ---------------------------------------------------

class _ConnectivitySection extends ConsumerWidget {
  const _ConnectivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final status = ref.watch(networkStatusProvider);
    final syncAsync = ref.watch(syncStateProvider);
    final sync = syncAsync.asData?.value ?? const SyncState.initial();

    final (Color dot, String label) = switch (status) {
      NetworkStatus.online => (c.success, 'Working online'),
      NetworkStatus.offline => (c.warning, 'Working offline'),
      NetworkStatus.checking => (c.textMuted, 'Checking connection…'),
    };

    final syncing = sync.phase == SyncPhase.syncing;

    return _Section(
      title: 'Connectivity & sync',
      subtitle:
      'Connection is detected automatically. When it returns, queued changes '
          'sync to the server on their own — or sync them now.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status label (read-only — no manual toggle).
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(label,
                  style:
                  AppTypography.bodyStrong.copyWith(color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Pending + last sync.
          _Row('Pending changes', sync.pending.toString()),
          _Row(
            'Last synced',
            sync.lastSyncedAt == null ? 'Never' : _ago(sync.lastSyncedAt!),
          ),
          if (sync.phase == SyncPhase.error && sync.lastError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: c.dangerSubtle,
                borderRadius: const BorderRadius.all(AppRadius.mdR),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded, size: 16, color: c.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Last sync failed: ${sync.lastError}',
                        style:
                        AppTypography.caption.copyWith(color: c.danger)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              AppButton.primary(
                label: syncing ? 'Syncing…' : 'Sync now',
                icon: Icons.sync_rounded,
                busy: syncing,
                onPressed: syncing
                    ? null
                    : () async {
                  // Re-check the connection, then drain.
                  await ref
                      .read(networkStatusProvider.notifier)
                      .refresh();
                  await ref.read(syncEngineProvider).drainNow();
                },
              ),
              const SizedBox(width: AppSpacing.md),
              if (sync.pending == 0 && !syncing)
                Text('Everything is up to date.',
                    style:
                    AppTypography.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }
}

// ---- About -----------------------------------------------------------------

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return const _Section(
      title: 'About',
      child: Column(
        children: [
          _Row('Version', AppInfo.version),
          _Row('Developed by', AppInfo.developer),
        ],
      ),
    );
  }
}