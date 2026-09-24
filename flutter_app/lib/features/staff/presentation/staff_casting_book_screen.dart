import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_models.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';
import 'package:aji_tfarraj/features/casting/presentation/pose_capture_screen.dart'
    show poseCopy;
import 'package:aji_tfarraj/features/casting/presentation/pose_guide_sheet.dart';
import 'package:aji_tfarraj/features/staff/data/staff_casting_repository.dart';

/// Le book d'un membre, photographié par l'équipe.
///
/// Une case par pose : ce qui est déjà pris, ce qui manque, et le bouton pour
/// photographier. Le guide de la pose s'ouvre avant la caméra, exactement
/// comme pour le membre — c'est le staff qui tient l'appareil, pas qui pose.
class StaffCastingBookScreen extends ConsumerStatefulWidget {
  const StaffCastingBookScreen({super.key, required this.member});

  final CastingMember member;

  @override
  ConsumerState<StaffCastingBookScreen> createState() =>
      _StaffCastingBookScreenState();
}

class _StaffCastingBookScreenState
    extends ConsumerState<StaffCastingBookScreen> {
  /// La pose en cours d'envoi, s'il y en a une.
  CastingPose? _uploading;

  Future<void> _takePhoto(CastingPose pose) async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);

    // Plus grand que pour un membre : on photographie justement parce que son
    // téléphone ne suit pas, et ces clichés-là sont regardés par un directeur
    // de casting.
    final path = await showPoseGuide(context, ref, pose: pose, maxSide: 1600);
    if (path == null || !mounted) return;

    setState(() => _uploading = pose);
    try {
      await ref.read(staffCastingRepositoryProvider).uploadPhoto(
            memberId: widget.member.id,
            pose: pose,
            photoPath: path,
          );
      ref.invalidate(staffCastingBookProvider(widget.member.id));
      // La liste des membres affiche l'avancement du book : elle est fausse
      // dès qu'on a photographié.
      ref.invalidate(castingMembersProvider);
    } on ApiException catch (e) {
      messenger.showSnackBar(
        // Le serveur explique pourquoi (mineur, pose retirée) : mieux vaut
        // son message que le nôtre.
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(s.staffCastingUploadError)));
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final book = ref.watch(staffCastingBookProvider(widget.member.id));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: Text(widget.member.name)),
      body: book.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorState(
          message: s.staffCastingLoadError,
          onRetry: () =>
              ref.invalidate(staffCastingBookProvider(widget.member.id)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(s.staffCastingBookHint,
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.lg),
            for (final pose in CastingPose.values) ...[
              _PoseRow(
                pose: pose,
                photo: data.photoFor(pose),
                busy: _uploading == pose,
                // Une seule à la fois : la caméra et la lecture de posture
                // sont ce que le téléphone fait de plus lourd.
                enabled: _uploading == null,
                label: poseCopy(s.casting, pose).label,
                takeLabel: s.casting.bookTake,
                retakeLabel: s.staffCastingRetake,
                onTake: () => _takePhoto(pose),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _PoseRow extends StatelessWidget {
  const _PoseRow({
    required this.pose,
    required this.photo,
    required this.busy,
    required this.enabled,
    required this.label,
    required this.takeLabel,
    required this.retakeLabel,
    required this.onTake,
  });

  final CastingPose pose;
  final CastingPhoto? photo;
  final bool busy;
  final bool enabled;
  final String label;
  final String takeLabel;
  final String retakeLabel;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final taken = photo != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              width: 54,
              height: 72,
              child: taken
                  ? CachedNetworkImage(
                      imageUrl: photo!.url,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _EmptySlot(),
                    )
                  : _EmptySlot(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTypography.bodyMedium),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      taken ? Icons.check_circle : Icons.circle_outlined,
                      size: 14,
                      color: taken ? AppColors.success : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      taken ? retakeLabel : takeLabel,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton.filled(
                  onPressed: enabled ? onTake : null,
                  icon: const Icon(Icons.photo_camera_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.backgroundGrey,
        child: Icon(Icons.person_outline, color: AppColors.textLight),
      );
}
