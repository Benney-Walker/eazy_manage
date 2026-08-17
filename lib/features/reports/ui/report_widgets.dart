import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_button.dart';
import '../../academics/ui/academics_widgets.dart';
import '../data/report_pdf_service.dart';

/// A labelled dropdown wrapper matching the report context bars. Thin shim over
/// [AcademicsDropdown] so report screens read cleanly.
class ReportPicker extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final double width;

  const ReportPicker({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AcademicsDropdown<String>(
        label: label,
        value: value,
        hint: hint,
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

/// A "Download PDF" button that fetches bytes and saves through the native
/// dialog, with its own busy state and success/cancel/error snackbars.
class DownloadPdfButton extends ConsumerStatefulWidget {
  /// Builds the endpoint path to fetch (null disables the button).
  final String? path;
  final String suggestedName;

  /// Button caption. Defaults to a generic "Download PDF"; override when the
  /// download is something more specific (e.g. a class's report cards).
  final String label;

  const DownloadPdfButton({
    super.key,
    required this.path,
    required this.suggestedName,
    this.label = 'Download PDF',
  });

  @override
  ConsumerState<DownloadPdfButton> createState() => _DownloadPdfButtonState();
}

class _DownloadPdfButtonState extends ConsumerState<DownloadPdfButton> {
  bool _busy = false;

  Future<void> _download() async {
    final path = widget.path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(reportPdfServiceProvider).downloadAndSave(
        path: path,
        suggestedName: widget.suggestedName,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (result == PdfSaveResult.saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report saved.')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${e.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not download the report.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(
      label: widget.label,
      icon: Icons.download_rounded,
      busy: _busy,
      onPressed: widget.path == null ? null : _download,
    );
  }
}

/// A framed, scrollable table container used by report previews.
class ReportTable extends StatelessWidget {
  final Widget header;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const ReportTable({
    super.key,
    required this.header,
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
        child: Column(
          children: [
            Container(color: c.surfaceAlt, child: header),
            Divider(height: 1, color: c.divider),
            Expanded(
              child: ListView.separated(
                itemCount: itemCount,
                separatorBuilder: (_, __) => Divider(height: 1, color: c.divider),
                itemBuilder: itemBuilder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small helper to render a bar of picker widgets + optional trailing action.
class ReportContextBar extends StatelessWidget {
  final List<Widget> pickers;
  final Widget? trailing;

  const ReportContextBar({super.key, required this.pickers, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: AppRadius.card,
        border: Border.all(color: c.border, width: AppStroke.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < pickers.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            pickers[i],
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A small "Run" button used by report context bars to trigger a fetch.
class ReportRunButton extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final VoidCallback onRun;

  const ReportRunButton({
    super.key,
    required this.enabled,
    required this.busy,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(
      label: 'Run',
      icon: Icons.play_arrow_rounded,
      busy: busy,
      onPressed: enabled ? onRun : null,
    );
  }
}

/// Shared empty/error/loading helpers so report bodies stay short.
class ReportStates {
  static Widget loading(AppColors c) =>
      Center(child: CircularProgressIndicator(color: c.brand));

  static Widget error(Object e, VoidCallback onRetry) => AcademicsEmpty(
    icon: Icons.cloud_off_rounded,
    title: 'Couldn\'t load the report',
    subtitle: e.toString().replaceFirst('ApiException: ', ''),
    action: AppButton.secondary(
      label: 'Retry',
      icon: Icons.refresh_rounded,
      onPressed: onRetry,
    ),
  );

  static Widget prompt(String title, String subtitle) => AcademicsEmpty(
    icon: Icons.tune_rounded,
    title: title,
    subtitle: subtitle,
  );

  static Widget empty(String title, String subtitle) => AcademicsEmpty(
    icon: Icons.inbox_rounded,
    title: title,
    subtitle: subtitle,
  );
}