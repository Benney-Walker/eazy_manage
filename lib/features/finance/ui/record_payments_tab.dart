import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/connectivity/connectivity_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../academics/ui/academics_widgets.dart';
import '../../students/data/student_models.dart';
import '../../students/data/student_providers.dart';
import '../data/finance_models.dart';
import '../data/finance_providers.dart';

/// Record Payments: pick a student in the current class + semester, see their
/// payment history, and record a new payment or edit an existing one.
class RecordPaymentsTab extends ConsumerWidget {
  const RecordPaymentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ready = ref.watch(financeContextReadyProvider);

    if (!ready) {
      return const AcademicsEmpty(
        icon: Icons.filter_alt_rounded,
        title: 'Choose a class and term',
        subtitle: 'Pick both above, then choose a student to record payments.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _studentPicker(context, ref, c),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: _body(context, ref, c)),
      ],
    );
  }

  Widget _studentPicker(BuildContext context, WidgetRef ref, AppColors c) {
    final levelId = ref.watch(financeLevelIdProvider);
    final selectedStudent = ref.watch(financeStudentIdProvider);
    final rosterAsync = ref.watch(_financeRosterProvider(levelId));

    return Row(
      children: [
        SizedBox(
          width: 320,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
              border:
              Border.all(color: c.borderStrong, width: AppStroke.hairline),
            ),
            child: DropdownButtonHideUnderline(
              child: rosterAsync.when(
                loading: () => _hint(c, 'Loading students…'),
                error: (_, __) => _hint(c, 'Students unavailable'),
                data: (students) {
                  final valid = students.any((s) => s.studentId == selectedStudent)
                      ? selectedStudent
                      : null;
                  return DropdownButton<String>(
                    value: valid,
                    isExpanded: true,
                    hint: Text('Select student',
                        style: AppTypography.body
                            .copyWith(color: c.inputPlaceholder)),
                    icon: Icon(Icons.expand_more_rounded,
                        color: c.textSecondary),
                    dropdownColor: c.surfaceElevated,
                    borderRadius: const BorderRadius.all(AppRadius.mdR),
                    items: [
                      for (final StudentSummary s in students)
                        DropdownMenuItem(
                          value: s.studentId,
                          child: Text(s.studentName,
                              style: AppTypography.body
                                  .copyWith(color: c.textPrimary)),
                        ),
                    ],
                    onChanged: (v) =>
                    ref.read(financeStudentIdProvider.notifier).state = v,
                  );
                },
              ),
            ),
          ),
        ),
        const Spacer(),
        AppButton.primary(
          label: 'Record payment',
          icon: Icons.add_rounded,
          onPressed: selectedStudent == null
              ? null
              : () => _openEditor(context, ref, null),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, AppColors c) {
    final studentId = ref.watch(financeStudentIdProvider);
    if (studentId == null) {
      return const AcademicsEmpty(
        icon: Icons.person_search_rounded,
        title: 'Choose a student',
        subtitle: 'Select a student above to see and record their payments.',
      );
    }

    final async = ref.watch(paymentRecordsProvider);
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.brand)),
      error: (e, _) => AcademicsEmpty(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load payments',
        subtitle: e.toString().replaceFirst('ApiException: ', ''),
        action: AppButton.secondary(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(paymentRecordsProvider),
        ),
      ),
      data: (records) {
        if (records.isEmpty) {
          return const AcademicsEmpty(
            icon: Icons.receipt_long_rounded,
            title: 'No payments yet',
            subtitle: 'Record this student\'s first payment for the term.',
          );
        }
        final total = records.fold<double>(
          0,
              (sum, r) => sum + (double.tryParse(r.amount) ?? 0),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  bottom: AppSpacing.sm, left: AppSpacing.xs),
              child: Text(
                '${records.length} payment${records.length == 1 ? '' : 's'}'
                    '  ·  ₵${_fmt(total)} total',
                style: AppTypography.caption.copyWith(color: c.textSecondary),
              ),
            ),
            Expanded(
              child: AcademicsListCard(
                itemCount: records.length,
                itemBuilder: (context, i) =>
                    _paymentRow(context, ref, c, records[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _paymentRow(
      BuildContext context, WidgetRef ref, AppColors c, PaymentRecord r) {
    final sub = [
      if (r.dateOfPayment.isNotEmpty) r.dateOfPayment,
      if (r.payerName.isNotEmpty) 'by ${r.payerName}',
    ].join('  ·  ');
    return AcademicsRow(
      leadingIcon: Icons.receipt_rounded,
      title: '₵${r.amount}',
      subtitle: sub.isEmpty ? null : sub,
      onTap: () => _openEditor(context, ref, r),
    );
  }

  Widget _hint(AppColors c, String text) => Align(
    alignment: Alignment.centerLeft,
    child:
    Text(text, style: AppTypography.body.copyWith(color: c.textMuted)),
  );

  void _openEditor(BuildContext context, WidgetRef ref, PaymentRecord? record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentEditor(existing: record),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

/// Roster for a finance class levelId, backed by the students repository.
final _financeRosterProvider = FutureProvider.autoDispose
    .family<List<StudentSummary>, String?>((ref, levelId) async {
  if (levelId == null) return const [];
  return ref.watch(studentRepositoryProvider).loadStudents(levelId);
});

/// Add (existing == null) a payment, or edit an existing one.
class _PaymentEditor extends ConsumerStatefulWidget {
  final PaymentRecord? existing;
  const _PaymentEditor({required this.existing});

  @override
  ConsumerState<_PaymentEditor> createState() => _PaymentEditorState();
}

class _PaymentEditorState extends ConsumerState<_PaymentEditor> {
  final _amount = TextEditingController();
  final _payerName = TextEditingController();
  final _payerContact = TextEditingController();
  DateTime? _date;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amount.text = e.amount;
      _payerName.text = e.payerName;
      _payerContact.text = e.payerContact;
      _date = _parse(e.dateOfPayment);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _payerName.dispose();
    _payerContact.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _amount.text.trim();
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      setState(() => _error = 'Enter a valid amount greater than zero.');
      return;
    }
    if (_payerName.text.trim().isEmpty) {
      setState(() => _error = 'Payer name is required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(financeRepositoryProvider);
    try {
      if (_isEdit) {
        final updated = widget.existing!.copyWith(
          amount: raw,
          payerName: _payerName.text.trim(),
          payerContact: _payerContact.text.trim(),
          dateOfPayment: _date == null
              ? widget.existing!.dateOfPayment
              : _iso(_date!),
        );
        await repo.updatePayment(updated);
      } else {
        await repo.addPayment(NewPaymentRequest(
          studentId: ref.read(financeStudentIdProvider) ?? '',
          levelId: ref.read(financeLevelIdProvider) ?? '',
          semesterId: ref.read(financeSemesterIdProvider) ?? '',
          amountPaid: raw,
          payerName: _payerName.text.trim(),
          payerPhone: _payerContact.text.trim(),
        ));
      }
      if (!mounted) return;
      ref.invalidate(paymentRecordsProvider);
      Navigator.of(context).pop();
      final online = ref.read(isOnlineProvider);
      final verb = _isEdit ? 'updated' : 'recorded';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(online
              ? 'Payment $verb.'
              : 'Payment $verb — will sync when back online.'),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Could not save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AcademicsSheet(
      title: _isEdit ? 'Edit payment' : 'Record payment',
      icon: Icons.receipt_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: AppTextField(
                label: 'Amount (₵)',
                hint: 'e.g. 250',
                controller: _amount,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AcademicsDateField(
                label: 'Date of payment',
                value: _date,
                onPick: (d) => setState(() => _date = d),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: AppTextField(
                label: 'Payer name',
                hint: 'Full name',
                controller: _payerName,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppTextField(
                label: 'Payer contact',
                hint: 'e.g. 024 123 4567',
                controller: _payerContact,
              ),
            ),
          ]),
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
              label: _isEdit ? 'Save changes' : 'Record payment',
              busy: _saving,
              onPressed: _save,
            ),
          ]),
        ],
      ),
    );
  }

  DateTime? _parse(String s) {
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s.length >= 10 ? s.substring(0, 10) : s);
    } catch (_) {
      return null;
    }
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}