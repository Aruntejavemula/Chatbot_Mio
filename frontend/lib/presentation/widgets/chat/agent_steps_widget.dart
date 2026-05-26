import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/agent_step_model.dart';

class AgentStepsWidget extends StatefulWidget {
  final List<AgentStepModel> steps;
  final bool isRunning;

  const AgentStepsWidget({
    super.key,
    required this.steps,
    required this.isRunning,
  });

  @override
  State<AgentStepsWidget> createState() => _AgentStepsWidgetState();
}

class _AgentStepsWidgetState extends State<AgentStepsWidget> {
  late DateTime _startTime;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    if (widget.isRunning) {
      _startElapsedTimer();
    }
  }

  @override
  void didUpdateWidget(covariant AgentStepsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isRunning && oldWidget.isRunning) {
      _elapsedTimer?.cancel();
      _elapsedTimer = null;
    } else if (widget.isRunning && !oldWidget.isRunning) {
      _startTime = DateTime.now();
      _startElapsedTimer();
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border.all(
            color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 10),
          ...List.generate(widget.steps.length, (index) {
            final step = widget.steps[index];
            final isLast = index == widget.steps.length - 1;
            return _buildTimelineStep(step, isLast, isDark);
          }),
          if (!widget.isRunning) _buildFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        if (widget.isRunning)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.persian),
          )
        else
          const Icon(Icons.check_circle, size: 14, color: AppColors.success),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.isRunning
                ? 'Working on it...'
                : 'Done in ${widget.steps.length} steps',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.isRunning
                  ? AppColors.persian
                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            ),
          ),
        ),
        Text(
          _formatElapsed(_elapsed),
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(AgentStepModel step, bool isLast, bool isDark) {
    final isExecuting = step.status == 'executing';
    final circleColor = isExecuting
        ? AppColors.persian
        : AppColors.success;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline connector column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark
                          ? AppColors.darkBgTertiary
                          : AppColors.bgTertiary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Step content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.tool.replaceAll('_', ' '),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (step.preview != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              step.preview!,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isExecuting)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.persian),
                    )
                  else
                    const Icon(Icons.check, size: 14, color: AppColors.success),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.done_all,
              size: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            'All steps completed in ${_formatElapsed(_elapsed)}',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
