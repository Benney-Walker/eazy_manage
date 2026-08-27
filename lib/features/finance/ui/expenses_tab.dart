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
import '../data/finance_models.dart';
import '../data/finance_providers.dart';

String _cedis(double v) => '₵${NumberFormat('#,##0.00').format(v)}';

class ExpensesTab extends ConsumerWidget {
  const ExpensesTab({super.key});

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
            subtitle: 'Pick a term above to view and record its expenses.',
          )
              : _body(context, ref, c, ref.watch(expensesProvider)),
        ),
      ],
    );
  }

  Widget _toolbar(
      BuildContext context, WidgetRef ref, AppColors c, String? semesterId) {
    final termsAsync = ref.watch(semestersProvider);
    final total = ref.watch(totalExpensesProvider).maybeWhen(
      data: (v) => _cedis(v),
      orElse: () => '—',
    );
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
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total this term',
                  style: AppTypography.label.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              Text(total,
                  style:
                  AppTypography.subtitle.copyWith(color: c.textPrimary)),
            ],
          ),
        ),
        AppButton.secondary(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: () {
            ref.invalidate(expensesProvider);
            ref.invalidate(totalExpensesProvider);
          },
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton.primary(
          label: 'Add expense',
          icon: Icons.add_rounded,
          onPressed: semesterId == null
              ? null
              : () => _openEditor(context, ref, null),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, AppColors c,
      AsyncValue<List<ExpensesRecord>> async) {
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.brand)),
      error: (e, _) => AcademicsEmpty(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load expenses',
        subtitle: e.toString().replaceFirst('ApiException: ', ''),
        action: AppButton.secondary(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(expensesProvider),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const AcademicsEmpty(
            icon: Icons.receipt_long_rounded,
            title: 'No expenses recorded this term',
            subtitle: 'Use "Add expense" above to record one.',
          );
        }
        return AcademicsListCard(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final e = rows[i];
            final extra =
            e.extraInfo.isEmpty ? '' : '  ·  ${e.extraInfo}';
            final date = e.expenseDate.isEmpty ? '' : '  ·  ${e.expenseDate}';
            return AcademicsRow(
              leadingIcon: Icons.receipt_long_rounded,
              title: e.description,
              subtitle: '${_cedis(e.amountSpent)}$extra$date',
              trailing: Icon(Icons.edit_rounded,
                  size: 18, color: c.textSecondary),
              onTap: () => _openEditor(context, ref, e),
            );
          },
        );
      },
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, ExpensesRecord? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseEditor(existing: existing),
    );
  }
}

class _ExpenseEditor extends ConsumerStatefulWidget {
  final ExpensesRecord? existing;
  const _ExpenseEditor({required this.existing});

  @override
  ConsumerState<_ExpenseEditor> createState() => _ExpenseEditorState();
}

class _ExpenseEditorState extends ConsumerState<_ExpenseEditor> {
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _extraInfo = TextEditingController();
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _description.text = e.description;
      _amount.text = e.amountSpent.toString();
      // "no information" is the backend's placeholder; show it blank so the
      // user can leave it empty again.
      _extraInfo.text =
      e.extraInfo.trim().toLowerCase() == 'no information' ? '' : e.extraInfo;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _extraInfo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final description = _description.text.trim();
    final amount = double.tryParse(_amount.text.trim());
    if (description.isEmpty) {
      setState(() => _error = 'Enter a description.');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount greater than zero.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(financeRepositoryProvider);
    final semesterId = ref.read(financeSemesterIdProvider) ?? '';

    try {
      if (_isEdit) {
        await repo.updateExpense(UpdateExpensesRequest(
          expensesId: widget.existing!.expensesId,
          description: description,
          amountSpent: amount,
          extraInfo: _extraInfo.text,
          semesterId: semesterId,
        ));
      } else {
        await repo.addExpense(NewExpensesRequest(
          description: description,
          extraInfo: _extraInfo.text,
          amountSpent: amount,
          semesterId: semesterId,
        ));
      }
      if (!mounted) return;
      ref.invalidate(expensesProvider);
      ref.invalidate(totalExpensesProvider);
      notify(ref, context,
          action: _isEdit ? 'Update expense' : 'Add expense',
          message: _isEdit ? 'Expense updated.' : 'Expense added.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      notify(ref, context,
          action: _isEdit ? 'Update expense' : 'Add expense',
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
          action: _isEdit ? 'Update expense' : 'Add expense',
          message: msg,
          isError: true,
          showSnackbar: false);
      setState(() {
        _saving = false;
        _error = msg;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
            'This will permanently remove "${widget.existing!.description}". '
                'This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete',
                style: TextStyle(color: AppColors.of(dialogContext).danger)),
          ),
        ],
      ),
    );
    if (ok == true) await _delete();
  }

  Future<void> _delete() async {
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref
          .read(financeRepositoryProvider)
          .deleteExpense(widget.existing!.expensesId);
      if (!mounted) return;
      ref.invalidate(expensesProvider);
      ref.invalidate(totalExpensesProvider);
      notify(ref, context, action: 'Delete expense', message: 'Expense deleted.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      notify(ref, context,
          action: 'Delete expense',
          message: e.message,
          isError: true,
          showSnackbar: false);
      setState(() {
        _deleting = false;
        _error = e.message;
      });
    } catch (_) {
      const msg = 'Could not delete. Try again.';
      notify(ref, context,
          action: 'Delete expense',
          message: msg,
          isError: true,
          showSnackbar: false);
      setState(() {
        _deleting = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AcademicsSheet(
      title: _isEdit ? 'Update expense' : 'Add expense',
      icon: Icons.receipt_long_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Description',
            hint: 'e.g. Printer toner',
            controller: _description,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Amount (₵)',
            hint: 'e.g. 120.50',
            controller: _amount,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Extra info (optional)',
            hint: 'Leave blank if none',
            controller: _extraInfo,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AcademicsInlineError(message: _error!),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(children: [
            if (_isEdit)
              AppButton.danger(
                label: 'Delete',
                busy: _deleting,
                onPressed: _saving ? null : _confirmDelete,
              ),
            const Spacer(),
            AppButton.ghost(
              label: 'Cancel',
              onPressed:
              (_saving || _deleting) ? null : () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton.primary(
              label: _isEdit ? 'Update expense' : 'Add expense',
              busy: _saving,
              onPressed: _deleting ? null : _save,
            ),
          ]),
        ],
      ),
    );
  }
}