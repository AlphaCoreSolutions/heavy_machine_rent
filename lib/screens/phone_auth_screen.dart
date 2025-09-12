import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:heavy_new/foundation/ui/ui_kit.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';

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
    if (_busy) return; // debounce
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
      AppSnack.info(context, 'OTP sent');
    } catch (e) {
      AppSnack.error(context, 'Could not start verification');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy) return; // debounce double taps
    final code = _otpCtrl.text.trim();
    if (code.length != 4) {
      AppSnack.error(context, 'Enter the 4-digit code');
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthStore.instance.verifyOtp(otp: code);
      AppSnack.success(context, 'Signed in');

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      AppSnack.error(context, 'Invalid or expired code');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: LayoutBuilder(
          builder: (context, bc) {
            final w = bc.maxWidth;
            final wide = w >= 900;

            // Common paddings & max widths
            const screenHPad = 16.0;
            const screenVPad = 24.0;
            const formMaxWidth = 520.0; // clamp fields on desktop
            const pageMaxWidth = 1100.0; // clamp whole page on desktop

            final formColumn = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: formMaxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                            'Mobile number',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              SizedBox(
                                width: 96,
                                child: AInput(
                                  controller: _ccCtrl,
                                  label: 'Code',
                                  hint: '966',
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
                                        ? 'Code'
                                        : null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AInput(
                                  controller: _digitsCtrl,
                                  label: 'Mobile (9 digits)',
                                  hint: '5XX XXX XXX',
                                  glyph: AppGlyph.phone,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(9),
                                  ],
                                  validator: (v) =>
                                      (v == null || v.trim().length != 9)
                                      ? 'Enter 9 digits'
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
                            child: Text(_stepOtp ? 'Resend code' : 'Send code'),
                          ),
                          if (_stepOtp &&
                              (_serverOtpHint?.isNotEmpty ?? false)) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cs.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'DEV OTP: $_serverOtpHint',
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
                                'Enter code',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              AInput(
                                controller: _otpCtrl,
                                label: 'Code',
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
                                child: const Text('Verify & continue'),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Didn\'t get it? Tap "Resend code".',
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
              // -------- Phone / small tablet: single column, centered width --------
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

            // -------- Desktop / big tablet: two columns (welcome + form) --------
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
                                      'Welcome back',
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
                                  'Sign in with your mobile number.\n'
                                  'Fast, secure, OTP-based login.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceVariant,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AIcon(AppGlyph.info, color: cs.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'We’ll never share your number.',
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
