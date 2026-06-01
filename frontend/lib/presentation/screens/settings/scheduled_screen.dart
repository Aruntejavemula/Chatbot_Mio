import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/scheduled_task_model.dart';
import '../../../data/services/scheduled_service.dart';
import '../../widgets/common/shaking_hands.dart';
import '../../widgets/scheduled/create_task_sheet.dart';

class ScheduledScreen extends StatefulWidget {
  const ScheduledScreen({super.key});

  @override
  State<ScheduledScreen> createState() => _ScheduledScreenState();
}

class _ScheduledScreenState extends State<ScheduledScreen> {
  final ScheduledService _service = ScheduledService();
  List<ScheduledTaskModel> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _service.getTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTaskSheet(
        onCreated: (task) {
          setState(() => _tasks.insert(0, task));
        },
      ),
    );
  }

  String _scheduleDescription(ScheduledTaskModel task) {
    switch (task.scheduleType) {
      case 'daily':
        return 'Daily at ${task.runTime ?? '09:00'}';
      case 'weekly':
        return 'Weekly on ${task.runDay ?? 'Monday'} at ${task.runTime ?? '09:00'}';
      case 'once':
      default:
        if (task.runAt != null) {
          return 'Once on ${task.runAt!.month}/${task.runAt!.day}/${task.runAt!.year}';
        }
        return 'Once';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'paused':
        return AppColors.warning;
      case 'done':
        return AppColors.persian;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scheduled Tasks',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            onPressed: _showCreateSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.persian))
          : _tasks.isEmpty
              ? _buildEmptyState(isDark)
              : _buildTaskList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ShakingHands(size: AppSizes.mascotSizeMedium),
          const SizedBox(height: 16),
          Text(
            'No scheduled tasks yet',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule tasks to run automatically',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Create Task',
              style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.persian),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingScreen),
      itemCount: _tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return _buildTaskCard(task, isDark);
      },
    );
  }

  Widget _buildTaskCard(ScheduledTaskModel task, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingCard),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
        border: Border.all(
            color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(task.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Text(
                  task.status,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(task.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task.prompt,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule,
                  size: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                _scheduleDescription(task),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
