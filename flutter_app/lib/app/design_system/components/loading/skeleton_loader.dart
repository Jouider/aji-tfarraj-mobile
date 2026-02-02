import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';

/// Skeleton Loader for loading states
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppSpacing.radiusMd,
  });

  /// Text line skeleton
  factory SkeletonLoader.text({
    double width = 100,
    double height = 16,
  }) =>
      SkeletonLoader(
        width: width,
        height: height,
        borderRadius: AppSpacing.radiusSm,
      );

  /// Circle skeleton (for avatars)
  factory SkeletonLoader.circle({double size = 48}) => SkeletonLoader(
        width: size,
        height: size,
        borderRadius: size / 2,
      );

  /// Card skeleton
  factory SkeletonLoader.card({
    double? width,
    double height = 200,
  }) =>
      SkeletonLoader(
        width: width,
        height: height,
        borderRadius: AppSpacing.cardRadius,
      );

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                AppColors.backgroundGrey,
                AppColors.backgroundLight,
                AppColors.backgroundGrey,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for a show card item
class ShowCardSkeleton extends StatelessWidget {
  const ShowCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          SkeletonLoader(
            width: 120,
            height: 120,
            borderRadius: AppSpacing.cardRadius,
          ),
          const SizedBox(width: AppSpacing.md),
          // Text content skeleton
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader.text(width: double.infinity, height: 18),
                  const SizedBox(height: AppSpacing.sm),
                  SkeletonLoader.text(width: 150, height: 14),
                  const SizedBox(height: AppSpacing.sm),
                  SkeletonLoader.text(width: 120, height: 14),
                  const SizedBox(height: AppSpacing.sm),
                  SkeletonLoader.text(width: 100, height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton list for shows loading state
class ShowsListSkeleton extends StatelessWidget {
  final int itemCount;

  const ShowsListSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ShowCardSkeleton(),
    );
  }
}
