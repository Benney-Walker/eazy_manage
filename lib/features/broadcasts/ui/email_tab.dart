import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/notification/notifications.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../academics/ui/academics_widgets.dart';
import '../data/broadcast_models.dart';
import '../data/broadcast_providers.dart';
import 'audience_picker.dart';

/// Email broadcast composer.
class EmailTab extends ConsumerStatefulWidget {
  const EmailTab({super.key});

  @override
  ConsumerState<EmailTab> createState() => _EmailTabState();
}

class _EmailTabState extends ConsumerState<EmailTab> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  Set<String> _audience = {};
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_subject.text.trim().isEmpty) {
      setState(() => _error = 'Enter a subject.');
      return;
    }
    if (_body.text.trim().isEmpty) {
      setState(() => _error = 'Enter a message body.');
      return;
    }
    if (_audience.isEmpty) {
      setState(() => _error = 'Select at least one audience.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(broadcastRepositoryProvider).sendEmail(
        BroadcastEmailRequest(
          subject: _subject.text.trim(),
          body: _body.text.trim(),
          audience: _audience.toList(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _subject.clear();
        _body.clear();
        _audience = {};
      });
      notify(ref, context,
          action: 'Send email broadcast', message: 'Email broadcast sent.');
    } on ApiException catch (e) {
      notify(ref, context,
          action: 'Send email broadcast', message: e.message,
          isError: true, showSnackbar: false);
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } catch (_) {
      const msg = 'Could not send. Try again.';
      notify(ref, context,
          action: 'Send email broadcast', message: msg,
          isError: true, showSnackbar: false);
      setState(() {
        _sending = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Subject',
                hint: 'Email subject',
                controller: _subject,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Message',
                  style: AppTypography.label.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: '',
                hint: 'Write the email body…',
                controller: _body,
                maxLines: 6,
              ),
              const SizedBox(height: AppSpacing.lg),
              AudiencePicker(
                selected: _audience,
                onChanged: (s) => setState(() => _audience = s),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AcademicsInlineError(message: _error!),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  const Spacer(),
                  AppButton.ghost(
                    label: 'Clear',
                    onPressed: _sending
                        ? null
                        : () => setState(() {
                      _subject.clear();
                      _body.clear();
                      _audience = {};
                      _error = null;
                    }),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton.primary(
                    label: 'Send email',
                    icon: Icons.mail_rounded,
                    busy: _sending,
                    onPressed: _send,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}