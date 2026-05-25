import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

enum LoadingState { idle, thinking, responding, streaming }

class LoadingIndicator extends StatefulWidget {
  final LoadingState state;
  final String word;
  final String streamingText;
  final VoidCallback? onStop;

  const LoadingIndicator({
    super.key,
    required this.state,
    this.word = '',
    this.streamingText = '',
    this.onStop,
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dot1Controller;
  late AnimationController _dot2Controller;
  late AnimationController _dot3Controller;
  late AnimationController _wordFadeController;
  late AnimationController _cursorController;

  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;
  late Animation<double> _wordFadeAnimation;
  late Animation<Offset> _wordSlideAnimation;

  @override
  void initState() {
    super.initState();

    _dot1Controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dot2Controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dot3Controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _dot1Animation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _dot1Controller, curve: Curves.easeInOut),
    );
    _dot2Animation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _dot2Controller, curve: Curves.easeInOut),
    );
    _dot3Animation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _dot3Controller, curve: Curves.easeInOut),
    );

    _wordFadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _wordFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _wordFadeController, curve: Curves.easeInOut),
    );
    _wordSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _wordFadeController, curve: Curves.easeInOut),
    );

    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _startAnimationsForState(widget.state);
  }

  @override
  void didUpdateWidget(covariant LoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _handleStateChange(oldWidget.state, widget.state);
    }
  }

  void _handleStateChange(LoadingState oldState, LoadingState newState) {
    if (newState == LoadingState.idle) {
      _resetAll();
      return;
    }

    if (newState == LoadingState.thinking ||
        newState == LoadingState.responding) {
      _ensureDotsRunning();
    }

    if (newState == LoadingState.responding &&
        oldState != LoadingState.responding) {
      _wordFadeController.forward(from: 0);
    }

    if (newState == LoadingState.streaming) {
      _cursorController.repeat();
    }
  }

  void _startAnimationsForState(LoadingState state) {
    if (state == LoadingState.thinking || state == LoadingState.responding) {
      _ensureDotsRunning();
      if (state == LoadingState.responding) {
        _wordFadeController.forward(from: 0);
      }
    } else if (state == LoadingState.streaming) {
      _cursorController.repeat();
    }
  }

  void _ensureDotsRunning() {
    if (!_dot1Controller.isAnimating) {
      _dot1Controller.repeat(reverse: true);
    }
    if (!_dot2Controller.isAnimating) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_dot2Controller.isAnimating) {
          _dot2Controller.repeat(reverse: true);
        }
      });
    }
    if (!_dot3Controller.isAnimating) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && !_dot3Controller.isAnimating) {
          _dot3Controller.repeat(reverse: true);
        }
      });
    }
  }

  void _resetAll() {
    _dot1Controller.reset();
    _dot2Controller.reset();
    _dot3Controller.reset();
    _wordFadeController.reset();
    _cursorController.reset();
  }

  @override
  void dispose() {
    _dot1Controller.dispose();
    _dot2Controller.dispose();
    _dot3Controller.dispose();
    _wordFadeController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state == LoadingState.idle) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _buildContent(textColor, mutedColor),
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor, Color mutedColor) {
    switch (widget.state) {
      case LoadingState.idle:
        return const SizedBox.shrink();
      case LoadingState.thinking:
        return _buildDotsRow();
      case LoadingState.responding:
        return _buildRespondingContent(mutedColor);
      case LoadingState.streaming:
        return _buildStreamingContent(textColor, mutedColor);
    }
  }

  Widget _buildDotsRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _dot1Animation,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _dot1Animation.value),
            child: child,
          ),
          child: _buildDot(),
        ),
        const SizedBox(width: 6),
        AnimatedBuilder(
          animation: _dot2Animation,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _dot2Animation.value),
            child: child,
          ),
          child: _buildDot(),
        ),
        const SizedBox(width: 6),
        AnimatedBuilder(
          animation: _dot3Animation,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _dot3Animation.value),
            child: child,
          ),
          child: _buildDot(),
        ),
      ],
    );
  }

  Widget _buildDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.persian,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildRespondingContent(Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _wordFadeAnimation,
          child: SlideTransition(
            position: _wordSlideAnimation,
            child: Text(
              '${widget.word}...',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: mutedColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildDotsRow(),
      ],
    );
  }

  Widget _buildStreamingContent(Color textColor, Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.streamingText.isNotEmpty)
          SelectableText(
            widget.streamingText,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: textColor,
              height: 1.5,
            ),
          ),
        AnimatedBuilder(
          animation: _cursorController,
          builder: (_, __) => Opacity(
            opacity: _cursorController.value < 0.5 ? 1.0 : 0.0,
            child: const Text(
              '\u258B',
              style: TextStyle(
                color: AppColors.persian,
                fontSize: 15,
              ),
            ),
          ),
        ),
        if (widget.onStop != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: widget.onStop,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stop_circle_outlined,
                  size: 14,
                  color: mutedColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Stop generating',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
