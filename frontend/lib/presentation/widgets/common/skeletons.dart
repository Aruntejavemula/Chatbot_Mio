import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Warm-toned shimmer skeletons used as loading placeholders across the app.
///
/// Built on the `shimmer` package so the placeholders animate with a smooth
/// left-to-right sheen instead of a bare spinner.
class MioSkeleton {
  MioSkeleton._();

  static Color _base(bool isDark) =>
      isDark ? const Color(0xFF26241F) : const Color(0xFFEAE6DF);
  static Color _highlight(bool isDark) =>
      isDark ? const Color(0xFF34312A) : const Color(0xFFF6F3EE);

  /// A single shimmering rounded box.
  static Widget box({
    required bool isDark,
    double? width,
    double height = 14,
    double radius = 8,
  }) {
    return Shimmer.fromColors(
      baseColor: _base(isDark),
      highlightColor: _highlight(isDark),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _base(isDark),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  /// A card-shaped placeholder mimicking a project / chat card.
  static Widget card({required bool isDark, double height = 96}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C18) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2823) : const Color(0xFFE2DDD6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          box(isDark: isDark, width: 140, height: 16),
          const SizedBox(height: 12),
          box(isDark: isDark, width: double.infinity, height: 10),
          const SizedBox(height: 8),
          box(isDark: isDark, width: 200, height: 10),
        ],
      ),
    );
  }

  /// A grid of card skeletons for project-style layouts.
  static Widget cardGrid({
    required bool isDark,
    int count = 4,
    int crossAxisCount = 1,
    double childAspectRatio = 2.5,
  }) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: count,
      itemBuilder: (_, __) => card(isDark: isDark),
    );
  }

  /// A vertical list of row skeletons for chat-style lists.
  static Widget list({required bool isDark, int count = 6}) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Row(
        children: [
          box(isDark: isDark, width: 40, height: 40, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(isDark: isDark, width: 180, height: 14),
                const SizedBox(height: 8),
                box(isDark: isDark, width: 120, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
