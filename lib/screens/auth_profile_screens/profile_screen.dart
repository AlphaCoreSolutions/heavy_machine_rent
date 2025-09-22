// lib/screens/auth_profile_screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:heavy_new/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;
import 'package:heavy_new/core/auth/auth_store.dart';
import 'package:heavy_new/core/models/user/user_account.dart';

import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart'; // Glass, AppSnack, PressableScale
import 'package:heavy_new/foundation/ui/ui_kit.dart'; // AInput, BrandButton, GhostButton

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _mobile = TextEditingController();

  UserAccount? _model;
  File? _pickedAvatar;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() => _busy = true);

      final au = AuthStore.instance.user.value;
      UserAccount pref = UserAccount(
        id: au?.id,
        fullName: au?.fullName,
        email: au?.email,
        mobile: au?.mobile,
        countryCode: au?.countryCode,
        createDateTime: au?.createDateTime,
        modifyDateTime: au?.modifyDateTime,
        statusId: au?.statusId,
        isActive: au?.isActive,
        isCompleted: au?.isCompleted,
        userTypeId: au?.userTypeId,
        password: null,
      );

      if (pref.id != null && pref.id! > 0) {
        try {
          pref = await api.Api.getUserAccountById(pref.id!);
        } catch (_) {
          /* keep local */
        }
      }

      _model = pref;
      _name.text = pref.fullName ?? '';
      _email.text = pref.email ?? '';
      _mobile.text = pref.mobile ?? '';
      _password.clear();
    } catch (_) {
      AppSnack.error(context, context.l10n.failedToLoadProfile);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final au = AuthStore.instance.user.value;
      final includePassword = _password.text.trim().isNotEmpty;

      final updated = UserAccount(
        id: _model?.id ?? au?.id,
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        password: includePassword ? _password.text.trim() : null,
        mobile: _mobile.text.trim(),
        countryCode: _model?.countryCode ?? au?.countryCode,
        isCompleted: true,
        isActive: _model?.isActive ?? true,
        statusId: _model?.statusId,
        userTypeId: _model?.userTypeId ?? au?.userTypeId,
        modifyDateTime: DateTime.now(),
        createDateTime: _model?.createDateTime,
        otpcode: _model?.otpcode,
        otpExpire: _model?.otpExpire,
      );

      final saved = await api.Api.saveUserAccount(
        updated,
        includePassword: includePassword,
      );

      await AuthStore.instance.saveProfileAndMarkCompleted(
        fullName: saved.fullName ?? _name.text.trim(),
        email: saved.email ?? _email.text.trim(),
        mobile: saved.mobile ?? _mobile.text.trim(),
      );

      _model = saved;
      _password.clear();

      if (!mounted) return;
      AppSnack.success(context, context.l10n.profileSaved);
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, context.l10n.couldNotSaveProfile);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (x != null) {
      setState(() => _pickedAvatar = File(x.path));
      // TODO: upload avatar when backend route is available
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profileTitle),
      ), // already added earlier
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                // Avatar + pick
                Glass(
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: cs.surfaceVariant,
                          backgroundImage: _pickedAvatar != null
                              ? FileImage(_pickedAvatar!)
                              : null,
                          child: _pickedAvatar == null
                              ? AIcon(AppGlyph.user, color: cs.onSurfaceVariant)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _name.text.isEmpty
                                ? context.l10n.profileCompletePrompt
                                : _name.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PressableScale(
                          onTap: _pickAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Form
                Glass(
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Form(
                      key: _form,
                      child: Column(
                        children: [
                          AInput(
                            controller: _name,
                            label: context.l10n.fullName,
                            glyph: AppGlyph.user,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? context.l10n.validationRequired(
                                    context.l10n.fullName,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          AInput(
                            controller: _email,
                            label: context.l10n.email, // existing key
                            glyph: AppGlyph.mail,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty)
                                return context.l10n.validationEmail;
                              if (!t.contains('@') || !t.contains('.')) {
                                return context.l10n.validationEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          AInput(
                            controller: _mobile,
                            label: context.l10n.phone, // reuse existing "phone"
                            glyph: AppGlyph.phone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 8),
                          AInput(
                            controller: _password,
                            label: context.l10n.passwordKeep,
                            glyph: AppGlyph.lock,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty) return null; // optional
                              if (t.length < 6)
                                return context.l10n.validationMinChars(6);
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: BrandButton(
                                  onPressed: _save,
                                  icon: AIcon(
                                    AppGlyph.save,
                                    color: Colors.white,
                                    selected: true,
                                    size: 22,
                                  ),
                                  child: Text(
                                    context.l10n.actionSaveChanges,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GhostButton(
                                  onPressed: _load,
                                  icon: AIcon(
                                    AppGlyph.refresh,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 22,
                                  ),
                                  child: Text(context.l10n.actionReset),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
