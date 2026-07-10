import 'package:app_settings/app_settings.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/profile/data/face_detection_service.dart';
import 'package:aji_tfarraj/features/profile/data/image_normalize.dart';

/// Full-screen camera capture with an oval face-guide frame. Front camera,
/// validates a face is present, and pops the captured file path (or null).
class FaceCaptureScreen extends ConsumerStatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  ConsumerState<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends ConsumerState<FaceCaptureScreen>
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
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
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
    final s = ref.read(stringsProvider);
    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      // Bake EXIF orientation (front-camera photos are rotated) so ML Kit can
      // detect the face and the uploaded avatar isn't stored sideways.
      final path = await normalizeCapturedImage(file.path);
      final hasFace =
          await ref.read(faceDetectionServiceProvider).hasFace(path);
      if (!mounted) return;
      if (!hasFace) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.avatarNoFace),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      Navigator.of(context).pop(path);
    } catch (e) {
      debugPrint('[FaceCapture] capture error: $e');
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.avatarCameraError),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
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
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _permissionDenied
                          ? s.cameraPermissionMessage
                          : s.avatarCameraError,
                      style: AppTypography.bodyMedium
                          .copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    if (_permissionDenied) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => AppSettings.openAppSettings(),
                        child: Text(s.openSettings),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else ...[
            // Camera preview, cover-filled.
            _CoverPreview(controller: controller),
            // Dimmed overlay with an oval cutout guide.
            CustomPaint(painter: _OvalFramePainter(), size: Size.infinite),
          ],

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Instruction
          if (ready)
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * 0.12,
              child: Text(
                s.avatarFrameHint,
                textAlign: TextAlign.center,
                style: AppTypography.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Capture button
          if (ready)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 36,
              child: Center(
                child: GestureDetector(
                  onTap: _busy ? null : _capture,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: _busy
                          ? const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: Colors.white),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fills the screen with the camera preview without distortion (BoxFit.cover).
class _CoverPreview extends StatelessWidget {
  final CameraController controller;
  const _CoverPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final preview = controller.value.previewSize;
    if (preview == null) return CameraPreview(controller);
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        // previewSize is landscape-oriented; swap for a portrait screen.
        width: preview.height,
        height: preview.width,
        child: CameraPreview(controller),
      ),
    );
  }
}

/// Dims the screen and cuts out a centered oval "put your face here" guide.
class _OvalFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.72,
      height: size.width * 0.72 * 1.3,
    );

    final scrim = Path()
      ..addRect(Offset.zero & size)
      ..addOval(oval)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.55));

    canvas.drawOval(
      oval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.secondary,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
