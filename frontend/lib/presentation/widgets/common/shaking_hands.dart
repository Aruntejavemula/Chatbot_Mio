import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ShakingHands extends StatefulWidget {
  final double size;
  final bool animate;

  const ShakingHands({
    super.key,
    this.size = 48,
    this.animate = true,
  });

  @override
  State<ShakingHands> createState() => _ShakingHandsState();
}

class _ShakingHandsState extends State<ShakingHands>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.animate) {
      _controller.repeat();
    } else {
      _controller.value = 0.25;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Lottie.asset(
        'assets/animations/shaking_hands.json',
        controller: _controller,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Text(
          '\u{1F91D}',
          style: TextStyle(fontSize: widget.size * 0.7),
        ),
      ),
    );
  }
}
