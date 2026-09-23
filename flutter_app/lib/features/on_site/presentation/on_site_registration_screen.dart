import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/on_site/data/on_site_repository.dart';
import 'package:aji_tfarraj/features/on_site/domain/on_site_models.dart';
import 'package:aji_tfarraj/features/return_points/domain/return_point_option.dart';
import 'package:aji_tfarraj/features/return_points/presentation/return_point_choice.dart';
import 'package:aji_tfarraj/features/profile/data/profile_repository.dart'
    show citiesProvider;
import 'package:aji_tfarraj/features/profile/presentation/face_capture_screen.dart';

/// Inscription sur place — door staff open a real account for someone who
/// turned up without booking, and check them in on the spot.
///
/// Two phases:
///  1. **Session** — episode + chargé public, chosen once and kept, because
///     staff register a queue of people onto the same episode.
///  2. **Person** — photo → identity → location, then the credentials to read
///     out. "Personne suivante" clears the person but keeps the session.
class OnSiteRegistrationScreen extends ConsumerStatefulWidget {
  const OnSiteRegistrationScreen({super.key});

  @override
  ConsumerState<OnSiteRegistrationScreen> createState() =>
      _OnSiteRegistrationScreenState();
}

class _OnSiteRegistrationScreenState
    extends ConsumerState<OnSiteRegistrationScreen> {
  // ── Session ──
  OnSiteShow? _show;
  OnSiteEpisode? _episode;
  ChargePublicOption? _chargePublic;
  int _registered = 0;

  // ── Person ──
  int _step = 0;
  String? _photoPath;
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String? _gender;
  DateTime? _birthday;
  String? _cityName;
  String? _district;

  /// Où la navette la dépose. Null est une vraie réponse — beaucoup rentrent
  /// par leurs propres moyens — d'où [_returnAnswered], qui distingue « a dit
  /// non » de « on ne lui a pas demandé ».
  int? _returnPointId;
  bool _returnAnswered = false;

  bool _submitting = false;
  String? _error;

  bool get _sessionOpen => _episode != null;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  // ── Flow ────────────────────────────────────────────────────────────────

  /// Clear the person's fields but keep the session — staff register several
  /// people onto the same episode in a row.
  void _resetPerson() {
    setState(() {
      _step = 0;
      _photoPath = null;
      _firstName.clear();
      _lastName.clear();
      _phone.clear();
      _email.clear();
      _gender = null;
      _birthday = null;
      _cityName = null;
      _district = null;
      _returnPointId = null;
      _returnAnswered = false;
      _error = null;
    });
  }

  /// Les arrêts desservis ce soir-là. Vide : pas de navette, et l'étape du
  /// retour n'existe pas — on ne fait pas taper sur « aucun » pour rien.
  List<ReturnPointOption> get _returnPoints => _episode?.returnPoints ?? const [];

  bool get _hasShuttle => _returnPoints.isNotEmpty;

  /// 3 étapes, 4 quand la navette roule.
  int get _stepCount => _hasShuttle ? 4 : 3;

  int get _lastStep => _stepCount - 1;

  bool _stepValid(int step) {
    switch (step) {
      case 0:
        return _photoPath != null;
      case 1:
        return _firstName.text.trim().isNotEmpty &&
            _lastName.text.trim().isNotEmpty &&
            _gender != null &&
            _birthday != null;
      case 2:
        return _cityName != null && _district != null;
      default:
        // Une réponse explicite, y compris « repart par ses propres moyens » :
        // sans ça, personne ne saura si la question a été posée.
        return _returnAnswered;
    }
  }

  bool get _allStepsValid =>
      List.generate(_stepCount, _stepValid).every((valid) => valid);

  Future<void> _capturePhoto() async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        // Staff photograph the person facing them, so the back camera.
        builder: (_) => const FaceCaptureScreen(preferFrontCamera: false),
      ),
    );
    if (path != null && mounted) {
      setState(() {
        _photoPath = path;
        _error = null;
      });
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: ref.read(stringsProvider).onSiteBirthday,
    );
    if (picked != null && mounted) setState(() => _birthday = picked);
  }

  Future<void> _submit() async {
    final s = ref.read(stringsProvider);
    if (!_allStepsValid) {
      setState(() => _error = s.onSiteRequiredFields);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await ref.read(onSiteRepositoryProvider).register(
            episodeId: _episode!.id,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            gender: _gender!,
            birthday: _birthday!,
            cityName: _cityName!,
            district: _district!,
            photoPath: _photoPath!,
            chargePublicId: _chargePublic?.id,
            returnPointId: _returnPointId,
            phoneNumber: _phone.text.trim(),
            email: _email.text.trim(),
          );

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _registered++;
      });
      await _showResult(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        // Surface the server's own wording — it explains *why* (duplicate
        // phone, district from another city…), which staff can act on.
        _error = e is ApiException ? e.message : s.onSiteGenericError;
      });
    }
  }

  Future<void> _showResult(OnSiteRegistrationResult result) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => _ResultSheet(result: result),
    );
    if (mounted) _resetPerson();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(s.onSiteTitle, style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        actions: [
          if (_sessionOpen)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Text(
                  s.onSiteRegisteredCount(_registered),
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _sessionOpen ? _buildPerson(s) : _buildSessionPicker(s),
      ),
    );
  }

  // ── Phase 1: session ────────────────────────────────────────────────────

  Widget _buildSessionPicker(dynamic s) {
    final episodesAsync = ref.watch(onSiteEpisodesProvider);

    return episodesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorBox(
        message: e is ApiException ? e.message : s.onSiteGenericError,
        onRetry: () => ref.invalidate(onSiteEpisodesProvider),
      ),
      data: (shows) {
        if (shows.isEmpty) {
          return _ErrorBox(
            message: s.onSiteNoEpisodes,
            onRetry: () => ref.invalidate(onSiteEpisodesProvider),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(s.onSiteSubtitle,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            Text(s.onSiteChooseEpisode, style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            for (final show in shows) ...[
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(show.title,
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.textMuted)),
              ),
              for (final ep in show.episodes)
                _EpisodeTile(
                  show: show,
                  episode: ep,
                  selected: _episode?.id == ep.id,
                  onTap: () => setState(() {
                    _show = show;
                    _episode = ep;
                  }),
                ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(s.onSiteChooseChargePublic, style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            _ChargePublicPicker(
              selected: _chargePublic,
              onChanged: (cp) => setState(() => _chargePublic = cp),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: FilledButton(
                onPressed: _episode == null ? null : () => setState(() {}),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child:
                    Text(s.onSiteStartSession, style: AppTypography.buttonLarge),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Phase 2: the person ─────────────────────────────────────────────────

  Widget _buildPerson(dynamic s) {
    final stepLabels = [
      s.onSiteStepPhoto,
      s.onSiteStepIdentity,
      s.onSiteStepLocation,
      if (_hasShuttle) s.onSiteStepReturn,
    ];

    return Column(
      children: [
        _SessionBar(
          show: _show,
          episode: _episode,
          chargePublic: _chargePublic,
          label: s.onSiteChangeSession,
          noChargePublicLabel: s.onSiteNoChargePublic,
          onChange: () => setState(() {
            _episode = null;
            _show = null;
          }),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(stepLabels[_step], style: AppTypography.h4),
              Text(s.onSiteStepCounter(_step + 1, _stepCount),
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: switch (_step) {
              0 => _buildPhotoStep(s),
              1 => _buildIdentityStep(s),
              2 => _buildLocationStep(s),
              _ => _buildReturnStep(s),
            },
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _ErrorBanner(message: _error!),
          ),
        _buildActions(s),
      ],
    );
  }

  /// L'aperçu est plafonné pour que le bouton reste visible sans faire
  /// défiler : à la porte, un bouton qu'il faut chercher est un bouton qui
  /// n'existe pas. Le cadre lui-même ouvre l'appareil photo.
  Widget _buildPhotoStep(dynamic s) {
    final preview = MediaQuery.sizeOf(context).height * 0.38;
    final taken = _photoPath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: preview),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Material(
                  color: AppColors.backgroundGrey,
                  child: InkWell(
                    onTap: _capturePhoto,
                    child: taken
                        ? Image.file(File(_photoPath!), fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_camera_outlined,
                                  size: 48, color: AppColors.textMuted),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                s.onSiteTakePhoto,
                                style: AppTypography.labelMedium
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppSpacing.buttonHeight,
          child: FilledButton.icon(
            onPressed: _capturePhoto,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(taken ? s.onSiteRetakePhoto : s.onSiteTakePhoto),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(s.onSitePhotoHint,
            textAlign: TextAlign.center,
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  /// Où la navette la dépose. Posé à la porte parce que c'est là que les plans
  /// changent — et enregistré même quand la réponse est « je me débrouille ».
  Widget _buildReturnStep(dynamic s) {
    final isArabic = ref.watch(localeProvider) == AppLocale.ar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        Text(s.staffReturnPointQuestion, style: AppTypography.h4),
        const SizedBox(height: AppSpacing.xs),
        Text(s.returnPointHint,
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: AppSpacing.lg),
        ReturnPointChoice(
          points: _returnPoints,
          selectedId: _returnAnswered ? _returnPointId : -1,
          isArabic: isArabic,
          noneLabel: s.staffReturnPointNone,
          onChoose: (id) => setState(() {
            _returnPointId = id;
            _returnAnswered = true;
            _error = null;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildIdentityStep(dynamic s) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        _Field(controller: _firstName, label: s.onSiteFirstName),
        _Field(controller: _lastName, label: s.onSiteLastName),
        const SizedBox(height: AppSpacing.sm),
        Text(s.onSiteGender, style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _ChoicePill(
                label: s.onSiteMale,
                selected: _gender == 'male',
                onTap: () => setState(() => _gender = 'male'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ChoicePill(
                label: s.onSiteFemale,
                selected: _gender == 'female',
                onTap: () => setState(() => _gender = 'female'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: _pickBirthday,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: s.onSiteBirthday,
              border: const OutlineInputBorder(),
            ),
            child: Text(
              _birthday == null ? '—' : dateFormat.format(_birthday!),
              style: AppTypography.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Field(
            controller: _phone,
            label: s.onSitePhone,
            keyboardType: TextInputType.phone),
        _Field(
            controller: _email,
            label: s.onSiteEmail,
            keyboardType: TextInputType.emailAddress),
        Text(s.onSiteEmailHint,
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildLocationStep(dynamic s) {
    final citiesAsync = ref.watch(citiesProvider);

    return citiesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _ErrorBox(
        message: s.onSiteGenericError,
        onRetry: () => ref.invalidate(citiesProvider),
      ),
      data: (cities) {
        final city = cities.where((c) => c.name == _cityName).firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _cityName,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: s.onSiteCity,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final c in cities)
                  DropdownMenuItem(value: c.name, child: Text(c.name)),
              ],
              // Changing city invalidates the district under it.
              onChanged: (v) => setState(() {
                _cityName = v;
                _district = null;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _district,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: s.onSiteDistrict,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final d in city?.districts ?? const <String>[])
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: city == null
                  ? null
                  : (v) => setState(() => _district = v),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }

  Widget _buildActions(dynamic s) {
    final isLast = _step == _lastStep;
    final canAdvance = _stepValid(_step) && !_submitting;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            TextButton(
              onPressed:
                  _submitting ? null : () => setState(() => _step -= 1),
              child: Text(s.onSiteBack),
            ),
          Expanded(
            child: SizedBox(
              height: AppSpacing.buttonHeight,
              child: FilledButton(
                onPressed: canAdvance
                    ? (isLast ? _submit : () => setState(() => _step += 1))
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isLast ? s.onSiteSubmit : s.onSiteNext,
                        style: AppTypography.buttonLarge),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Result — the credentials staff read out
// ─────────────────────────────────────────────

class _ResultSheet extends ConsumerWidget {
  const _ResultSheet({required this.result});

  final OnSiteRegistrationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(s.onSiteDoneTitle,
              style: AppTypography.h3, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(s.onSiteDoneSubtitle(result.name),
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          if (result.rewardAmount != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(s.onSiteRewardEarned(result.rewardAmount!),
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.secondary),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.onSiteCredentials, style: AppTypography.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                SelectableText(result.email,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(result.password,
                    style: AppTypography.h3.copyWith(letterSpacing: 2)),
                const SizedBox(height: AppSpacing.sm),
                Text(s.onSiteCredentialsHint,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(
                  text: '${result.email}\n${result.password}'));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.onSiteCopied)),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(s.onSiteCopyCredentials),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.buttonHeight,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(s.onSiteNextPerson,
                  style: AppTypography.buttonLarge),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Small pieces
// ─────────────────────────────────────────────

class _SessionBar extends StatelessWidget {
  const _SessionBar({
    required this.show,
    required this.episode,
    required this.chargePublic,
    required this.label,
    required this.noChargePublicLabel,
    required this.onChange,
  });

  final OnSiteShow? show;
  final OnSiteEpisode? episode;
  final ChargePublicOption? chargePublic;
  final String label;
  final String noChargePublicLabel;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final when = episode?.startsAt;
    final line = [
      show?.title,
      episode?.title,
      if (when != null) DateFormat('dd/MM HH:mm').format(when.toLocal()),
    ].whereType<String>().join(' · ');

    return Container(
      width: double.infinity,
      color: AppColors.backgroundGrey,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line,
                    style: AppTypography.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(chargePublic?.name ?? noChargePublicLabel,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: Text(label)),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.show,
    required this.episode,
    required this.selected,
    required this.onTap,
  });

  final OnSiteShow show;
  final OnSiteEpisode episode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final when = episode.startsAt;
    final seats = episode.availableSeats;

    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 0.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(episode.title ?? show.title,
            style: AppTypography.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            if (when != null) DateFormat('dd/MM · HH:mm').format(when.toLocal()),
            if (episode.studio != null) episode.studio!,
            if (seats != null) '$seats',
          ].join(' · '),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        trailing: selected
            ? Icon(Icons.check_circle, color: AppColors.primary)
            : null,
      ),
    );
  }
}

class _ChargePublicPicker extends ConsumerStatefulWidget {
  const _ChargePublicPicker({required this.selected, required this.onChanged});

  final ChargePublicOption? selected;
  final ValueChanged<ChargePublicOption?> onChanged;

  @override
  ConsumerState<_ChargePublicPicker> createState() =>
      _ChargePublicPickerState();
}

class _ChargePublicPickerState extends ConsumerState<_ChargePublicPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final async = ref.watch(chargePublicSearchProvider(_query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: s.onSiteSearchChargePublic,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Explicit "nobody" so staff can register someone who came alone
        // without leaving the field ambiguous.
        _ChoicePill(
          label: s.onSiteNoChargePublic,
          selected: widget.selected == null,
          onTap: () => widget.onChanged(null),
        ),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (list) => Column(
            children: [
              for (final cp in list)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: _ChoicePill(
                    label: cp.referralCode == null
                        ? cp.name
                        : '${cp.name} · ${cp.referralCode}',
                    selected: widget.selected?.id == cp.id,
                    onTap: () => widget.onChanged(cp),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.10)
              : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTypography.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (selected) Icon(Icons.check, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Text(message,
          style: AppTypography.bodySmall.copyWith(color: AppColors.errorDark)),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: AppColors.textLight),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
