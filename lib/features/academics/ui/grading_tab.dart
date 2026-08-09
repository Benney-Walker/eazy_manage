import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/academics_models.dart';
import '../data/academics_providers.dart';
import 'academics_widgets.dart';

/// Grading criteria: the score bands that map a mark to a letter grade and
/// descriptor. Add or edit bands; both go through the same upsert endpoint.
class GradingTab extends ConsumerWidget {
  const GradingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final async = ref.watch(gradingCriteriaProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Grading criteria',
                  style: AppTypography.subtitle.copyWith(color: c.textPrimary),
                ),
              ),
              AppButton.secondary(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                onPressed: () => ref.invalidate(gradingCriteriaProvider),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.primary(
                label: 'Add band',
                icon: Icons.add_rounded,
                onPressed: () => _openEditor(context, ref, null, const []),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Score ranges that determine each letter grade on report cards.',
            style: AppTypography.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: async.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: c.brand)),
              error: (e, _) => AcademicsEmpty(
                icon: Icons.cloud_off_rounded,
                title: 'Couldn\'t load grading criteria',
                subtitle: e.toString().replaceFirst('ApiException: ', ''),
                action: AppButton.secondary(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: () => ref.invalidate(gradingCriteriaProvider),
                ),
              ),
              data: (bands) {
                if (bands.isEmpty) {
                  return const AcademicsEmpty(
                    icon: Icons.grading_rounded,
                    title: 'No grading criteria yet',
                    subtitle:
                        'Add score bands (e.g. 80–100 = A) so results can be graded.',
                  );
                }
                return AcademicsListCard(
                  itemCount: bands.length,
                  itemBuilder: (context, i) =>
                      _row(context, ref, c, bands[i], bands),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, AppColors c,
      GradingCriteria band, List<GradingCriteria> all) {
    return AcademicsRow(
      leadingIcon: Icons.grading_rounded,
      title: '${_num(band.lowerRange)} – ${_num(band.upperRange)}',
      subtitle: band.gradeDescription.isEmpty ? null : band.gradeDescription,
      trailing: AppBadge(
        label: band.grade.isEmpty ? '—' : band.grade,
        intent: BadgeIntent.brand,
      ),
      onTap: () => _openEditor(context, ref, band, all),
    );
  }

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void _openEditor(BuildContext context, WidgetRef ref, GradingCriteria? band,
      List<GradingCriteria> all) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GradingEditor(existing: band, all: all),
    );
  }
}

/// Add (existing == null) or edit a grading band.
class _GradingEditor extends ConsumerStatefulWidget {
  final GradingCriteria? existing;
  final List<GradingCriteria> all;

  const _GradingEditor({required this.existing, required this.all});

  @override
  ConsumerState<_GradingEditor> createState() => _GradingEditorState();
}

class _GradingEditorState extends ConsumerState<_GradingEditor> {
  final _lower = TextEditingController();
  final _upper = TextEditingController();
  final _grade = TextEditingController();
  final _description = TextEditingController();

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _lower.text = GradingTab._num(e.lowerRange);
      _upper.text = GradingTab._num(e.upperRange);
      _grade.text = e.grade;
      _description.text = e.gradeDescription;
    }
  }

  @override
  void dispose() {
    _lower.dispose();
    _upper.dispose();
    _grade.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _validate(double? lower, double? upper) {
    if (lower == null) return 'Enter a valid lower score.';
    if (upper == null) return 'Enter a valid upper score.';
    if (lower < 0 || upper > 100) return 'Scores must be between 0 and 100.';
    if (upper <= lower) return 'Upper score must be greater than lower score.';
    if (_grade.text.trim().isEmpty) return 'Grade letter is required.';

    // Warn on overlap with another band (ignore the one being edited).
    for (final b in widget.all) {
      if (_isEdit && b.id == widget.existing!.id) continue;
      final overlaps = lower <= b.upperRange && upper >= b.lowerRange;
      if (overlaps) {
        return 'That range overlaps the existing '
            '${GradingTab._num(b.lowerRange)}–${GradingTab._num(b.upperRange)} '
            '(${b.grade}) band.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final lower = double.tryParse(_lower.text.trim());
    final upper = double.tryParse(_upper.text.trim());

    final err = _validate(lower, upper);
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = GradingCriteria(
      // The backend upserts by id; 0 signals a new band.
      id: widget.existing?.id ?? 0,
      lowerRange: lower!,
      upperRange: upper!,
      grade: _grade.text.trim(),
      gradeDescription: _description.text.trim(),
    );

    try {
      await ref.read(academicsRepositoryProvider).saveGradingCriteria(payload);
      if (!mounted) return;
      ref.invalidate(gradingCriteriaProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Band updated.' : 'Band added.')),
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
      title: _isEdit ? 'Edit grading band' : 'Add grading band',
      icon: Icons.grading_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: AppTextField(
                label: 'Lower score',
                hint: 'e.g. 80',
                controller: _lower,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppTextField(
                label: 'Upper score',
                hint: 'e.g. 100',
                controller: _upper,
                keyboardType: TextInputType.number,
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: AppTextField(
                label: 'Grade',
                hint: 'e.g. A',
                controller: _grade,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 2,
              child: AppTextField(
                label: 'Descriptor',
                hint: 'e.g. Excellent',
                controller: _description,
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
              label: _isEdit ? 'Save changes' : 'Add band',
              busy: _saving,
              onPressed: _save,
            ),
          ]),
        ],
      ),
    );
  }
}
