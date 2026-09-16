import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/tutorials/domain/tutorial.dart';

/// Full-screen player for a tutorial clip.
///
/// Starts on its own, pauses on tap, and offers to replay at the end — people
/// often want to see the step they missed.
class TutorialVideoScreen extends ConsumerStatefulWidget {
  const TutorialVideoScreen({
    super.key,
    required this.clip,
    required this.title,
  });

  final TutorialClip clip;
  final String title;

  @override
  ConsumerState<TutorialVideoScreen> createState() =>
      _TutorialVideoScreenState();
}

class _TutorialVideoScreenState extends ConsumerState<TutorialVideoScreen> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(widget.clip.video);
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.play();
    }).catchError((Object _) {
      if (!mounted) return;
      setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final value = _controller.value;
    if (value.isPlaying) {
      _controller.pause();
      return;
    }
    final ended =
        value.duration > Duration.zero && value.position >= value.duration;
    if (ended) _controller.seekTo(Duration.zero);
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final ready = _controller.value.isInitialized;
    final poster = widget.clip.poster;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title,
            style: AppTypography.h4.copyWith(color: Colors.white)),
      ),
      body: Center(
        child: _failed
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 40, color: Colors.white54),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      s.tutorialUnavailable,
                      style: AppTypography.bodyMedium
                          .copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : !ready
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      if (poster != null)
                        Opacity(
                          opacity: 0.5,
                          child: Image.network(
                            poster.toString(),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      const CircularProgressIndicator(
                          color: AppColors.secondary),
                    ],
                  )
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        GestureDetector(
                          onTap: _togglePlay,
                          child: VideoPlayer(_controller),
                        ),
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: AppColors.secondary,
                          ),
                        ),
                        // Play, or replay once the clip has ended.
                        ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: _controller,
                          builder: (_, value, __) {
                            if (value.isPlaying) return const SizedBox.shrink();
                            final ended = value.duration > Duration.zero &&
                                value.position >= value.duration;
                            return Center(
                              child: GestureDetector(
                                onTap: _togglePlay,
                                child: Icon(
                                  ended
                                      ? Icons.replay_circle_filled
                                      : Icons.play_circle_fill,
                                  size: 72,
                                  color: Colors.white70,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
