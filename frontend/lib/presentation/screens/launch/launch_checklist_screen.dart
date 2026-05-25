import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class LaunchChecklistScreen extends StatefulWidget {
  const LaunchChecklistScreen({super.key});

  @override
  State<LaunchChecklistScreen> createState() => _LaunchChecklistScreenState();
}

class _LaunchChecklistScreenState extends State<LaunchChecklistScreen> {
  static const _prefsKey = 'launch_checklist';

  final Map<String, List<String>> _groups = {
    'Backend': [
      'API endpoints tested',
      'Database migrations applied',
      'Rate limiting configured',
      'Error logging set up',
      'Health check endpoint live',
      'SSL certificates configured',
      'Environment variables set',
      'Backup strategy confirmed',
    ],
    'Frontend': [
      'Build passes without errors',
      'All screens responsive',
      'Dark mode verified',
      'Loading states implemented',
      'Error states handled',
      'Accessibility reviewed',
      'Performance profiled',
      'App icon and splash screen set',
      'Deep links configured',
      'Analytics integrated',
    ],
    'Store Listings': [
      'App Store screenshots uploaded',
      'Play Store screenshots uploaded',
      'App description written',
      'Keywords optimized',
      'Privacy policy URL added',
    ],
    'Launch': [
      'ProductHunt page drafted',
      'Social media posts scheduled',
      'Landing page live',
      'Beta testers notified',
      'Press kit ready',
      'Support email configured',
      'Monitoring alerts enabled',
    ],
  };

  Set<String> _checked = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    setState(() {
      _checked = saved.toSet();
      _loaded = true;
    });
  }

  Future<void> _toggle(String item) async {
    setState(() {
      if (_checked.contains(item)) {
        _checked.remove(item);
      } else {
        _checked.add(item);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _checked.toList());
  }

  int get _totalItems =>
      _groups.values.fold(0, (sum, items) => sum + items.length);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _totalItems;
    final checkedCount = _checked.length;
    final progress = total > 0 ? checkedCount / total : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Launch Checklist',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.paddingScreen),
              children: [
                _buildProgressBar(isDark, progress, checkedCount, total),
                const SizedBox(height: 24),
                ..._groups.entries.expand((entry) => [
                      _buildGroupHeader(entry.key, isDark),
                      const SizedBox(height: 8),
                      ...entry.value.map(
                        (item) => _buildChecklistItem(item, isDark),
                      ),
                      const SizedBox(height: 16),
                    ]),
              ],
            ),
    );
  }

  Widget _buildProgressBar(
    bool isDark,
    double progress,
    int checked,
    int total,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingCard),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color:
              isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '$checked / $total',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.persian,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String item, bool isDark) {
    final isChecked = _checked.contains(item);

    return GestureDetector(
      onTap: () => _toggle(item),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isChecked,
                onChanged: (_) => _toggle(item),
                activeColor: AppColors.persian,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: isDark
                      ? AppColors.darkBorderDefault
                      : AppColors.borderDefault,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: isChecked
                      ? (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted)
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary),
                  decoration:
                      isChecked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
