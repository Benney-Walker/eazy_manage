import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';


class AcademicsEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const AcademicsEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.bgAlt,
              borderRadius: const BorderRadius.all(AppRadius.lgR),
            ),
            child: Icon(icon, size: 30, color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: c.textSecondary),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

/// A bordered card wrapping a separated list.
class AcademicsListCard extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const AcademicsListCard({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: c.border, width: AppStroke.hairline),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: ListView.separated(
          itemCount: itemCount,
          separatorBuilder: (_, __) => Divider(height: 1, color: c.divider),
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }
}

/// A tappable list row with a leading icon plate, title/subtitle, and optional
/// trailing widget.
class AcademicsRow extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const AcademicsRow({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: c.hover,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.brand50,
                  borderRadius: const BorderRadius.all(AppRadius.mdR),
                ),
                child: Icon(leadingIcon, size: 18, color: c.brand),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                      AppTypography.bodyStrong.copyWith(color: c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTypography.caption
                            .copyWith(color: c.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ],
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bottom-sheet shell with a header (icon + title) and a body.
class AcademicsSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const AcademicsSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.all(AppRadius.xlR),
              border: Border.all(color: c.border, width: AppStroke.hairline),
              boxShadow: [
                BoxShadow(
                    color: c.shadow, blurRadius: 32, offset: const Offset(0, 12)),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.brand50,
                        borderRadius: const BorderRadius.all(AppRadius.lgR),
                      ),
                      child: Icon(icon, color: c.brand, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.title.copyWith(color: c.textPrimary),
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.xl),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labeled date field that opens the native date picker.
class AcademicsDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  const AcademicsDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.label.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.xs + 2),
        InkWell(
          borderRadius: const BorderRadius.all(AppRadius.mdR),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 5),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: c.inputBg,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
              border: Border.all(color: c.inputBorder, width: AppStroke.hairline),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: c.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  value == null ? 'Select date' : _iso(value!),
                  style: AppTypography.body.copyWith(
                    color: value == null ? c.inputPlaceholder : c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// A labeled dropdown consistent with the input styling.
class AcademicsDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;

  const AcademicsDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Select',
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.label.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.xs + 2),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: c.inputBg,
            borderRadius: const BorderRadius.all(AppRadius.mdR),
            border: Border.all(color: c.inputBorder, width: AppStroke.hairline),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(hint,
                  style: AppTypography.body.copyWith(color: c.inputPlaceholder)),
              icon: Icon(Icons.expand_more_rounded, color: c.textSecondary),
              dropdownColor: c.surfaceElevated,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// A red inline error banner.
class AcademicsInlineError extends StatelessWidget {
  final String message;
  const AcademicsInlineError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
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
            child:
            Text(message, style: AppTypography.caption.copyWith(color: c.danger)),
          ),
        ],
      ),
    );
  }
}
