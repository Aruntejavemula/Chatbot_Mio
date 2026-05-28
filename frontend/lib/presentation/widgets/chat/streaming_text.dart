import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class StreamingText extends StatefulWidget {
  final String text;
  final Color textColor;
  final double fontSize;

  const StreamingText({
    super.key,
    required this.text,
    required this.textColor,
    this.fontSize = 15,
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  int _previousLength = 0;
  int _animatedLength = 0;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
    _previousLength = 0;
    _animatedLength = 0;
  }

  @override
  void didUpdateWidget(covariant StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text.length > _previousLength) {
      final newChars = widget.text.length - _previousLength;
      _previousLength = widget.text.length;
      _animateNewChars(newChars);
    }
  }

  void _animateNewChars(int count) {
    // Batch-reveal new characters with a slight delay for the fade effect
    Future.delayed(const Duration(milliseconds: 16), () {
      if (!mounted) return;
      setState(() {
        _animatedLength = widget.text.length;
      });
    });
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayLength = _animatedLength.clamp(0, widget.text.length);
    final revealedText = widget.text.substring(0, displayLength);
    final pendingText = widget.text.substring(displayLength);

    return Text.rich(
      TextSpan(
        children: [
          // Already revealed text
          TextSpan(
            text: revealedText,
            style: GoogleFonts.dmSans(
              fontSize: widget.fontSize,
              color: widget.textColor,
              height: 1.5,
            ),
          ),
          // Newly arriving text with slight opacity
          if (pendingText.isNotEmpty)
            TextSpan(
              text: pendingText,
              style: GoogleFonts.dmSans(
                fontSize: widget.fontSize,
                color: widget.textColor.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          // Blinking cursor
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: AnimatedBuilder(
              animation: _cursorController,
              builder: (context, child) {
                return Opacity(
                  opacity: _cursorController.value,
                  child: child,
                );
              },
              child: Container(
                width: 2,
                height: widget.fontSize + 2,
                margin: const EdgeInsets.only(left: 1),
                color: AppColors.persian,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dot1;
  late AnimationController _dot2;
  late AnimationController _dot3;

  @override
  void initState() {
    super.initState();

    _dot1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _dot2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _dot3 = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _dot2.repeat(reverse: true);
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _dot3.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _dot1.dispose();
    _dot2.dispose();
    _dot3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(_dot1),
        const SizedBox(width: 4),
        _buildDot(_dot2),
        const SizedBox(width: 4),
        _buildDot(_dot3),
      ],
    );
  }

  Widget _buildDot(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * controller.value),
          child: Opacity(
            opacity: 0.3 + 0.7 * controller.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.persian,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
