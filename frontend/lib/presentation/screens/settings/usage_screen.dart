import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/repositories/chat_repository.dart';

class UsageScreen extends ConsumerStatefulWidget {
  const UsageScreen({super.key});

  @override
  ConsumerState<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends ConsumerState<UsageScreen> {
  Map<String, Object?>? _usageData;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUsage();
    _refreshTimer = Timer.periodic(
      Duration(seconds: AppConstants.usageRefreshIntervalSeconds),
      (_) => _loadUsage(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsage() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final data = await chatService.getTokenUsage();
      if (mounted) {
        setState(() {
          _usageData = data;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load usage data';
        });
      }
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
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Usage',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState(isDark)
              : _buildContent(isDark),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'An error occurred',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadUsage();
            },
            child: Text(
              'Retry',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.persian,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final fiveHourUsed = _getInt('five_hour_used');
    final fiveHourLimit = _getInt('five_hour_limit', defaultValue: AppConstants.freeTokenCap5Hour);
    final dailyUsed = _getInt('daily_used');
    final dailyLimit = _getInt('daily_limit', defaultValue: AppConstants.basicTokenCapDaily);
    final weeklyUsed = _getInt('weekly_used');
    final weeklyLimit = _getInt('weekly_limit', defaultValue: AppConstants.proTokenCapWeekly);
    final monthlyUsed = _getInt('monthly_used');
    final monthlyLimit = _getInt('monthly_limit', defaultValue: AppConstants.proTokenCapMonthly);
    final estimatedCost = _getDouble('estimated_cost');
    final tokensSaved = _getInt('tokens_saved');
    final currentModel = _getString('current_model', defaultValue: 'GPT-4o');
    final weeklyBreakdown = _getWeeklyBreakdown();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCapCard(
            name: '5-Hour',
            used: fiveHourUsed,
            limit: fiveHourLimit,
            resetLabel: _formatResetTime('five_hour_reset'),
            isDark: isDark,
          ),
          _buildCapCard(
            name: 'Today',
            used: dailyUsed,
            limit: dailyLimit,
            resetLabel: 'tomorrow',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildMilestoneCard(
            isDark: isDark,
            dailyUsed: dailyUsed,
            dailyLimit: dailyLimit,
          ),
          const SizedBox(height: 12),
          _buildCapCard(
            name: 'This Week',
            used: weeklyUsed,
            limit: weeklyLimit,
            resetLabel: 'Monday',
            isDark: isDark,
          ),
          _buildCapCard(
            name: 'This Month',
            used: monthlyUsed,
            limit: monthlyLimit,
            resetLabel: 'on 1st',
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildCostCard(
            isDark: isDark,
            estimatedCost: estimatedCost,
            tokensSaved: tokensSaved,
            currentModel: currentModel,
          ),
          const SizedBox(height: 20),
          _buildBarChart(isDark: isDark, weeklyBreakdown: weeklyBreakdown),
        ],
      ),
    );
  }

  Widget _buildCapCard({
    required String name,
    required int used,
    required int limit,
    required String resetLabel,
    required bool isDark,
  }) {
    final double ratio = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    final Color progressColor = _getProgressColor(ratio);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border.all(
          color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                'Resets $resetLabel',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatNumber(used)} / ${_formatNumber(limit)} tokens',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor:
                  isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostCard({
    required bool isDark,
    required double estimatedCost,
    required int tokensSaved,
    required String currentModel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border.all(
          color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildCostRow(
            label: 'Estimated cost to Mio:',
            value: '~\$${estimatedCost.toStringAsFixed(2)}',
            valueColor:
                isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildCostRow(
            label: 'Tokens saved by caching:',
            value: '~${_formatNumber(tokensSaved)} saved',
            valueColor: AppColors.success,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildCostRow(
            label: 'Current model:',
            value: currentModel,
            valueColor: AppColors.persian,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          Text(
            'We show you exactly what we spend.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow({
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart({
    required bool isDark,
    required List<int> weeklyBreakdown,
  }) {
    const List<String> dayLabels = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final int maxValue =
        weeklyBreakdown.fold<int>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border.all(
          color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final double barHeight = maxValue > 0
                    ? (weeklyBreakdown[index] / maxValue) * 60.0
                    : 0.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: barHeight.clamp(2.0, 60.0),
                      decoration: BoxDecoration(
                        color: AppColors.persian,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppSizes.radiusSmall),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayLabels[index],
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard({
    required bool isDark,
    required int dailyUsed,
    required int dailyLimit,
  }) {
    final double ratio =
        dailyLimit > 0 ? (dailyUsed / dailyLimit).clamp(0.0, 1.0) : 0.0;
    final String milestone = _getMilestoneMessage(ratio);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt,
            size: 16,
            color: AppColors.persian,
          ),
          const SizedBox(width: 8),
          Text(
            milestone,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getMilestoneMessage(double ratio) {
    if (ratio >= 0.75) {
      return 'Almost at limit';
    } else if (ratio >= 0.50) {
      return 'Heavy usage';
    } else if (ratio >= 0.25) {
      return 'Making progress';
    }
    return 'Getting started';
  }

  Color _getProgressColor(double ratio) {
    if (ratio > 0.9) {
      return AppColors.error;
    } else if (ratio >= 0.7) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  int _getInt(String key, {int defaultValue = 0}) {
    final value = _usageData?[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return defaultValue;
  }

  double _getDouble(String key, {double defaultValue = 0.0}) {
    final value = _usageData?[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  String _getString(String key, {String defaultValue = ''}) {
    final value = _usageData?[key];
    if (value is String) return value;
    return defaultValue;
  }

  List<int> _getWeeklyBreakdown() {
    final value = _usageData?['weekly_breakdown'];
    if (value is List) {
      return value.map((item) {
        if (item is int) return item;
        if (item is num) return item.toInt();
        return 0;
      }).toList();
    }
    return List.filled(7, 0);
  }

  String _formatResetTime(String key) {
    final value = _usageData?[key];
    if (value is String) {
      try {
        final resetTime = DateTime.parse(value);
        final now = DateTime.now();
        final diff = resetTime.difference(now);
        if (diff.isNegative) return 'soon';
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        return '${hours}h ${minutes}m';
      } catch (_) {
        return 'soon';
      }
    }
    return 'soon';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
