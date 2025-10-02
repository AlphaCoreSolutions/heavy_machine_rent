// lib/screens/auth_profile_screens/phone_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/foundation/session_manager.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/l10n/app_localizations.dart';
import 'package:heavy_new/screens/app/notification_screen.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key, this.onDone});
  final VoidCallback? onDone;

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ccCtrl = TextEditingController(text: '966'); // numerals only
  final _digitsCtrl = TextEditingController(); // 9 digits
  final _otpCtrl = TextEditingController();

  bool _stepOtp = false;
  String? _serverOtpHint;
  bool _busy = false;

  @override
  void dispose() {
    _ccCtrl.dispose();
    _digitsCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final cc = int.parse(_ccCtrl.text.replaceAll('+', '').trim());
      final probe = await AuthStore.instance.startPhoneCheck(
        mobileDigits: _digitsCtrl.text.trim(),
        countryCode: cc,
      );
      setState(() {
        _serverOtpHint = probe.otpHint;
        _stepOtp = true;
      });
      AppSnack.info(context, context.l10n.otpSent);
    } catch (e) {
      AppSnack.error(context, context.l10n.couldNotStartVerification);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    final code = _otpCtrl.text.trim();
    if (code.length != 4) {
      AppSnack.error(context, context.l10n.enterFourDigitCode);
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthStore.instance.verifyOtp(otp: code);

      await sessionManager.startFreshSession(reset: true);
      AppSnack.success(context, context.l10n.signedIn);

      if (!mounted) return;
      // Persist FCM token for this user, then optionally send welcome.
      try {
        await Notifications().getDeviceToken();
      } catch (_) {}
      Notifications().sendNotification();
      Navigator.of(context).pop(true);
    } catch (e) {
      AppSnack.error(context, context.l10n.invalidOrExpiredCode);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.actionSignIn)), // reuse existing
      body: AbsorbPointer(
        absorbing: _busy,
        child: LayoutBuilder(
          builder: (context, bc) {
            final w = bc.maxWidth;
            final wide = w >= 900;

            const screenHPad = 1.0;
            const screenVPad = 1.0;
            const formMaxWidth = 600.0;
            const pageMaxWidth = 1100.0;

            final formColumn = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: formMaxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(5, 16, 5, 24),
                children: [
                  // ====== Phone form ======
                  Glass(
                    radius: 20,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.mobileNumber,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              SizedBox(
                                width: 96,
                                child: AInput(
                                  controller: _ccCtrl,
                                  label: context.l10n.codeLabel,
                                  hint: context.l10n.codeHint,
                                  glyph: AppGlyph.globe,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[+\d]'),
                                    ),
                                    LengthLimitingTextInputFormatter(5),
                                  ],
                                  validator: (v) {
                                    final n = int.tryParse(
                                      (v ?? '').replaceAll('+', '').trim(),
                                    );
                                    return (n == null || n <= 0)
                                        ? context.l10n.validationRequired(
                                            context.l10n.codeLabel,
                                          )
                                        : null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AInput(
                                  controller: _digitsCtrl,
                                  label: context.l10n.mobile9DigitsLabel,
                                  hint: context.l10n.mobile9DigitsHint,
                                  glyph: AppGlyph.phone,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(9),
                                  ],
                                  validator: (v) =>
                                      (v == null || v.trim().length != 9)
                                      ? context.l10n.enterNineDigits
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          BrandButton(
                            onPressed: _start,
                            icon: AIcon(
                              AppGlyph.send,
                              color: Colors.white,
                              selected: true,
                            ),
                            child: Text(
                              _stepOtp
                                  ? context.l10n.resendCode
                                  : context.l10n.sendCode,
                            ),
                          ),
                          if (_stepOtp &&
                              (_serverOtpHint?.isNotEmpty ?? false)) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                context.l10n.devOtpHint(_serverOtpHint!),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (_stepOtp) const SizedBox(height: 16),

                  // ====== OTP step ======
                  if (_stepOtp)
                    Glass(
                          radius: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.enterCodeTitle,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              AInput(
                                controller: _otpCtrl,
                                label: context.l10n.codeLabel,
                                hint: '• • • •',
                                keyboardType: TextInputType.number,
                                maxLines: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                              ),
                              const SizedBox(height: 12),
                              BrandButton(
                                onPressed: _verify,
                                icon: AIcon(
                                  AppGlyph.check,
                                  color: Colors.white,
                                  selected: true,
                                ),
                                child: Text(context.l10n.verifyAndContinue),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.l10n.didntGetItTapResend,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 220.ms)
                        .moveY(begin: 8, end: 0),
                ],
              ),
            );

            if (!wide) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: formMaxWidth + 32,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: screenHPad,
                    ).copyWith(top: 8, bottom: screenVPad),
                    child: formColumn,
                  ),
                ),
              );
            }

            // Desktop / big tablet: two columns
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: pageMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ).copyWith(top: 12, bottom: 28),
                  child: Row(
                    children: [
                      // Left welcome/brand panel
                      Expanded(
                        child: Glass(
                          radius: 24,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AIcon(
                                      AppGlyph.login,
                                      color: cs.primary,
                                      selected: true,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.l10n.welcomeBack,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  context.l10n.signInWithMobileBlurb,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AIcon(AppGlyph.info, color: cs.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.l10n.neverShareNumber,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right form column (clamped)
                      Expanded(child: formColumn),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
