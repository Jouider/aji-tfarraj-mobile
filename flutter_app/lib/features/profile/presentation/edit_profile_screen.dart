import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/profile/data/profile_repository.dart';
import 'package:aji_tfarraj/features/profile/domain/city.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedCity;
  String? _selectedDistrict;
  bool _isLoading = false;
  bool _isAvatarLoading = false;
  String? _errorMessage;
  DateTime? _dateOfBirth;
  // Fixed country code for now — Morocco (+212)
  final String _countryCode = '+212';

  @override
  void initState() {
    super.initState();
    final user = ref.read(loginAuthStateProvider).user;
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _selectedCity = user.cityName;
      _selectedDistrict = user.district;
      _phoneController.text = user.phoneNumber ?? '';
      _dateOfBirth = user.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Hard guard — cities must be loaded and city/district must be selected
    final citiesAsync = ref.read(citiesProvider);
    if (!citiesAsync.hasValue) {
      setState(() =>
          _errorMessage = 'Veuillez patienter le chargement des villes.');
      return;
    }
    if (_selectedCity == null) {
      setState(() => _errorMessage = ref.read(stringsProvider).cityRequired);
      return;
    }
    if (_selectedDistrict == null) {
      setState(
          () => _errorMessage = ref.read(stringsProvider).districtRequired);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final phone = _phoneController.text.trim();
      // Update immediately from PATCH response so the router redirect
      // sees profileComplete=true even if the follow-up GET /me fails.
      final updatedUser = await ref.read(profileRepositoryProvider).updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            cityName: _selectedCity,
            district: _selectedDistrict,
            phoneCountryCode: phone.isNotEmpty ? _countryCode : null,
            phoneNumber: phone.isNotEmpty ? phone : null,
            dateOfBirth: _dateOfBirth,
          );
      debugPrint('[EditProfile] PATCH user: profileComplete=${updatedUser.profileComplete}, missing=${updatedUser.missingProfileFields}');
      ref.read(loginAuthStateProvider.notifier).updateUser(updatedUser);
      // Re-fetch from GET /api/auth/me so profile_complete reflects the true
      // server state (the PATCH response may return stale computed values).
      await ref.read(loginAuthStateProvider.notifier).refreshUser();
      final refreshedUser = ref.read(loginAuthStateProvider).user;
      debugPrint('[EditProfile] Refreshed user: profileComplete=${refreshedUser?.profileComplete}, missing=${refreshedUser?.missingProfileFields}');
      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.profileSavedSuccess),
            backgroundColor: AppColors.success,
          ),
        );

        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.home);
        }
      }
    } on ApiException catch (e) {
      final s = ref.read(stringsProvider);
      if (e.code == 'PHONE_ALREADY_USED' ||
          (e.isValidationError && e.errors?['phone_number'] != null)) {
        setState(() => _errorMessage = s.phoneAlreadyUsed);
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      setState(() => _errorMessage = ref.read(stringsProvider).genericError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    Navigator.of(context).pop(); // close bottom sheet
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    } on PlatformException catch (e) {
      if (mounted) {
        final msg = e.code == 'camera_access_denied'
            ? ref.read(stringsProvider).cameraAccessDenied
            : ref.read(stringsProvider).genericError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
      return;
    } catch (_) {
      return; // user cancelled or camera unavailable
    }
    if (picked == null) return;

    setState(() => _isAvatarLoading = true);
    try {
      final updatedUser = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(File(picked.path));
      ref.read(loginAuthStateProvider.notifier).updateUser(updatedUser);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(stringsProvider).genericError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAvatarLoading = false);
    }
  }

  Future<void> _deleteAvatar() async {
    Navigator.of(context).pop(); // close bottom sheet
    setState(() => _isAvatarLoading = true);
    try {
      final updatedUser =
          await ref.read(profileRepositoryProvider).deleteAvatar();
      ref.read(loginAuthStateProvider.notifier).updateUser(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(stringsProvider).avatarDeletedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(stringsProvider).genericError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAvatarLoading = false);
    }
  }

  void _showAvatarSheet() {
    final s = ref.read(stringsProvider);
    final user = ref.read(loginAuthStateProvider).user;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Camera only — no gallery
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(s.takePhoto),
              onTap: _pickAvatar,
            ),
            if (user?.avatarUrl != null)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(s.removePhoto,
                    style: const TextStyle(color: AppColors.error)),
                onTap: _deleteAvatar,
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final authState = ref.watch(loginAuthStateProvider);
    final user = authState.user;
    final citiesAsync = ref.watch(citiesProvider);

    final canGoBack = context.canPop();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.editProfileTitle, style: AppTypography.h3),
        actions: [
          if (!canGoBack)
            TextButton(
              onPressed: () => context.go(Routes.home),
              child: Text(
                s.skipForNow,
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textMuted),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ──
              Center(
                child: GestureDetector(
                  onTap: _isAvatarLoading ? null : _showAvatarSheet,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.backgroundGrey,
                        child: _isAvatarLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.secondary)
                            : (user?.avatarUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: user!.avatarUrl!,
                                      width: 104,
                                      height: 104,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Icon(
                                          Icons.person,
                                          size: 52,
                                          color: AppColors.textMuted),
                                      errorWidget: (_, __, ___) => const Icon(
                                          Icons.person,
                                          size: 52,
                                          color: AppColors.textMuted),
                                    ),
                                  )
                                : const Icon(Icons.person,
                                    size: 52, color: AppColors.textMuted)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (user?.avatarUrl == null && !_isAvatarLoading) ...[
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        s.avatarRequiredHint,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.warning),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // ── Error banner ──
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── First name ──
              TextFormField(
                controller: _firstNameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration:
                    _fieldDecoration(s.firstNameLabel, Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s.firstNameRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Last name ──
              TextFormField(
                controller: _lastNameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration:
                    _fieldDecoration(s.lastNameLabel, Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s.lastNameRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Date of birth ──
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1940),
                          lastDate: DateTime(2008, 12, 31),
                        );
                        if (picked != null) {
                          setState(() => _dateOfBirth = picked);
                        }
                      },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _dateOfBirth != null
                          ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                          : '',
                    ),
                    decoration: _fieldDecoration(
                        s.dateOfBirthLabel, Icons.cake_outlined),
                    validator: (_) =>
                        _dateOfBirth == null ? s.dateOfBirthRequired : null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── City + District ──
              citiesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: LinearProgressIndicator(color: AppColors.secondary),
                ),
                error: (_, __) => _CitiesRetryWidget(
                  onRetry: () => ref.refresh(citiesProvider),
                ),
                data: (cities) => Column(
                  children: [
                    // City dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCity,
                      decoration: _fieldDecoration(
                          s.cityLabel, Icons.location_city_outlined),
                      items: cities
                          .map((c) => DropdownMenuItem(
                                value: c.name,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: _isLoading
                          ? null
                          : (val) {
                              setState(() {
                                _selectedCity = val;
                                _selectedDistrict = null;
                              });
                            },
                      validator: (_) =>
                          _selectedCity == null ? s.cityRequired : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // District dropdown — key forces recreation when city changes
                    // so initialValue is applied fresh via initState each time
                    Builder(
                      key: ValueKey(_selectedCity),
                      builder: (_) {
                        final City? selected = _selectedCity != null
                            ? cities.cast<City?>().firstWhere(
                                (c) => c?.name == _selectedCity,
                                orElse: () => null)
                            : null;
                        final districts = selected?.districts ?? [];
                        return DropdownButtonFormField<String>(
                          initialValue: districts.contains(_selectedDistrict)
                              ? _selectedDistrict
                              : null,
                          decoration: _fieldDecoration(
                              s.districtLabel, Icons.map_outlined),
                          items: districts
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ))
                              .toList(),
                          onChanged: (_isLoading || districts.isEmpty)
                              ? null
                              : (val) =>
                                  setState(() => _selectedDistrict = val),
                          validator: (_) => _selectedDistrict == null
                              ? s.districtRequired
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Phone ──
              _PhoneSection(
                phoneController: _phoneController,
                countryCode: _countryCode,
                isLoading: _isLoading,
                fieldDecoration: _fieldDecoration,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Save button ──
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(s.saveChanges, style: AppTypography.labelLarge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Phone section ──────────────────────────────────────────────────────────

class _PhoneSection extends ConsumerWidget {
  const _PhoneSection({
    required this.phoneController,
    required this.countryCode,
    required this.isLoading,
    required this.fieldDecoration,
  });

  final TextEditingController phoneController;
  final String countryCode;
  final bool isLoading;
  final InputDecoration Function(String, IconData) fieldDecoration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.phoneLabel, style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: AppSpacing.inputHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              alignment: Alignment.center,
              child: Text(countryCode, style: AppTypography.bodyMedium),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: phoneController,
                enabled: !isLoading,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: fieldDecoration(s.phoneNumberHint, Icons.phone_outlined),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s.phoneNumberInvalid
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Shown when GET /api/cities fails — lets user retry
class _CitiesRetryWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _CitiesRetryWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Impossible de charger les villes.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Réessayer',
              style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
