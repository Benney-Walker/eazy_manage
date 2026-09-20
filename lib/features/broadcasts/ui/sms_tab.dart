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

/// SMS broadcast composer.
class SmsTab extends ConsumerStatefulWidget {
  const SmsTab({super.key});

  @override
  ConsumerState<SmsTab> createState() => _SmsTabState();
}

class _SmsTabState extends ConsumerState<SmsTab> {
  final _message = TextEditingController();
  Set<String> _audience = {};
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _onMessageChanged(String val) {
    if (val.length > 350) {
      final truncated = val.substring(0, 350);
      _message.value = TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
    }
    setState(() {});
  }

  Future<void> _send() async {
    final msgText = _message.text.trim();
    if (msgText.isEmpty) {
      setState(() => _error = 'Enter a message.');
      return;
    }
    if (msgText.length > 350) {
      setState(() => _error = 'Message cannot exceed 350 characters.');
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
      await ref.read(broadcastRepositoryProvider).sendSms(
        BroadcastSmsRequest(
          message: msgText,
          audience: _audience.toList(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _message.clear();
        _audience = {};
      });
      notify(ref, context,
          action: 'Send SMS broadcast', message: 'SMS broadcast queued for delivery.');
    } on ApiException catch (e) {
      notify(ref, context,
          action: 'Send SMS broadcast', message: e.message,
          isError: true, showSnackbar: false);
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } catch (_) {
      const msg = 'Could not send. Try again.';
      notify(ref, context,
          action: 'Send SMS broadcast', message: msg,
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
    final count = _message.text.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Message',
                  style: AppTypography.label.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: '',
                hint: 'Type the SMS message…',
                controller: _message,
                maxLines: 4,
                onChanged: _onMessageChanged,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: c.textMuted),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Your school name will be automatically added to the message.',
                            style: AppTypography.caption
                                .copyWith(color: c.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '$count / 350 characters',
                    style: AppTypography.caption.copyWith(
                      color: count >= 350 ? c.danger : c.textMuted,
                    ),
                  ),
                ],
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
                      _message.clear();
                      _audience = {};
                      _error = null;
                    }),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton.primary(
                    label: 'Send SMS',
                    icon: Icons.sms_rounded,
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