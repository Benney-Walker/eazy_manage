import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../academics/ui/academics_widgets.dart';
import '../data/finance_models.dart';
import '../data/finance_providers.dart';


class FeesSetupTab extends ConsumerWidget {
  const FeesSetupTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ready = ref.watch(financeContextReadyProvider);

    if (!ready) {
      return const AcademicsEmpty(
        icon: Icons.filter_alt_rounded,
        title: 'Choose a class and semester',
        subtitle: 'Pick both above to view or set the fee for that term.',
      );
    }

    final async = ref.watch(feesDetailsProvider);

    // Toolbar (with the action button top-right) always shows once a context
    // is picked — mirroring the Record Payments layout. The button label and
    // whether it's enabled depend on the load state.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _toolbar(context, ref, c, async),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: _body(context, ref, c, async)),
      ],
    );
  }

  // ---- Toolbar: title + action button (top-right) -------------------------
  Widget _toolbar(BuildContext context, WidgetRef ref, AppColors c,
      AsyncValue<FeesDetails?> async) {
    // Resolve the current fee (if loaded) so the button reads Set vs Update.
    final fees = async.asData?.value;
    final loaded = async.hasValue;

    return Row(
      children: [
        Expanded(
          child: Text('Semester fee',
              style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
        ),
        AppButton.secondary(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(feesDetailsProvider),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton.primary(
          label: fees == null ? 'Set fee' : 'Update fee',
          icon: fees == null ? Icons.add_rounded : Icons.edit_rounded,
          // Enabled only once we know the current state, so we open the editor
          // in the right mode.
          onPressed: loaded ? () => _openEditor(context, ref, fees) : null,
        ),
      ],
    );
  }

  // ---- Body: the fee (or empty / error state) -----------------------------
  Widget _body(BuildContext context, WidgetRef ref, AppColors c,
      AsyncValue<FeesDetails?> async) {
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.brand)),
      error: (e, _) => AcademicsEmpty(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load the fee',
        subtitle: e.toString().replaceFirst('ApiException: ', ''),
        action: AppButton.secondary(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(feesDetailsProvider),
        ),
      ),
      data: (fees) {
        if (fees == null) {
          return const AcademicsEmpty(
            icon: Icons.account_balance_wallet_rounded,
            title: 'No fee set for this class this term',
            subtitle: 'Use "Set fee" above to configure the semester fee.',
          );
        }
        return _feeCard(context, c, fees);
      },
    );
  }

  Widget _feeCard(BuildContext context, AppColors c, FeesDetails fees) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.brand50,
                      borderRadius: const BorderRadius.all(AppRadius.lgR),
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded,
                        color: c.brand, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('Current fee for this class this term',
                        style: AppTypography.caption
                            .copyWith(color: c.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('₵',
                      style: AppTypography.title.copyWith(color: c.brand)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(fees.amount,
                      style:
                      AppTypography.metric.copyWith(color: c.textPrimary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, FeesDetails? fees) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeesEditor(existing: fees),
    );
  }
}

/// Set (existing == null) or update the semester fee.
class _FeesEditor extends ConsumerStatefulWidget {
  final FeesDetails? existing;
  const _FeesEditor({required this.existing});

  @override
  ConsumerState<_FeesEditor> createState() => _FeesEditorState();
}

class _FeesEditorState extends ConsumerState<_FeesEditor> {
  final _amount = TextEditingController();
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _amount.text = widget.existing!.amount;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _amount.text.trim();
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      setState(() => _error = 'Enter a valid amount greater than zero.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(financeRepositoryProvider);
    final levelId = ref.read(financeLevelIdProvider);
    final semesterId = ref.read(financeSemesterIdProvider);

    try {
      if (_isEdit) {
        await repo.updateFees(widget.existing!, raw);
      } else {
        await repo.addFees(
          classId: levelId ?? '',
          semesterId: semesterId ?? '',
          feesAmount: raw,
        );
      }
      if (!mounted) return;
      ref.invalidate(feesDetailsProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Fee updated.' : 'Fee set.')),
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
      title: _isEdit ? 'Update fee' : 'Set fee',
      icon: Icons.account_balance_wallet_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Fee amount (₵)',
            hint: 'e.g. 500',
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
              label: _isEdit ? 'Update fee' : 'Set fee',
              busy: _saving,
              onPressed: _save,
            ),
          ]),
        ],
      ),
    );
  }
}