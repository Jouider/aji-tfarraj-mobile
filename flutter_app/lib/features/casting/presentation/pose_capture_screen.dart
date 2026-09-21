import 'package:app_settings/app_settings.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/copywriting/casting_copy.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';
import 'package:aji_tfarraj/features/casting/data/body_pose_service.dart';
import 'package:aji_tfarraj/features/casting/domain/pose_check.dart';
import 'package:aji_tfarraj/features/profile/data/face_detection_service.dart';
import 'package:aji_tfarraj/features/profile/data/image_normalize.dart';
import 'package:aji_tfarraj/features/profile/domain/face_check.dart';

/// Camera for one prescribed casting shot, with the frame drawn on screen.
///
/// **Back camera.** Somebody else holds the phone: you cannot photograph
/// yourself full length, and the whole book is judged on framing that a selfie
/// arm cannot produce.
///
/// The guide is not decoration. Told "stand up straight, full length", people
/// crop their own feet; given an outline to fill, they step back. That is the
/// difference between a book that can be compared and one that cannot.
///
/// Pops the captured file path, or null.
class PoseCaptureScreen extends ConsumerStatefulWidget {
  const PoseCaptureScreen({super.key, required this.pose});

  final CastingPose pose;

  @override
  ConsumerState<PoseCaptureScreen> createState() => _PoseCaptureScreenState();
}

class _PoseCaptureScreenState extends ConsumerState<PoseCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _cameraError = false;
  bool _permissionDenied = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      // High, not medium: a full-length shot is judged on the person's face at
      // a fraction of the frame, and medium turns that into mush.
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } on CameraException catch (e) {
      final code = e.code.toLowerCase();
      if (mounted) {
        setState(() {
          _cameraError = true;
          _permissionDenied =
              code.contains('denied') || code.contains('permission');
          _initializing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraError = true;
          _initializing = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_busy || controller == null || !controller.value.isInitialized) return;

    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      // Bake EXIF orientation in, so the shot is not stored sideways.
      final path = await normalizeCapturedImage(file.path);
      if (!mounted) return;

      // Two different strictnesses on purpose: faces are read reliably, so a
      // portrait can be refused; full-length pose reading is not, so a body
      // shot is only ever advised on.
      final accepted = widget.pose.isFullLength
          ? await _checkBody(path)
          : await _checkFace(path);
      if (!mounted) return;

      if (!accepted) {
        setState(() => _busy = false);
        return;
      }
      Navigator.of(context).pop(path);
    } catch (e) {
      debugPrint('[PoseCapture] $e');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(stringsProvider).avatarCameraError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Portraits: the same face check as the profile photo, reliable enough to
  /// refuse — plus a smile for the smiling portrait.
  Future<bool> _checkFace(String path) async {
    final s = ref.read(stringsProvider);
    final verdict = await ref.read(faceDetectionServiceProvider).check(
          path,
          requireSmile: widget.pose == CastingPose.portraitSmile,
        );

    final problem = switch (verdict) {
      FaceCheck.ok => null,
      FaceCheck.noFace => s.avatarNoFace,
      FaceCheck.tooSmall => s.avatarFaceTooSmall,
      FaceCheck.multipleFaces => s.avatarMultipleFaces,
      FaceCheck.notFacing => s.avatarNotFacing,
      FaceCheck.eyesClosed => s.avatarEyesClosed,
      FaceCheck.notSmiling => s.casting.portraitNotSmiling,
    };

    if (problem == null) return true;
    _refuse(problem);
    return false;
  }

  /// Full length: advice the member can override, never a decision — body-pose
  /// reading is unreliable on loose clothing. The one exception is a photo
  /// with nobody in it.
  Future<bool> _checkBody(String path) async {
    final c = ref.read(stringsProvider).casting;
    final verdict =
        await ref.read(bodyPoseServiceProvider).check(path, widget.pose);

    if (verdict == PoseCheck.ok) return true;

    final message = switch (verdict) {
      PoseCheck.ok => '',
      PoseCheck.noPerson => c.poseNoPerson,
      PoseCheck.headCut => c.poseHeadCut,
      PoseCheck.feetCut => c.poseFeetCut,
      PoseCheck.notFacing => c.poseNotFacing,
      PoseCheck.notSideways => c.poseNotSideways,
    };

    if (verdict.blocks) {
      _refuse(message);
      return false;
    }

    if (!mounted) return false;

    // Retaking is the suggested way out, so it is the prominent button; keeping
    // the photo stays one tap away, because the detector can be wrong.
    final keep = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(c.adviceTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(c.adviceKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
            ),
            child: Text(c.bookRetake),
          ),
        ],
      ),
    );

    return keep == true;
  }

  void _refuse(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final copy = poseCopy(s.casting, widget.pose);
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_initializing)
            const Center(
                child: CircularProgressIndicator(color: AppColors.secondary))
          else if (_cameraError || !ready)
            _CameraProblem(
              message: _permissionDenied
                  ? s.cameraPermissionMessage
                  : s.avatarCameraError,
              showSettings: _permissionDenied,
              settingsLabel: s.openSettings,
            )
          else ...[
            _CoverPreview(controller: controller),
            CustomPaint(
              painter: _PoseFramePainter(fullLength: widget.pose.isFullLength),
              size: Size.infinite,
            ),
          ],

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // The pose, and the single line worth reading while in position.
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 56,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.label,
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.secondary)),
                const SizedBox(height: 2),
                Text(copy.hint,
                    style: AppTypography.bodySmall
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ),

          if (ready)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
              child: Center(
                child: GestureDetector(
                  onTap: _busy ? null : _capture,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: _busy ? 0.4 : 1),
                      border: Border.all(color: Colors.white38, width: 4),
                    ),
                    child: _busy
                        ? const Padding(
                            padding: EdgeInsets.all(22),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black54),
                          )
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Picks the instructions for a pose. Kept in one place so a pose added later
/// fails to compile here rather than showing an empty guide at the shoot.
CastingPoseCopy poseCopy(CastingCopy copy, CastingPose pose) =>
    switch (pose) {
      CastingPose.fullFront => copy.fullFront,
      CastingPose.fullProfile => copy.fullProfile,
      CastingPose.portrait => copy.portrait,
      CastingPose.portraitSmile => copy.portraitSmile,
    };

class _CameraProblem extends StatelessWidget {
  const _CameraProblem({
    required this.message,
    required this.showSettings,
    required this.settingsLabel,
  });

  final String message;
  final bool showSettings;
  final String settingsLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                style:
                    AppTypography.bodyMedium.copyWith(color: Colors.white70),
                textAlign: TextAlign.center),
            if (showSettings) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => AppSettings.openAppSettings(),
                child: Text(settingsLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fills the screen with the preview without distorting it.
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.width * controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

/// Dims the frame and cuts out the shape the person should fill.
///
/// Full length is a tall rounded window with head and foot lines: the two
/// mistakes are cropping the feet and standing so far back the face is
/// unreadable, and the lines make both visible before the shutter.
class _PoseFramePainter extends CustomPainter {
  const _PoseFramePainter({required this.fullLength});

  final bool fullLength;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect window = fullLength
        ? Rect.fromCenter(
            center: Offset(size.width / 2, size.height * 0.48),
            // Tall and narrow: a standing person, with room at top and bottom
            // so the guide itself does not encourage cropping.
            width: size.width * 0.52,
            height: size.height * 0.74,
          )
        : Rect.fromCenter(
            center: Offset(size.width / 2, size.height * 0.42),
            width: size.width * 0.68,
            height: size.height * 0.42,
          );

    final shape = RRect.fromRectAndRadius(
      window,
      Radius.circular(fullLength ? 28 : window.width / 2.6),
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(shape),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.secondary.withValues(alpha: 0.9),
    );

    if (!fullLength) return;

    // Head and foot lines — where the top of the head and the feet belong.
    final hint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.45);

    for (final y in [window.top + window.height * 0.08, window.bottom - 12]) {
      canvas.drawLine(
        Offset(window.left + 14, y),
        Offset(window.right - 14, y),
        hint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PoseFramePainter old) =>
      old.fullLength != fullLength;
}
