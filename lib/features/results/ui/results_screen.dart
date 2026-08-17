import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/connectivity/connectivity_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../academics/data/academics_providers.dart';
import '../../academics/ui/academics_widgets.dart';
import '../../students/data/student_providers.dart';
import '../data/results_models.dart';
import '../data/results_providers.dart';

/// Enter Scores: a spreadsheet-style grid. Pick class → subject → term,
/// then type the five component scores per student. Class score, exam score,
/// and total compute live. Saving is a local-first batch write.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  /// The working copy of the rows being edited.
  List<ScoreRow> _draft = [];

  /// Controllers per (studentId, columnKey) so typing preserves focus/caret.
  final Map<String, TextEditingController> _controllers = {};

  String? _loadedKey; // subjectId+semesterId currently loaded into _draft
  bool _saving = false;
  bool _dirty = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrl(String studentId, String key, String initial) {
    final id = '$studentId::$key';
    return _controllers.putIfAbsent(
        id, () => TextEditingController(text: initial));
  }

  void _syncDraft(SubjectScores data) {
    final key = '${data.subjectId}::${ref.read(resultsSemesterIdProvider)}';
    if (_loadedKey == key) return; // already loaded this context
    // New context: reset controllers + draft.
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _draft = List.of(data.rows);
    _loadedKey = key;
    _dirty = false;
  }

  void _onCell(int index, String key, String value) {
    setState(() {
      _draft[index] = _draft[index].withValue(key, value);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final subjectName = ref.read(subjectScoresProvider).asData?.value?.subjectName ??
        '';
    try {
      await ref.read(resultsRepositoryProvider).saveScores(
        subjectName: subjectName,
        rows: _draft,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _dirty = false;
      });
      final online = ref.read(isOnlineProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(online
              ? 'Scores saved.'
              : 'Scores saved — will sync when back online.'),
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
    final c = AppColors.of(context);

    // Sync the editable draft when a new score sheet loads (outside build's
    // widget construction — this callback fires on data change, not every
    // frame, and never disposes controllers mid-build).
    ref.listen(subjectScoresProvider, (prev, next) {
      final data = next.asData?.value;
      if (data != null) {
        setState(() => _syncDraft(data));
      }
    });

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _contextBar(c),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: _body(c)),
        ],
      ),
    );
  }

  // ---- Context bar ----------------------------------------------------------
  Widget _contextBar(AppColors c) {
    final classesAsync = ref.watch(classesProvider);
    final subjectsAsync = ref.watch(resultsSubjectsProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final levelId = ref.watch(resultsLevelIdProvider);
    final subjectId = ref.watch(resultsSubjectIdProvider);
    final semesterId = ref.watch(resultsSemesterIdProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: AppRadius.card,
        border: Border.all(color: c.border, width: AppStroke.hairline),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_rounded, size: 18, color: c.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 200,
            child: classesAsync.when(
              loading: () => _hintBox(c, 'Loading classes…'),
              error: (_, __) => _hintBox(c, 'Classes unavailable'),
              data: (classes) {
                final valid =
                classes.any((cl) => cl.levelId == levelId) ? levelId : null;
                return AcademicsDropdown<String>(
                  label: 'Class',
                  value: valid,
                  hint: 'Select class',
                  items: [
                    for (final cls in classes)
                      DropdownMenuItem(
                        value: cls.levelId,
                        child: Text(cls.levelName,
                            style: AppTypography.body
                                .copyWith(color: c.textPrimary)),
                      ),
                  ],
                  onChanged: (v) {
                    ref.read(resultsLevelIdProvider.notifier).state = v;
                    // Changing class clears subject.
                    ref.read(resultsSubjectIdProvider.notifier).state = null;
                    _loadedKey = null;
                  },
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 200,
            child: subjectsAsync.when(
              loading: () => _hintBox(c, 'Loading subjects…'),
              error: (_, __) => _hintBox(c, 'Subjects unavailable'),
              data: (subjects) {
                final valid = subjects.any((s) => s.subjectId == subjectId)
                    ? subjectId
                    : null;
                return AcademicsDropdown<String>(
                  label: 'Subject',
                  value: valid,
                  hint: levelId == null ? 'Pick class first' : 'Select subject',
                  items: [
                    for (final s in subjects)
                      DropdownMenuItem(
                        value: s.subjectId,
                        child: Text(s.subjectName,
                            style: AppTypography.body
                                .copyWith(color: c.textPrimary)),
                      ),
                  ],
                  onChanged: (v) {
                    ref.read(resultsSubjectIdProvider.notifier).state = v;
                    _loadedKey = null;
                  },
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 220,
            child: semestersAsync.when(
              loading: () => _hintBox(c, 'Loading terms…'),
              error: (_, __) => _hintBox(c, 'Terms unavailable'),
              data: (semesters) {
                final valid = semesters.any((s) => s.semesterId == semesterId)
                    ? semesterId
                    : null;
                return AcademicsDropdown<String>(
                  label: 'Term',
                  value: valid,
                  hint: 'Select term',
                  items: [
                    for (final s in semesters)
                      DropdownMenuItem(
                        value: s.semesterId,
                        child: Text('${s.semesterName}  (${s.academicYear})',
                            style: AppTypography.body
                                .copyWith(color: c.textPrimary)),
                      ),
                  ],
                  onChanged: (v) {
                    ref.read(resultsSemesterIdProvider.notifier).state = v;
                    _loadedKey = null;
                  },
                );
              },
            ),
          ),
          const Spacer(),
          AppButton.primary(
            label: 'Save scores',
            icon: Icons.save_rounded,
            busy: _saving,
            onPressed: (_dirty && !_saving) ? _save : null,
          ),
        ],
      ),
    );
  }

  Widget _hintBox(AppColors c, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(' ', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs + 2),
        Container(
          height: 44,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: c.inputBg,
            borderRadius: const BorderRadius.all(AppRadius.mdR),
            border: Border.all(color: c.inputBorder, width: AppStroke.hairline),
          ),
          child:
          Text(text, style: AppTypography.body.copyWith(color: c.textMuted)),
        ),
      ],
    );
  }

  // ---- Body -----------------------------------------------------------------
  Widget _body(AppColors c) {
    final ready = ref.watch(resultsContextReadyProvider);
    if (!ready) {
      return const AcademicsEmpty(
        icon: Icons.grid_on_rounded,
        title: 'Choose class, subject and term',
        subtitle: 'Pick all three above to load the score sheet.',
      );
    }

    final async = ref.watch(subjectScoresProvider);
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.brand)),
      error: (e, _) => AcademicsEmpty(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load the score sheet',
        subtitle: e.toString().replaceFirst('ApiException: ', ''),
        action: AppButton.secondary(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(subjectScoresProvider),
        ),
      ),
      data: (data) {
        if (data == null || data.rows.isEmpty) {
          return const AcademicsEmpty(
            icon: Icons.person_off_rounded,
            title: 'No students',
            subtitle: 'This subject has no students for the chosen term.',
          );
        }
        // Rows are loaded into the editable draft via the ref.listen in build.
        // If the draft isn't populated yet for this data, show a brief spinner.
        if (_draft.isEmpty) {
          return Center(child: CircularProgressIndicator(color: c.brand));
        }
        return _grid(c, data.subjectName);
      },
    );
  }

  // ---- The spreadsheet grid -------------------------------------------------
  Widget _grid(AppColors c, String subjectName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                subjectName.isEmpty ? 'Score sheet' : subjectName,
                style: AppTypography.subtitle.copyWith(color: c.textPrimary),
              ),
            ),
            if (_dirty)
              Text('Unsaved changes',
                  style: AppTypography.caption.copyWith(color: c.warning)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_error != null) ...[
          AcademicsInlineError(message: _error!),
          const SizedBox(height: AppSpacing.md),
        ],
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: AppRadius.card,
              border: Border.all(color: c.border, width: AppStroke.hairline),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.card,
              child: Column(
                children: [
                  _headerRow(c),
                  Divider(height: 1, color: c.divider),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _draft.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: c.divider),
                      itemBuilder: (context, i) => _dataRow(c, i),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const double _nameW = 200;
  static const double _cellW = 78;
  static const double _computedW = 74;

  Widget _headerRow(AppColors c) {
    Widget h(String text, double w, {bool computed = false}) => SizedBox(
      width: w,
      child: Text(
        text,
        textAlign: computed ? TextAlign.center : TextAlign.left,
        style: AppTypography.caption.copyWith(
          color: computed ? c.brand : c.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Container(
      color: c.surfaceAlt,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          h('Student', _nameW),
          const SizedBox(width: AppSpacing.sm),
          for (final col in ScoreColumn.all) ...[
            SizedBox(
              width: _cellW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(col.shortLabel,
                      style: AppTypography.caption.copyWith(
                          color: c.textSecondary, fontWeight: FontWeight.w700)),
                  Text('/${col.max.toInt()}',
                      style: AppTypography.caption
                          .copyWith(color: c.textMuted, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          h('Class /50', _computedW, computed: true),
          const SizedBox(width: AppSpacing.sm),
          h('Exam /50', _computedW, computed: true),
          const SizedBox(width: AppSpacing.sm),
          h('Total', _computedW, computed: true),
        ],
      ),
    );
  }

  Widget _dataRow(AppColors c, int index) {
    final row = _draft[index];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _nameW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.studentName,
                    style:
                    AppTypography.body.copyWith(color: c.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(row.studentId,
                    style:
                    AppTypography.caption.copyWith(color: c.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          for (final col in ScoreColumn.all) ...[
            SizedBox(
              width: _cellW,
              child: _scoreCell(c, index, row, col),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          _computed(c, row.classScore),
          const SizedBox(width: AppSpacing.sm),
          _computed(c, row.calculatedExamScore),
          const SizedBox(width: AppSpacing.sm),
          _computed(c, row.total, strong: true),
        ],
      ),
    );
  }

  Widget _scoreCell(AppColors c, int index, ScoreRow row, ScoreColumn col) {
    final controller = _ctrl(row.studentId, col.key, row.valueFor(col.key));
    final over = (double.tryParse(controller.text.trim()) ?? 0) > col.max;

    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        style: AppTypography.body.copyWith(
          color: over ? c.danger : c.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          filled: true,
          fillColor: over ? c.dangerSubtle : c.inputBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(AppRadius.smR),
            borderSide: BorderSide(
                color: over ? c.danger : c.inputBorder,
                width: AppStroke.hairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(AppRadius.smR),
            borderSide: BorderSide(color: c.brand, width: AppStroke.thick),
          ),
        ),
        onChanged: (v) {
          // Clamp-on-type is avoided (fights the caret); we flag over-max in red
          // and clamp at save. Just record the raw value + recompute.
          _onCell(index, col.key, v);
        },
      ),
    );
  }

  Widget _computed(AppColors c, double value, {bool strong = false}) {
    return SizedBox(
      width: _computedW,
      child: Text(
        value.toStringAsFixed(1),
        textAlign: TextAlign.center,
        style: (strong ? AppTypography.bodyStrong : AppTypography.body)
            .copyWith(color: strong ? c.brand : c.textPrimary),
      ),
    );
  }
}
