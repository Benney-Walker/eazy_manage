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
import '../../academics/ui/academics_widgets.dart';
import '../../students/data/student_providers.dart';
import '../data/finance_models.dart';
import '../data/finance_providers.dart';

String _cedis(double v) => '₵${NumberFormat('#,##0.00').format(v)}';

class SpecialFeesTab extends ConsumerWidget {
  const SpecialFeesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final type = ref.watch(specialTypeProvider);
    final async = ref.watch(specialFeesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _toolbar(context, ref, c, type),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: _body(context, ref, c, async)),
      ],
    );
  }

  Widget _toolbar(
      BuildContext context, WidgetRef ref, AppColors c, SpecialPaymentType type) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 220,
          child: AcademicsDropdown<SpecialPaymentType>(
            label: 'Payment type',
            value: type,
            items: [
              for (final t in SpecialPaymentType.values)
                DropdownMenuItem(value: t, child: Text(t.label)),
            ],
            onChanged: (v) {
              if (v != null) {
                ref.read(specialTypeProvider.notifier).state = v;
              }
            },
          ),
        ),
        const Spacer(),
        AppButton.secondary(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(specialFeesProvider),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton.primary(
          label: 'Add special fee',
          icon: Icons.add_rounded,
          onPressed: () => _openAdd(context, ref),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, AppColors c,
      AsyncValue<List<SpecialPaymentRecord>> async) {
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.brand)),
      error: (e, _) => AcademicsEmpty(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load special fees',
        subtitle: e.toString().replaceFirst('ApiException: ', ''),
        action: AppButton.secondary(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(specialFeesProvider),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const AcademicsEmpty(
            icon: Icons.request_quote_rounded,
            title: 'No special fees of this type',
            subtitle: 'Use "Add special fee" above to create one.',
          );
        }
        return AcademicsListCard(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final r = rows[i];
            final desc = r.description.isEmpty ? '' : '  ·  ${r.description}';
            return AcademicsRow(
              leadingIcon: Icons.request_quote_rounded,
              title: r.levelName.isEmpty ? 'All classes' : r.levelName,
              subtitle: '${_cedis(r.amount)}$desc',
              trailing: Icon(Icons.edit_rounded,
                  size: 18, color: c.textSecondary),
              onTap: () => _openEdit(context, ref, r),
            );
          },
        );
      },
    );
  }

  void _openAdd(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SpecialFeeAdd(initialType: ref.read(specialTypeProvider)),
    );
  }

  void _openEdit(BuildContext context, WidgetRef ref, SpecialPaymentRecord r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SpecialFeeEdit(record: r),
    );
  }
}

/// Create a new special fee against one or more classes.
class _SpecialFeeAdd extends ConsumerStatefulWidget {
  final SpecialPaymentType initialType;
  const _SpecialFeeAdd({required this.initialType});

  @override
  ConsumerState<_SpecialFeeAdd> createState() => _SpecialFeeAddState();
}

class _SpecialFeeAddState extends ConsumerState<_SpecialFeeAdd> {
  late SpecialPaymentType _type = widget.initialType;
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final Set<String> _levelIds = {};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    String description = _description.text.trim();
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount greater than zero.');
      return;
    }
    if (_levelIds.isEmpty) {
      setState(() => _error = 'Select at least one class.');
      return;
    }
    if (description.isEmpty) {
      description = 'no_description';
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(financeRepositoryProvider).addSpecialFee(
        NewSpecialPaymentRequest(
          paymentType: _type,
          amount: amount,
          levelList: _levelIds.toList(),
          description: description,
        ),
      );
      if (!mounted) return;
      // Show the type we just added so it appears in the list.
      ref.read(specialTypeProvider.notifier).state = _type;
      ref.invalidate(specialFeesProvider);
      notify(ref, context,
          action: 'Add special fee', message: 'Special fee added.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      notify(ref, context,
          action: 'Add special fee',
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
          action: 'Add special fee',
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
    final classesAsync = ref.watch(classesProvider);

    return AcademicsSheet(
      title: 'Add special fee',
      icon: Icons.request_quote_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AcademicsDropdown<SpecialPaymentType>(
            label: 'Payment type',
            value: _type,
            items: [
              for (final t in SpecialPaymentType.values)
                DropdownMenuItem(value: t, child: Text(t.label)),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Amount (₵)',
            hint: 'e.g. 50.00',
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
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Description',
            hint: 'Optional',
            controller: _description,
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
              label: 'Add special fee',
              busy: _saving,
              onPressed: _save,
            ),
          ]),
        ],
      ),
    );
  }
}

/// Update an existing special-fee row — amount and description only.
class _SpecialFeeEdit extends ConsumerStatefulWidget {
  final SpecialPaymentRecord record;
  const _SpecialFeeEdit({required this.record});

  @override
  ConsumerState<_SpecialFeeEdit> createState() => _SpecialFeeEditState();
}

class _SpecialFeeEditState extends ConsumerState<_SpecialFeeEdit> {
  late final _amount =
  TextEditingController(text: widget.record.amount.toString());
  late final _description =
  TextEditingController(text: widget.record.description);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    String description = _description.text.trim();
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount greater than zero.');
      return;
    }
    if (description.isEmpty) {
      description = 'no_description';
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(financeRepositoryProvider).updateSpecialFee(
        UpdateSpecialPaymentRequest(
          id: widget.record.id,
          amount: amount,
          description: description,
        ),
      );
      if (!mounted) return;
      ref.invalidate(specialFeesProvider);
      notify(ref, context,
          action: 'Update special fee', message: 'Special fee updated.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      notify(ref, context,
          action: 'Update special fee',
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
          action: 'Update special fee',
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
    final r = widget.record;
    return AcademicsSheet(
      title: 'Update special fee',
      icon: Icons.request_quote_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${SpecialPaymentType.fromBackend(r.type).label}'
                '${r.levelName.isEmpty ? '' : '  ·  ${r.levelName}'}',
            style: AppTypography.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Amount (₵)',
            hint: 'e.g. 50.00',
            controller: _amount,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Description',
            hint: 'Optional',
            controller: _description,
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
              label: 'Update special fee',
              busy: _saving,
              onPressed: _save,
            ),
          ]),
        ],
      ),
    );
  }
}
