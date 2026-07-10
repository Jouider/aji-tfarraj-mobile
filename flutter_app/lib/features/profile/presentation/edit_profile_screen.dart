import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/profile/data/profile_repository.dart';
import 'package:aji_tfarraj/features/profile/presentation/face_capture_screen.dart';
import 'package:aji_tfarraj/features/profile/domain/city.dart';

/// Session-scoped flag set when the user taps "Skip for now" on the forced
/// profile-completion screen. While true, the router stops force-redirecting
/// to [Routes.editProfile]. Reset on logout. Reservation flows still enforce
/// completion via their own dialogs + server 409 PROFILE_INCOMPLETE.
final profileCompletionSkippedProvider = StateProvider<bool>((_) => false);

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
  String? _gender; // 'male' | 'female'
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
      _gender = user.gender;
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
    if (_gender == null) {
      setState(() => _errorMessage = ref.read(stringsProvider).genderRequired);
      return;
    }
    // Birthday is a server-required field; without this guard a user could save
    // with it empty, the backend keeps it in missing_profile_fields, and the
    // router silently bounces back here — the reported "sign-up loop".
    if (_dateOfBirth == null) {
      setState(() =>
          _errorMessage = ref.read(stringsProvider).dateOfBirthRequired);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final phone = _phoneController.text.trim();
      final updatedUser = await ref.read(profileRepositoryProvider).updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            cityName: _selectedCity,
            district: _selectedDistrict,
            phoneCountryCode: phone.isNotEmpty ? _countryCode : null,
            phoneNumber: phone.isNotEmpty ? phone : null,
            dateOfBirth: _dateOfBirth,
            gender: _gender,
          );
      debugPrint('[EditProfile] PATCH user: profileComplete=${updatedUser.profileComplete}, missing=${updatedUser.missingProfileFields}');
      ref.read(loginAuthStateProvider.notifier).updateUser(updatedUser);
      await ref.read(loginAuthStateProvider.notifier).refreshUser();
      final refreshedUser = ref.read(loginAuthStateProvider).user;
      debugPrint('[EditProfile] Refreshed user: profileComplete=${refreshedUser?.profileComplete}, missing=${refreshedUser?.missingProfileFields}');
      // Safety net against a silent redirect loop: if the server STILL reports a
      // required field missing (one the form couldn't satisfy), the global router
      // would immediately bounce us back to this screen. Show a clear message and
      // stay, instead of a misleading "saved" followed by the loop.
      const optionalFields = {
        'avatar', 'avatar_url', 'live_photo_captured_at', 'phone_verified_at',
      };
      final stillMissingRequired = refreshedUser != null &&
          !refreshedUser.profileComplete &&
          refreshedUser.missingProfileFields
              .where((f) => !optionalFields.contains(f))
              .isNotEmpty;
      if (stillMissingRequired) {
        if (mounted) {
          setState(() => _errorMessage =
              ref.read(stringsProvider).profileStillIncomplete);
        }
        return;
      }
      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.profileSavedSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
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
    Navigator.of(context).pop();

    // Custom camera with an oval face-guide frame. It validates that a face is
    // present and returns the captured file path (camera-only live capture —
    // the backend records live_photo_captured_at for identity).
    final path = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const FaceCaptureScreen(),
      ),
    );
    if (path == null || !mounted) return;

    setState(() => _isAvatarLoading = true);

    try {
      final updatedUser = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(File(path));
      ref.read(loginAuthStateProvider.notifier).updateUser(updatedUser);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(stringsProvider).genericError),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAvatarLoading = false);
    }
  }

  Future<void> _deleteAvatar() async {
    Navigator.of(context).pop();
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(stringsProvider).genericError),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
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
      backgroundColor: AppColors.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    size: 18, color: AppColors.secondary),
              ),
              title: Text(s.takePhoto,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              onTap: _pickAvatar,
            ),
            if (user?.avatarUrl != null)
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.error),
                ),
                title: Text(s.removePhoto,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.error, fontWeight: FontWeight.w500)),
                onTap: _deleteAvatar,
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  /// Drum-roll (CupertinoPicker) bottom sheet for birth date selection.
  void _showDateDrumPicker(BuildContext context) {
    final initial = _dateOfBirth ?? DateTime(2000, 1, 1);
    int selDay = initial.day;
    int selMonth = initial.month;
    int selYear = initial.year;

    final years = List.generate(
        DateTime.now().year - 1939, (i) => 1940 + i); // 1940 → current year
    final months = List.generate(12, (i) => i + 1);

    int daysInMonth(int m, int y) => DateTime(y, m + 1, 0).day;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          final days =
              List.generate(daysInMonth(selMonth, selYear), (i) => i + 1);
          // Clamp selDay if month/year changed
          if (selDay > days.length) selDay = days.length;

          return SizedBox(
            height: 340,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Annuler',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      Text(
                        'Date de naissance',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _dateOfBirth = DateTime(selYear, selMonth, selDay);
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'OK',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Wheels
                Expanded(
                  child: Row(
                    children: [
                      // Day
                      Expanded(
                        flex: 2,
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: selDay - 1),
                          itemExtent: 40,
                          onSelectedItemChanged: (i) =>
                              setModalState(() => selDay = days[i]),
                          children: days
                              .map((d) => Center(
                                    child: Text(
                                      d.toString().padLeft(2, '0'),
                                      style: AppTypography.bodyLarge.copyWith(
                                          color: AppColors.textPrimary),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      // Month
                      Expanded(
                        flex: 3,
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: selMonth - 1),
                          itemExtent: 40,
                          onSelectedItemChanged: (i) => setModalState(() {
                            selMonth = months[i];
                            final d = daysInMonth(selMonth, selYear);
                            if (selDay > d) selDay = d;
                          }),
                          children: [
                            'Janvier', 'Février', 'Mars', 'Avril', 'Mai',
                            'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre',
                            'Novembre', 'Décembre',
                          ]
                              .map((m) => Center(
                                    child: Text(
                                      m,
                                      style: AppTypography.bodyLarge.copyWith(
                                          color: AppColors.textPrimary),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      // Year
                      Expanded(
                        flex: 3,
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: years.indexOf(selYear)),
                          itemExtent: 40,
                          onSelectedItemChanged: (i) => setModalState(() {
                            selYear = years[i];
                            final d = daysInMonth(selMonth, selYear);
                            if (selDay > d) selDay = d;
                          }),
                          children: years
                              .map((y) => Center(
                                    child: Text(
                                      y.toString(),
                                      style: AppTypography.bodyLarge.copyWith(
                                          color: AppColors.textPrimary),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  /// Brand-token input decoration — filled backgroundGrey, secondary focus border.
  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: AppColors.secondary),
      filled: true,
      fillColor: AppColors.backgroundGrey,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
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
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          s.editProfileTitle,
          style: AppTypography.h4.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: canGoBack
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    size: 20, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          if (!canGoBack)
            TextButton(
              onPressed: () {
                ref.read(profileCompletionSkippedProvider.notifier).state =
                    true;
                context.go(Routes.home);
              },
              child: Text(
                s.skipForNow,
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textMuted),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // ── Avatar hero ──────────────────────────────────
              _AvatarHero(
                user: user,
                isLoading: _isAvatarLoading,
                onTap: _isAvatarLoading ? null : _showAvatarSheet,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Avatar required hint
              if (user?.avatarUrl == null && !_isAvatarLoading) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: AppColors.warningDark),
                        const SizedBox(width: 5),
                        Text(
                          s.avatarRequiredHint,
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.warningDark,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // ── Error banner ──────────────────────────────────
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.30)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── Personal info ──────────────────────────────────
              _SectionLabel(s.editSectionPersonal),
              const SizedBox(height: AppSpacing.sm),
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
              TextFormField(
                controller: _lastNameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration:
                    _fieldDecoration(s.lastNameLabel, Icons.badge_outlined),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s.lastNameRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Date of birth — drum-roll bottom sheet (day / month / year)
              GestureDetector(
                onTap: _isLoading ? null : () => _showDateDrumPicker(context),
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

              // ── Gender — friendly two-option toggle ───────────
              _GenderField(
                label: s.genderLabel,
                value: _gender,
                maleLabel: s.genderMale,
                femaleLabel: s.genderFemale,
                enabled: !_isLoading,
                onChanged: (g) => setState(() => _gender = g),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Location ──────────────────────────────────────
              _SectionLabel(s.editSectionLocation),
              const SizedBox(height: AppSpacing.sm),
              citiesAsync.when(
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: const LinearProgressIndicator(
                        color: AppColors.secondary,
                        backgroundColor: Colors.transparent),
                  ),
                ),
                error: (_, __) => _CitiesRetryWidget(
                  onRetry: () => ref.refresh(citiesProvider),
                ),
                data: (cities) {
                  final isAr = ref.watch(isRtlProvider);
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCity,
                        decoration: _fieldDecoration(
                            s.cityLabel, Icons.location_city_outlined),
                        dropdownColor: AppColors.surfaceOverlay,
                        items: cities
                            .map((c) => DropdownMenuItem(
                                  value: c.name,
                                  child: Text(c.localizedName(isAr),
                                      style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textPrimary)),
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
                            dropdownColor: AppColors.surfaceOverlay,
                            items: districts
                                .map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                          selected?.localizedDistrict(d, isAr) ?? d,
                                          style: AppTypography.bodyMedium.copyWith(
                                              color: AppColors.textPrimary)),
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
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Contact ───────────────────────────────────────
              _SectionLabel(s.editSectionContact),
              const SizedBox(height: AppSpacing.sm),
              _PhoneSection(
                phoneController: _phoneController,
                countryCode: _countryCode,
                isLoading: _isLoading,
                fieldDecoration: _fieldDecoration,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Save CTA ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(s.saveChanges,
                            style: AppTypography.buttonLarge
                                .copyWith(fontSize: 15)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar Hero — gradient ring, edit badge, loading overlay
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarHero extends ConsumerWidget {
  final dynamic user;
  final bool isLoading;
  final VoidCallback? onTap;

  const _AvatarHero({
    required this.user,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Gradient ring: outer=114, inner gap container=104
            Container(
              width: 114,
              height: 114,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundWhite,
                  ),
                  child: ClipOval(
                    child: isLoading
                        ? Container(
                            color: AppColors.backgroundGrey,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.secondary),
                            ),
                          )
                        : (user?.avatarUrl != null
                            ? Image.network(
                                user!.avatarUrl!,
                                width: 104,
                                height: 104,
                                fit: BoxFit.cover,
                                // Bound the decoded bitmap so a large source
                                // image can't OOM the render (displayed at 104).
                                cacheWidth: 312,
                                cacheHeight: 312,
                                loadingBuilder: (_, child, progress) =>
                                    progress == null ? child : _AvatarPlaceholder(),
                                errorBuilder: (_, __, ___) =>
                                    _AvatarPlaceholder(),
                              )
                            : _AvatarPlaceholder()),
                  ),
                ),
              ),
            ),
            // Edit badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundWhite, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt,
                  size: 15, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundGrey,
      child: Icon(Icons.person, size: 48, color: AppColors.textMuted),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label — secondary left accent, uppercase textMuted 11px ls1.2
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 2,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gender field — two large, tappable options (Homme / Femme · ذكر / أنثى)
// ─────────────────────────────────────────────────────────────────────────────

class _GenderField extends StatelessWidget {
  final String label;
  final String? value; // 'male' | 'female'
  final String maleLabel;
  final String femaleLabel;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _GenderField({
    required this.label,
    required this.value,
    required this.maleLabel,
    required this.femaleLabel,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _GenderOption(
                label: maleLabel,
                icon: Icons.male_rounded,
                selected: value == 'male',
                onTap: enabled ? () => onChanged('male') : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _GenderOption(
                label: femaleLabel,
                icon: Icons.female_rounded,
                selected: value == 'female',
                onTap: enabled ? () => onChanged('female') : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppColors.secondary : AppColors.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.secondary.withValues(alpha: 0.10)
                : AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle,
                    size: 16, color: AppColors.secondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone section
// ─────────────────────────────────────────────────────────────────────────────

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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code chip — matches field style
            Container(
              height: AppSpacing.inputHeight,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              alignment: Alignment.center,
              child: Text(
                countryCode,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: phoneController,
                enabled: !isLoading,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    fieldDecoration(s.phoneNumberHint, Icons.phone_outlined),
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

// ─────────────────────────────────────────────────────────────────────────────
// Cities retry widget
// ─────────────────────────────────────────────────────────────────────────────

class _CitiesRetryWidget extends ConsumerWidget {
  final VoidCallback onRetry;
  const _CitiesRetryWidget({required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined,
              color: AppColors.error, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Impossible de charger les villes.',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              s.resDetailRetry,
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
