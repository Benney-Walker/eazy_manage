import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
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

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) {
      setState(() => _error = 'Enter a message.');
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
              message: _message.text.trim(),
              audience: _audience.toList(),
            ),
          );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _message.clear();
        _audience = {};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS broadcast sent.')),
      );
    } on ApiException catch (e) {
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _sending = false;
        _error = 'Could not send. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final count = _message.text.trim().length;

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
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: Text('$count characters',
                    style: AppTypography.caption.copyWith(color: c.textMuted)),
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
