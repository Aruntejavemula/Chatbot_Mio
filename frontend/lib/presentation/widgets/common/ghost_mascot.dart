import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class PenguinMascot extends StatefulWidget {
  final double size;
  final bool animate;

  const PenguinMascot({
    super.key,
    this.size = 48,
    this.animate = true,
  });

  @override
  State<PenguinMascot> createState() => _PenguinMascotState();
}

class _PenguinMascotState extends State<PenguinMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget mascotImage = Image.asset(
      'assets/images/mascot.png',
      fit: BoxFit.contain,
      width: widget.size,
      height: widget.size,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if image not found
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '\u{1F427}',
              style: TextStyle(fontSize: widget.size * 0.5),
            ),
          ),
        );
      },
    );

    Widget content;
    if (isDark) {
      content = Container(
        width: widget.size,
        height: widget.size,
        padding: EdgeInsets.all(widget.size * 0.1),
        decoration: BoxDecoration(
          color: AppColors.darkBgSecondary,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.darkBorderDefault,
            width: 1,
          ),
        ),
        child: ClipOval(child: mascotImage),
      );
    } else {
      content = SizedBox(
        width: widget.size,
        height: widget.size,
        child: mascotImage,
      );
    }

    if (!widget.animate) {
      return content;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: content,
    );
  }
}
