import 'package:flutter/material.dart';

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

    Widget image = Image.asset(
      'assets/images/mascot.png',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Text(
        '\u{1F427}',
        style: TextStyle(fontSize: widget.size * 0.7),
      ),
    );

    Widget content;
    if (isDark) {
      content = Container(
        width: widget.size * 1.2,
        height: widget.size * 1.2,
        decoration: const BoxDecoration(
          color: Color(0xFFFAF8F5),
          shape: BoxShape.circle,
        ),
        padding: EdgeInsets.all(widget.size * 0.12),
        child: image,
      );
    } else {
      content = SizedBox(
        width: widget.size,
        height: widget.size,
        child: image,
      );
    }

    if (!widget.animate) return content;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _animation.value),
        child: child,
      ),
      child: content,
    );
  }
}
