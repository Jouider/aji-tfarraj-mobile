import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/image_viewer.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/profile/presentation/face_capture_screen.dart';
import 'package:aji_tfarraj/features/staff/data/staff_repository.dart';
import 'package:aji_tfarraj/features/staff/domain/ticket_preview.dart';
import 'package:aji_tfarraj/features/staff/presentation/return_point_picker.dart';

/// What the scanner sees after scanning, before admitting anyone.
///
/// The photo is the point: it is here so the person at the door can be compared
/// with the account, big enough to actually recognise a face, and replaceable on
/// the spot when it is useless.
class TicketPreviewView extends ConsumerStatefulWidget {
  const TicketPreviewView({
    super.key,
    required this.preview,
    required this.onCancel,
  });

  final TicketPreview preview;
  final VoidCallback onCancel;

  @override
  ConsumerState<TicketPreviewView> createState() => _TicketPreviewViewState();
}

class _TicketPreviewViewState extends ConsumerState<TicketPreviewView> {
  bool _uploadingPhoto = false;
  String? _photoError;
  bool _savingReturnPoint = false;
  String? _returnPointError;

  /// Whether the drop-off question has actually been put to this person.
  ///
  /// `chosenReturnPointId == null` cannot answer this on its own: it means both
  /// "said they would make their own way" and "nobody asked yet". Conflating
  /// the two is how somebody ends up counted as needing no lift, and left
  /// standing at the studio.
  late bool _returnPointAnswered;

  @override
  void initState() {
    super.initState();
    // An answer given on an earlier scan still counts as asked.
    _returnPointAnswered = widget.preview.chosenReturnPointId != null;
  }

  Future<void> _chooseReturnPoint(int? pointId) async {
    setState(() {
      _savingReturnPoint = true;
      _returnPointError = null;
    });

    try {
      await ref.read(staffCheckInProvider.notifier).setReturnPoint(pointId);
      // Including "makes their own way": the point is that it was asked.
      if (mounted) setState(() => _returnPointAnswered = true);
    } catch (e) {
      if (mounted) {
        setState(() => _returnPointError = e is ApiException
            ? e.message
            : ref.read(stringsProvider).staffReturnPointSaveError);
      }
    } finally {
      if (mounted) setState(() => _savingReturnPoint = false);
    }
  }

  Future<void> _replacePhoto() async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        // Staff photograph the person facing them, so the back camera.
        builder: (_) => const FaceCaptureScreen(preferFrontCamera: false),
      ),
    );
    if (path == null || !mounted) return;

    setState(() {
      _uploadingPhoto = true;
      _photoError = null;
    });

    try {
      await ref.read(staffCheckInProvider.notifier).replacePhoto(path);
    } catch (e) {
      if (mounted) {
        // The server explains why (locked avatar, not at the door) — that is
        // actionable, a generic failure is not.
        setState(() =>
            _photoError = e is ApiException ? e.message : 'Envoi impossible.');
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    // Read the live copy: replacing the photo updates it under us.
    final preview = ref.watch(staffCheckInProvider).preview ?? widget.preview;
    final loading =
        ref.watch(staffCheckInProvider).status == StaffCheckInStatus.loading;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _StatusBanner(preview: preview),
                  const SizedBox(height: AppSpacing.lg),
                  _AttendeePhoto(
                    preview: preview,
                    uploading: _uploadingPhoto,
                    onReplace: preview.canReplacePhoto ? _replacePhoto : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    preview.attendeeName,
                    style: AppTypography.h2.copyWith(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  if (preview.isMinor) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _Pill(
                      label: 'Mineur (-18 ans)',
                      color: AppColors.error,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                  if (_photoError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(_photoError!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.errorDark),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _DetailsCard(preview: preview),
                  // Only when a shuttle actually runs tonight: an empty list
                  // means no vehicle, so the question would be meaningless.
                  if (preview.asksReturnPoint) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ReturnPointPicker(
                      points: preview.returnPoints,
                      chosenId: preview.chosenReturnPointId,
                      saving: _savingReturnPoint,
                      answered: _returnPointAnswered,
                      error: _returnPointError,
                      onChoose: _chooseReturnPoint,
                    ),
                  ],
                ],
              ),
            ),
          ),
          _Actions(
            preview: preview,
            loading: loading,
            // A shuttle runs tonight and nobody has asked this person where
            // they are going: validating now would file them under "makes
            // their own way" and take their seat off the bus.
            blockedReason: preview.asksReturnPoint && !_returnPointAnswered
                ? s.staffReturnPointRequired
                : null,
            onCancel: widget.onCancel,
            onConfirm: () =>
                ref.read(staffCheckInProvider.notifier).confirmPreview(),
            confirmLabel: s.staffValidateEntry,
            cancelLabel: s.staffScanAnother,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.preview});

  final TicketPreview preview;

  @override
  Widget build(BuildContext context) {
    final (String text, Color color, IconData icon) = switch (preview.status) {
      TicketPreviewStatus.canCheckIn => (
          'Billet valide — vérifiez le visage',
          AppColors.success,
          Icons.check_circle_outline,
        ),
      TicketPreviewStatus.alreadyCheckedIn => (
          preview.checkedInAt != null
              ? 'Déjà pointé à ${DateFormat('HH:mm').format(preview.checkedInAt!)}'
              : 'Billet déjà utilisé',
          AppColors.warning,
          Icons.history,
        ),
      TicketPreviewStatus.notApproved => (
          'Réservation non approuvée',
          AppColors.error,
          Icons.block,
        ),
      TicketPreviewStatus.wrongDate => (
          switch (preview.reason) {
            WrongDateReason.future => "Billet pour une date à venir",
            WrongDateReason.past => 'Billet pour un tournage déjà passé',
            WrongDateReason.undated => "Cet épisode n'a pas de date",
            _ => 'Mauvaise date',
          },
          AppColors.error,
          Icons.event_busy,
        ),
      TicketPreviewStatus.unknown => (
          'Billet non reconnu — vérifiez avec un responsable',
          AppColors.error,
          Icons.help_outline,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _AttendeePhoto extends StatelessWidget {
  const _AttendeePhoto({
    required this.preview,
    required this.uploading,
    this.onReplace,
  });

  final TicketPreview preview;
  final bool uploading;
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    final url = preview.attendeeAvatarUrl;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          // Even 160px can be too small to be sure — let staff enlarge it.
          onTap: url == null
              ? null
              : () => showFullScreenImage(context,
                  imageUrl: url, heroTag: avatarHeroTag(url)),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: ClipOval(
              child: uploading
                  ? Container(
                      color: AppColors.backgroundGrey,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : url == null
                      ? const AvatarFallbackIcon(size: 64)
                      : Hero(
                          tag: avatarHeroTag(url),
                          child: Image.network(url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const AvatarFallbackIcon(size: 64)),
                        ),
            ),
          ),
        ),
        if (onReplace != null && !uploading)
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onReplace,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Icon(Icons.photo_camera, color: Colors.white, size: 22),
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.preview});

  final TicketPreview preview;

  @override
  Widget build(BuildContext context) {
    final when = preview.episodeStartsAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          _Row(label: 'Places', value: '${preview.seats}'),
          if (preview.showTitle.isNotEmpty)
            _Row(label: 'Émission', value: preview.showTitle),
          if (preview.episodeTitle != null)
            _Row(label: 'Épisode', value: preview.episodeTitle!),
          if (when != null)
            _Row(
                label: 'Date',
                value: DateFormat('dd/MM/yyyy · HH:mm').format(when)),
          if (preview.studio != null)
            _Row(label: 'Studio', value: preview.studio!),
          if (preview.attendeePhone != null)
            _Row(label: 'Téléphone', value: preview.attendeePhone!),
          _Row(label: 'Billet', value: preview.ticketCode),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style: AppTypography.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.preview,
    required this.loading,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
    required this.cancelLabel,
    this.blockedReason,
  });

  final TicketPreview preview;
  final bool loading;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final String cancelLabel;

  /// Why validating is not available yet, when a step is still outstanding.
  /// Null means nothing is in the way.
  final String? blockedReason;

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A refused ticket gets no button at all — a dead button invites
          // tapping it anyway. An outstanding STEP is different: there is
          // something to do, so the button stays and says what.
          if (preview.canAdmit && blockedReason != null) ...[
            Row(
              children: [
                Icon(Icons.arrow_upward,
                    size: 15, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(blockedReason!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.secondary)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (preview.canAdmit)
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: FilledButton.icon(
                onPressed:
                    loading || blockedReason != null ? null : onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(confirmLabel, style: AppTypography.buttonLarge),
              ),
            ),
          if (preview.canAdmit) const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeight,
            child: OutlinedButton(
              onPressed: loading ? null : onCancel,
              child: Text(cancelLabel),
            ),
          ),
        ],
      ),
    );
  }
}


/// Where the shuttle drops this person after the recording.
///
/// Optional on purpose: "repart par ses propres moyens" is a real answer, and
/// forcing a stop would fill the transport figures with noise.
