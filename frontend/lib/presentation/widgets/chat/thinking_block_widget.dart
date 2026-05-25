import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/animations.dart';

class ThinkingBlockWidget extends StatefulWidget {
  final String thinkingContent;
  final bool isStreaming;

  const ThinkingBlockWidget({
    super.key,
    required this.thinkingContent,
    required this.isStreaming,
  });

  @override
  State<ThinkingBlockWidget> createState() => _ThinkingBlockWidgetState();
}

class _ThinkingBlockWidgetState extends State<ThinkingBlockWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isStreaming) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ThinkingBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !oldWidget.isStreaming) {
      _rotationController.repeat();
    } else if (!widget.isStreaming && oldWidget.isStreaming) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;
    final borderColor =
        isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textMuted),
          _buildCollapsibleContent(isDark, borderColor, textMuted),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textMuted) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            _buildThinkingIcon(textMuted),
            const SizedBox(width: 8),
            Text(
              widget.isStreaming ? 'Thinking...' : 'Reasoning',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: textMuted,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: MioAnimations.fast,
              child: Icon(
                Icons.expand_more,
                size: 18,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingIcon(Color textMuted) {
    if (widget.isStreaming) {
      return AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * pi,
            child: Icon(
              Icons.sync,
              size: 16,
              color: textMuted,
            ),
          );
        },
      );
    }
    return Icon(
      Icons.psychology_outlined,
      size: 16,
      color: textMuted,
    );
  }

  Widget _buildCollapsibleContent(
      bool isDark, Color borderColor, Color textMuted) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: MioAnimations.curve,
      alignment: Alignment.topCenter,
      child: _isExpanded
          ? Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: SelectableText(
                widget.thinkingContent,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
