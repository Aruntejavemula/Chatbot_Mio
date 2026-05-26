import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/scheduled_task_model.dart';
import '../../../data/services/scheduled_service.dart';

class CreateTaskSheet extends StatefulWidget {
  final void Function(ScheduledTaskModel task) onCreated;

  const CreateTaskSheet({super.key, required this.onCreated});

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _nameController = TextEditingController();
  final _promptController = TextEditingController();
  final _service = ScheduledService();

  String _scheduleType = 'once';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedDay = 'Monday';
  bool _isSubmitting = false;

  static const _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _promptController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'title': _nameController.text.trim(),
        'prompt': _promptController.text.trim(),
        'schedule_type': _scheduleType,
        'run_time':
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      };

      if (_scheduleType == 'once') {
        data['run_at'] = _selectedDate.toIso8601String();
      } else if (_scheduleType == 'weekly') {
        data['run_day'] = _selectedDay;
      }

      final task = await _service.createTask(data);
      widget.onCreated(task);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.paddingScreen,
        right: AppSizes.paddingScreen,
        top: 16,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLarge)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'New Scheduled Task',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Task Name',
              hint: 'e.g. Daily summary',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _promptController,
              label: 'Prompt',
              hint: 'What should the agent do?',
              isDark: isDark,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Schedule',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildSegmentedControl(isDark),
            const SizedBox(height: 16),
            _buildScheduleOptions(isDark),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.persian,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Schedule Task',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkInputBg : AppColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkInputBorder
                      : AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkInputBorder
                      : AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkInputFocusBorder
                      : AppColors.inputFocusBorder),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl(bool isDark) {
    final types = ['once', 'daily', 'weekly'];
    final labels = ['Once', 'Daily', 'Weekly'];

    return Row(
      children: List.generate(types.length, (i) {
        final isSelected = _scheduleType == types[i];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _scheduleType = types[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.persian
                    : (isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary),
                borderRadius: BorderRadius.horizontal(
                  left: i == 0
                      ? const Radius.circular(AppSizes.radiusSmall)
                      : Radius.zero,
                  right: i == types.length - 1
                      ? const Radius.circular(AppSizes.radiusSmall)
                      : Radius.zero,
                ),
              ),
              child: Center(
                child: Text(
                  labels[i],
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildScheduleOptions(bool isDark) {
    switch (_scheduleType) {
      case 'daily':
        return _buildTimePicker(isDark);
      case 'weekly':
        return Column(
          children: [
            _buildDayPicker(isDark),
            const SizedBox(height: 12),
            _buildTimePicker(isDark),
          ],
        );
      case 'once':
      default:
        return Column(
          children: [
            _buildDatePicker(isDark),
            const SizedBox(height: 12),
            _buildTimePicker(isDark),
          ],
        );
    }
  }

  Widget _buildDatePicker(bool isDark) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkInputBg : AppColors.inputBg,
          border: Border.all(
              color: isDark ? AppColors.darkInputBorder : AppColors.inputBorder),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                size: 16,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(bool isDark) {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkInputBg : AppColors.inputBg,
          border: Border.all(
              color: isDark ? AppColors.darkInputBorder : AppColors.inputBorder),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time,
                size: 16,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              _selectedTime.format(context),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPicker(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputBg : AppColors.inputBg,
        border: Border.all(
            color: isDark ? AppColors.darkInputBorder : AppColors.inputBorder),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDay,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.darkBgSecondary : AppColors.cardBg,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          items: _weekDays
              .map((day) => DropdownMenuItem(value: day, child: Text(day)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedDay = value);
          },
        ),
      ),
    );
  }
}
