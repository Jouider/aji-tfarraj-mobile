import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/image_viewer.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/casting/data/casting_repository.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_models.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';
import 'package:aji_tfarraj/features/casting/presentation/pose_capture_screen.dart';
import 'package:aji_tfarraj/features/casting/presentation/pose_guide_sheet.dart';

/// The member's own book: five slots, always the same five.
class CastingBookScreen extends ConsumerStatefulWidget {
  const CastingBookScreen({super.key});

  @override
  ConsumerState<CastingBookScreen> createState() => _CastingBookScreenState();
}

class _CastingBookScreenState extends ConsumerState<CastingBookScreen> {
  CastingPose? _uploading;

  Future<void> _takePhoto(CastingPose pose) async {
    final path = await showPoseGuide(context, ref, pose: pose);
    if (path == null || !mounted) return;

    setState(() => _uploading = pose);
    try {
      await ref
          .read(castingRepositoryProvider)
          .uploadPhoto(pose: pose, photoPath: path);
      ref.invalidate(castingBookProvider);
    } catch (e) {
      if (mounted) _toast(e is ApiException ? e.message : ref.read(stringsProvider).casting.photoError);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _deletePhoto(CastingPose pose) async {
    setState(() => _uploading = pose);
    try {
      await ref.read(castingRepositoryProvider).deletePhoto(pose);
      ref.invalidate(castingBookProvider);
    } catch (e) {
      if (mounted) _toast(e is ApiException ? e.message : ref.read(stringsProvider).casting.photoError);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final book = ref.watch(castingBookProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(title: Text(s.casting.bookTitle, style: AppTypography.h3)),
      body: book.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _BookError(error: e),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(castingBookProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
                AppSpacing.lg, AppSpacing.xxl),
            children: [
              _Intro(text: s.casting.bookIntro),
              const SizedBox(height: AppSpacing.md),
              _RulesCard(title: s.casting.rulesTitle, rules: s.casting.rules),
              const SizedBox(height: AppSpacing.lg),
              _Progress(book: data, s: s),
              const SizedBox(height: AppSpacing.md),

              // Required poses first: they are what stands between this book
              // and being able to apply at all.
              for (final pose in CastingPose.values)
                _PoseSlot(
                  pose: pose,
                  photo: data.photoFor(pose),
                  busy: _uploading == pose,
                  onTake: () => _takePhoto(pose),
                  onDelete: () => _deletePhoto(pose),
                ),

              const SizedBox(height: AppSpacing.lg),
              _Measurements(book: data),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pieces ──────────────────────────────────────────────────────────────────

class _Intro extends StatelessWidget {
  const _Intro({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted));
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.title, required this.rules});

  final String title;
  final List<String> rules;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final rule in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 8),
                    child: SizedBox(
                      width: 4,
                      height: 4,
                      child: DecoratedBox(decoration: BoxDecoration(
                        color: AppColors.secondary, shape: BoxShape.circle)),
                    ),
                  ),
                  Expanded(
                    child: Text(rule,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.book, required this.s});

  final CastingBook book;
  final dynamic s;

  @override
  Widget build(BuildContext context) {
    final complete = book.isComplete;
    final missing = book.missingPoses.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: complete
            ? AppColors.successLight
            : AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(complete ? Icons.check_circle : Icons.photo_camera_outlined,
              color: complete ? AppColors.success : AppColors.secondary,
              size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              complete
                  ? s.casting.bookComplete
                  : s.casting.bookMissing.replaceFirst('%d', '$missing'),
              style: AppTypography.bodyMedium.copyWith(
                color: complete ? AppColors.successDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One slot. Filled or empty, it is always shown: the empty ones are the
/// instruction, and hiding them would make the book look finished.
class _PoseSlot extends ConsumerWidget {
  const _PoseSlot({
    required this.pose,
    required this.photo,
    required this.busy,
    required this.onTake,
    required this.onDelete,
  });

  final CastingPose pose;
  final CastingPhoto? photo;
  final bool busy;
  final VoidCallback onTake;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final copy = poseCopy(s.casting, pose);
    final url = photo?.url;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: url == null && pose.isRequired
              ? AppColors.secondary.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: url == null
                ? onTake
                : () => showFullScreenImage(context,
                    imageUrl: url, heroTag: avatarHeroTag(url)),
            child: Container(
              width: 64,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              clipBehavior: Clip.antiAlias,
              child: busy
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : url != null
                      ? Hero(
                          tag: avatarHeroTag(url),
                          child: Image.network(url,
                              fit: BoxFit.cover, cacheWidth: 256),
                        )
                      : Icon(Icons.add_a_photo_outlined,
                          color: AppColors.textLight, size: 22),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(copy.label,
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                    if (pose.isRequired && url == null)
                      Text(s.casting.bookRequired,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.secondary)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(copy.hint,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    TextButton(
                      onPressed: busy ? null : onTake,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        url == null ? s.casting.bookTake : s.casting.bookRetake,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.secondary),
                      ),
                    ),
                    if (url != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      TextButton(
                        onPressed: busy ? null : onDelete,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(s.casting.bookDelete,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.error)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Measurements. Never blocking — a director calls someone in on their photos,
/// not on numbers with no face attached.
class _Measurements extends ConsumerStatefulWidget {
  const _Measurements({required this.book});

  final CastingBook book;

  @override
  ConsumerState<_Measurements> createState() => _MeasurementsState();
}

class _MeasurementsState extends ConsumerState<_Measurements> {
  late final TextEditingController _height =
      TextEditingController(text: widget.book.heightCm?.toString() ?? '');
  late final TextEditingController _weight =
      TextEditingController(text: widget.book.weightKg?.toString() ?? '');
  late final TextEditingController _clothing =
      TextEditingController(text: widget.book.clothingSize ?? '');
  late final TextEditingController _shoe =
      TextEditingController(text: widget.book.shoeSize?.toString() ?? '');

  bool _saving = false;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _clothing.dispose();
    _shoe.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(stringsProvider);
    setState(() => _saving = true);
    try {
      await ref.read(castingRepositoryProvider).saveMeasurements(
            heightCm: int.tryParse(_height.text.trim()),
            weightKg: int.tryParse(_weight.text.trim()),
            clothingSize:
                _clothing.text.trim().isEmpty ? null : _clothing.text.trim(),
            shoeSize: int.tryParse(_shoe.text.trim()),
          );
      ref.invalidate(castingBookProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.casting.saved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : s.casting.loadError),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    Widget field(TextEditingController c, String label, {bool numeric = true}) =>
        Expanded(
          child: TextField(
            controller: c,
            keyboardType: numeric ? TextInputType.number : TextInputType.text,
            inputFormatters:
                numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.casting.measurementsTitle, style: AppTypography.labelMedium),
          const SizedBox(height: 2),
          Text(s.casting.measurementsIntro,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            field(_height, s.casting.height),
            const SizedBox(width: AppSpacing.sm),
            field(_weight, s.casting.weight),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            field(_clothing, s.casting.clothingSize, numeric: false),
            const SizedBox(width: AppSpacing.sm),
            field(_shoe, s.casting.shoeSize),
          ]),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(s.casting.save),
            ),
          ),
        ],
      ),
    );
  }
}

/// Not eligible is not an error: it is something the person may be able to fix.
class _BookError extends ConsumerWidget {
  const _BookError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final code = error is ApiException ? (error as ApiException).code : null;

    return switch (code) {
      'BIRTHDAY_REQUIRED' => EmptyState(
          icon: Icons.cake_outlined,
          title: s.casting.birthdayRequired,
          actionText: s.casting.completeProfile,
          onAction: () => Navigator.of(context).pop(),
        ),
      'MINOR_NOT_ELIGIBLE' => EmptyState(
          icon: Icons.lock_outline,
          title: s.casting.adultsOnly,
        ),
      _ => ErrorState(
          message: s.casting.loadError,
          retryText: s.retry,
          onRetry: () => ref.invalidate(castingBookProvider),
        ),
    };
  }
}
