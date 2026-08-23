import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/notification/notifications.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../academics/data/academics_providers.dart';
import '../../academics/ui/academics_widgets.dart';
import '../../students/data/student_providers.dart';
import '../data/finance_models.dart';
import '../data/finance_providers.dart';

String _cedis(double v) => '₵${NumberFormat('#,##0.00').format(v)}';

class FeesSetupTab extends ConsumerWidget {
  const FeesSetupTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final semesterId = ref.watch(financeSemesterIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _toolbar(context, ref, c, semesterId),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: semesterId == null
              ? const AcademicsEmpty(
            icon: Icons.filter_alt_rounded,
            title: 'Choose a term',
            subtitle: 'Pick a term above to set up its class fees.',
          )
              : _body(context, ref, c),
        ),
      ],
    );
  }

  Widget _toolbar(
      BuildContext context, WidgetRef ref, AppColors c, String? semesterId) {
    final termsAsync = ref.watch(semestersProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 240,
          child: AcademicsDropdown<String>(
            label: 'Term',
            hint: 'Select term',
            value: semesterId,
            items: termsAsync.maybeWhen(
              orElse: () => const [],
              data: (terms) => [
                for (final s in terms)
                  DropdownMenuItem(
                    value: s.semesterId,
                    child: Text('${s.semesterName}  (${s.academicYear})'),
                  ),
              ],
            ),
            onChanged: (v) =>
            ref.read(financeSemesterIdProvider.notifier).state = v,
          ),
        ),
        const Spacer(),
        AppButton.secondary(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(feesDetailsProvider),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton.primary(
          label: 'Add fee',
          icon: Icons.add_rounded,
          onPressed: semesterId == null
              ? null
              : () => _openAdd(context, ref, semesterId),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, AppColors c) {
    final async = ref.watch(feesDetailsProvider);
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.brand)),
      error: (e, _) => AcademicsEmpty(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load fees',
        subtitle: e.toString().replaceFirst('ApiException: ', ''),
        action: AppButton.secondary(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(feesDetailsProvider),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const AcademicsEmpty(
            icon: Icons.payments_rounded,
            title: 'No fees set for this term',
            subtitle: 'Use "Add fee" above to set fees for one or more classes.',
          );
        }
        return AcademicsListCard(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final f = rows[i];
            return AcademicsRow(
              leadingIcon: Icons.payments_rounded,
              title: f.levelName.isEmpty ? 'Class' : f.levelName,
              subtitle: _cedis(f.amount),
              trailing:
              Icon(Icons.edit_rounded, size: 18, color: c.textSecondary),
              onTap: () => _openEdit(context, ref, f),
            );
          },
        );
      },
    );
  }

  void _openAdd(BuildContext context, WidgetRef ref, String semesterId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeeAdd(semesterId: semesterId),
    );
  }

  void _openEdit(BuildContext context, WidgetRef ref, FeesDetails fee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeeEdit(fee: fee),
    );
  }
}

/// Set one amount across one or more classes.
class _FeeAdd extends ConsumerStatefulWidget {
  final String semesterId;
  const _FeeAdd({required this.semesterId});

  @override
  ConsumerState<_FeeAdd> createState() => _FeeAddState();
}

class _FeeAddState extends ConsumerState<_FeeAdd> {
  final _amount = TextEditingController();
  final Set<String> _levelIds = {};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount greater than zero.');
      return;
    }
    if (_levelIds.isEmpty) {
      setState(() => _error = 'Select at least one class.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(financeRepositoryProvider).addFees(NewFeesRequest(
        semesterId: widget.semesterId,
        levelIds: _levelIds.toList(),
        feesAmount: amount,
      ));
      if (!mounted) return;
      ref.invalidate(feesDetailsProvider);
      notify(ref, context, action: 'Add fee', message: 'Fee set.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      notify(ref, context,
          action: 'Add fee',
          message: e.message,
          isError: true,
          showSnackbar: false);
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      const msg = 'Could not save. Try again.';
      notify(ref, context,
          action: 'Add fee', message: msg, isError: true, showSnackbar: false);
      setState(() {
        _saving = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final classesAsync = ref.watch(classesProvider);

    return AcademicsSheet(
      title: 'Add fee',
      icon: Icons.payments_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Amount (₵)',
            hint: 'e.g. 500.00',
            controller: _amount,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Classes',
              style: AppTypography.label.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          classesAsync.when(
            loading: () => Text('Loading classes…',
                style: AppTypography.caption.copyWith(color: c.textMuted)),
            error: (_, __) => Text('Classes unavailable',
                style: AppTypography.caption.copyWith(color: c.danger)),
            data: (classes) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final cl in classes)
                  FilterChip(
                    label: Text(cl.levelName),
                    selected: _levelIds.contains(cl.levelId),
                    onSelected: _saving
                        ? null
                        : (on) => setState(() {
                      if (on) {
                        _levelIds.add(cl.levelId);
                      } else {
                        _levelIds.remove(cl.levelId);
                      }
                    }),
                  ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AcademicsInlineError(message: _error!),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(children: [
            const Spacer(),
            AppButton.ghost(
              label: 'Cancel',
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton.primary(
              label: 'Add fee',
              busy: _saving,
              onPressed: _save,
            ),
          ]),
        ],
      ),
    );
  }
}

/// Update the amount of an existing class fee.
class _FeeEdit extends ConsumerStatefulWidget {
  final FeesDetails fee;
  const _FeeEdit({required this.fee});

  @override
  ConsumerState<_FeeEdit> createState() => _FeeEditState();
}

class _FeeEditState extends ConsumerState<_FeeEdit> {
  late final _amount =
  TextEditingController(text: widget.fee.amount.toString());
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount greater than zero.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(financeRepositoryProvider).updateFees(widget.fee, amount);
      if (!mounted) return;
      ref.invalidate(feesDetailsProvider);
      notify(ref, context, action: 'Update fee', message: 'Fee updated.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      notify(ref, context,
          action: 'Update fee',
          message: e.message,
          isError: true,
          showSnackbar: false);
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      const msg = 'Could not save. Try again.';
      notify(ref, context,
          action: 'Update fee',
          message: msg,
          isError: true,
          showSnackbar: false);
      setState(() {
        _saving = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AcademicsSheet(
      title: 'Update fee',
      icon: Icons.payments_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.fee.levelName.isEmpty ? 'Class' : widget.fee.levelName,
              style: AppTypography.caption.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Amount (₵)',
            hint: 'e.g. 500.00',
            controller: _amount,
            keyboardType: TextInputType.number,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AcademicsInlineError(message: _error!),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(children: [
            const Spacer(),
            AppButton.ghost(
              label: 'Cancel',
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton.primary(
              label: 'Update fee',
              busy: _saving,
              onPressed: _save,
            ),
          ]),
        ],
      ),
    );
  }
}