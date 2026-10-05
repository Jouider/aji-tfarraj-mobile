import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:aji_tfarraj/app/copywriting/wafacash_copy.dart';
import 'package:aji_tfarraj/app/design_system/buttons.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/charge_public/data/charge_public_repository.dart';

/// La CIN, envoyée une fois pour les retraits Wafacash.
///
/// Wafacash ne remet l'argent qu'au titulaire de la carte, sur son nom exact :
/// le nom du compte est souvent un surnom, d'où le champ « exactement comme sur
/// ta CIN ». Le staff vérifie contre les photos avant le premier retrait, et
/// les suivants s'en servent sans revenir ici.
class WafacashIdentityScreen extends ConsumerStatefulWidget {
  const WafacashIdentityScreen({super.key, this.initialName});

  /// Le nom déjà envoyé, pour un renvoi après refus.
  final String? initialName;

  @override
  ConsumerState<WafacashIdentityScreen> createState() =>
      _WafacashIdentityScreenState();
}

class _WafacashIdentityScreenState
    extends ConsumerState<WafacashIdentityScreen> {
  late final _name = TextEditingController(text: widget.initialName ?? '');
  final _cin = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  XFile? _front;
  XFile? _back;
  bool _sending = false;
  String? _error;

  /// Une ou deux lettres, puis des chiffres — la forme de toutes les CIN.
  /// La même règle que le serveur, pour dire l'erreur avant l'envoi.
  static final _cinPattern = RegExp(r'^[A-Za-z]{1,2}\s?\d{3,8}$');

  @override
  void dispose() {
    _name.dispose();
    _cin.dispose();
    super.dispose();
  }

  Future<void> _pick(bool front) async {
    final c = ref.read(stringsProvider).wafacash;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundWhite,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(c.takePhoto),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(c.fromGallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    // Assez grand pour lire le nom et le numéro, assez léger pour un réseau
    // mobile : une CIN n'a pas besoin de douze mégapixels.
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 82,
    );
    if (file == null || !mounted) return;

    setState(() {
      if (front) {
        _front = file;
      } else {
        _back = file;
      }
      _error = null;
    });
  }

  Future<void> _submit() async {
    final c = ref.read(stringsProvider).wafacash;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_front == null || _back == null) {
      setState(() => _error = c.photosRequired);
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(wafacashRepositoryProvider).submitIdentity(
            legalName: _name.text,
            cinNumber: _cin.text,
            frontPath: _front!.path,
            backPath: _back!.path,
          );
      ref.invalidate(wafacashProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(c.identitySent),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e is ApiException ? e.message : c.genericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(stringsProvider).wafacash;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: Text(c.identityTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(c.identityIntro,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                enabled: !_sending,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: c.legalNameLabel),
                validator: (v) =>
                    (v ?? '').trim().length < 3 ? c.nameRequired : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _cin,
                enabled: !_sending,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: InputDecoration(
                  labelText: c.cinLabel,
                  hintText: c.cinHint,
                ),
                validator: (v) =>
                    _cinPattern.hasMatch((v ?? '').trim()) ? null : c.cinInvalid,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _PhotoSlot(
                      label: c.front,
                      file: _front,
                      copy: c,
                      enabled: !_sending,
                      onTap: () => _pick(true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _PhotoSlot(
                      label: c.back,
                      file: _back,
                      copy: c,
                      enabled: !_sending,
                      onTap: () => _pick(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(c.photoTip,
                  style:
                      AppTypography.caption.copyWith(color: AppColors.textMuted)),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.errorDark)),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: c.submit,
                icon: Icons.verified_user_outlined,
                isLoading: _sending,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(c.privacy,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textMuted)),
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

/// Une face de la carte : vide, elle invite ; remplie, elle montre ce qui part.
class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.label,
    required this.file,
    required this.copy,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final XFile? file;
  final WafacashCopy copy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AspectRatio(
        // Le format d'une carte d'identité : 85,6 × 54 mm.
        aspectRatio: 85.6 / 54,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.badge_outlined, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.xs),
                    Text(label, style: AppTypography.labelMedium),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(file!.path), fit: BoxFit.cover),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '$label · ${copy.retake}',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
