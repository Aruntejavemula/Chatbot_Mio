import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/animations.dart';

/// A premium empty-state placeholder: a gently "breathing" icon badge with a
/// staggered fade-in title and subtitle, plus an optional action button.
class AnimatedEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.color = AppColors.persian,
  });

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? const Color(0xFF9B9590) : AppColors.textMuted;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeSlideIn(
            child: AnimatedBuilder(
              animation: _breathe,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_breathe.value);
                return Transform.translate(
                  offset: Offset(0, -4 * t),
                  child: Transform.scale(scale: 1 + 0.04 * t, child: child),
                );
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: isDark ? 0.16 : 0.10),
                ),
                child: Icon(widget.icon, size: 32, color: widget.color),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: textPrimary),
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: textMuted, height: 1.5),
                ),
              ),
            ),
          ],
          if (widget.actionLabel != null && widget.onAction != null) ...[
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 280),
              child: ScaleTap(
                onTap: widget.onAction!,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    widget.actionLabel!,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
