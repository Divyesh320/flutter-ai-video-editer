import 'package:flutter/material.dart';

/// Types of skeleton loaders
enum SkeletonType {
  listTile,
  card,
  text,
  avatar,
}

/// Skeleton loader widget for loading states
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.type = SkeletonType.listTile,
    this.width,
    this.height,
  });

  final SkeletonType type;
  final double? width;
  final double? height;

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
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
        return _buildSkeleton(context, _animation.value);
      },
    );
  }

  Widget _buildSkeleton(BuildContext context, double opacity) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;

    switch (widget.type) {
      case SkeletonType.listTile:
        return _buildListTileSkeleton(baseColor, opacity);
      case SkeletonType.card:
        return _buildCardSkeleton(baseColor, opacity);
      case SkeletonType.text:
        return _buildTextSkeleton(baseColor, opacity);
      case SkeletonType.avatar:
        return _buildAvatarSkeleton(baseColor, opacity);
    }
  }

  Widget _buildListTileSkeleton(Color baseColor, double opacity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildShimmerBox(
            baseColor: baseColor,
            opacity: opacity,
            width: 48,
            height: 48,
            borderRadius: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(
                  baseColor: baseColor,
                  opacity: opacity,
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                _buildShimmerBox(
                  baseColor: baseColor,
                  opacity: opacity,
                  width: 150,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSkeleton(Color baseColor, double opacity) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildShimmerBox(
        baseColor: baseColor,
        opacity: opacity,
        width: widget.width ?? double.infinity,
        height: widget.height ?? 120,
        borderRadius: 12,
      ),
    );
  }

  Widget _buildTextSkeleton(Color baseColor, double opacity) {
    return _buildShimmerBox(
      baseColor: baseColor,
      opacity: opacity,
      width: widget.width ?? 100,
      height: widget.height ?? 16,
      borderRadius: 4,
    );
  }

  Widget _buildAvatarSkeleton(Color baseColor, double opacity) {
    final size = widget.width ?? 48;
    return _buildShimmerBox(
      baseColor: baseColor,
      opacity: opacity,
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  Widget _buildShimmerBox({
    required Color baseColor,
    required double opacity,
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
