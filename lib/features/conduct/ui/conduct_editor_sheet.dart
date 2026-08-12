import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../academics/ui/academics_widgets.dart';
import '../data/conduct_models.dart';
import '../data/conduct_providers.dart';

/// The rubric editor for one student: six conduct categories, each rated on the
/// five-point scale, plus a conduct remark and any peculiar issue. Saving is
/// local-first — it returns instantly and syncs in the background.
class ConductEditorSheet extends ConsumerStatefulWidget {
  final StudentConductRecord record;
  const ConductEditorSheet({super.key, required this.record});

  @override
  ConsumerState<ConductEditorSheet> createState() => _ConductEditorSheetState();
}

class _ConductEditorSheetState extends ConsumerState<ConductEditorSheet> {
  late StudentConductRecord _draft = widget.record;
  late final TextEditingController _remark =
      TextEditingController(text: widget.record.conductRemark);
  late final TextEditingController _peculiar =
      TextEditingController(text: widget.record.peculiarIssue);

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _remark.dispose();
    _peculiar.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final record = _draft.copyWith(
      conductRemark: _remark.text.trim(),
      peculiarIssue: _peculiar.text.trim(),
    );

    try {
      await ref.read(conductRepositoryProvider).saveRecord(record);
      if (!mounted) return;
      // Local-first: the write is durably queued (and pushing now if online).
      ref.invalidate(conductRecordsProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conduct saved.')),
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
    final c = AppColors.of(context);

    return AcademicsSheet(
      title: widget.record.studentName.isEmpty
          ? 'Conduct'
          : 'Conduct — ${widget.record.studentName}',
      icon: Icons.flag_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rubric grid.
          _RubricGrid(
            draft: _draft,
            onRate: (key, value) =>
                setState(() => _draft = _draft.withRating(key, value)),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Conduct remark',
              style: AppTypography.label.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: '',
            hint: 'Overall remark on the student\'s conduct',
            controller: _remark,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Peculiar issue',
              style: AppTypography.label.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: '',
            hint: 'Any specific issue to note (optional)',
            controller: _peculiar,
            maxLines: 2,
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
              label: 'Save conduct',
              busy: _saving,
              onPressed: _save,
            ),
          ]),
        ],
      ),
    );
  }
}

/// The six-category × five-rating grid. Each row is a category; each cell a
/// selectable rating chip.
class _RubricGrid extends StatelessWidget {
  final StudentConductRecord draft;
  final void Function(String key, String value) onRate;

  const _RubricGrid({required this.draft, required this.onRate});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cat in ConductCategory.all) ...[
          Text(cat.label,
              style: AppTypography.bodyStrong.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final rating in ConductRatings.all)
                _ratingChip(
                  c,
                  label: ConductRatings.label(rating),
                  selected: draft.ratingFor(cat.key) == rating,
                  onTap: () => onRate(cat.key, rating),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }

  Widget _ratingChip(AppColors c,
      {required String label,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? c.brand : c.surfaceAlt,
          borderRadius: const BorderRadius.all(AppRadius.mdR),
          border: Border.all(
            color: selected ? c.brand : c.border,
            width: AppStroke.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? c.onBrand : c.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
