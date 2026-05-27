import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PenguinMascot extends StatelessWidget {
  final double size;
  final bool animate;

  const PenguinMascot({
    super.key,
    this.size = 48,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/mascot.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      animate: animate,
      repeat: true,
      errorBuilder: (context, error, stack) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFCC5801),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            'M',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
