import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';

class _ChecklistGroup {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _ChecklistGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class LaunchChecklistScreen extends StatefulWidget {
  const LaunchChecklistScreen({super.key});

  @override
  State<LaunchChecklistScreen> createState() => _LaunchChecklistScreenState();
}

class _LaunchChecklistScreenState extends State<LaunchChecklistScreen> {
  static const _prefsKey = 'launch_checklist';

  static const List<_ChecklistGroup> _groups = [
    _ChecklistGroup(
      title: 'Backend',
      icon: Icons.dns_outlined,
      color: Color(0xFF6366F1),
      items: [
        'API endpoints tested',
        'Database migrations applied',
        'Rate limiting configured',
        'Error logging set up',
        'Health check endpoint live',
        'SSL certificates configured',
        'Environment variables set',
        'Backup strategy confirmed',
      ],
    ),
    _ChecklistGroup(
      title: 'Frontend',
      icon: Icons.devices_outlined,
      color: Color(0xFF06B6D4),
      items: [
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
    ),
    _ChecklistGroup(
      title: 'Store Listings',
      icon: Icons.storefront_outlined,
      color: Color(0xFFF59E0B),
      items: [
        'App Store screenshots uploaded',
        'Play Store screenshots uploaded',
        'App description written',
        'Keywords optimized',
        'Privacy policy URL added',
      ],
    ),
    _ChecklistGroup(
      title: 'Launch',
      icon: Icons.rocket_launch_outlined,
      color: AppColors.persian,
      items: [
        'ProductHunt page drafted',
        'Social media posts scheduled',
        'Landing page live',
        'Beta testers notified',
        'Press kit ready',
        'Support email configured',
        'Monitoring alerts enabled',
      ],
    ),
  ];

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

  int get _totalItems => _groups.fold(0, (sum, g) => sum + g.items.length);

  int _groupChecked(_ChecklistGroup group) =>
      group.items.where((item) => _checked.contains(item)).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final cardBg = isDark ? AppColors.darkBgSecondary : Colors.white;

    final total = _totalItems;
    final checkedCount = _checked.length;
    final progress = total > 0 ? checkedCount / total : 0.0;
    final percent = (progress * 100).round();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator(color: AppColors.persian))
            : SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: IconButton(
                              icon: Icon(Icons.arrow_back, color: textPrimary, size: 22),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Hero header with progress
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                                    : [const Color(0xFFFFF8F3), const Color(0xFFFAF5EF)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.checklist_outlined, size: 36, color: AppColors.persian),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Launch Checklist',
                                            style: GoogleFonts.dmSerifDisplay(fontSize: 36, color: textPrimary),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Track your progress across backend, frontend, store listings, and launch tasks.',
                                            style: GoogleFonts.dmSans(fontSize: 15, height: 1.5, color: textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    // Circular progress
                                    SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SizedBox(
                                            width: 80,
                                            height: 80,
                                            child: CircularProgressIndicator(
                                              value: progress,
                                              strokeWidth: 6,
                                              backgroundColor: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
                                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.persian),
                                              strokeCap: StrokeCap.round,
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '$percent%',
                                                style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
                                              ),
                                              Text(
                                                '$checkedCount/$total',
                                                style: GoogleFonts.dmSans(fontSize: 11, color: textMuted),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Group cards
                          ..._groups.map((group) {
                            final done = _groupChecked(group);
                            final groupTotal = group.items.length;
                            final groupProgress = groupTotal > 0 ? done / groupTotal : 0.0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 1),
                                ),
                                child: Column(
                                  children: [
                                    // Group header
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: group.color.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(group.icon, size: 16, color: group.color),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              group.title,
                                              style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: textPrimary),
                                            ),
                                          ),
                                          Text(
                                            '$done / $groupTotal',
                                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Group progress bar
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: groupProgress,
                                          minHeight: 4,
                                          backgroundColor: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
                                          valueColor: AlwaysStoppedAnimation<Color>(group.color),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Items
                                    ...group.items.map((item) {
                                      final isChecked = _checked.contains(item);
                                      return InkWell(
                                        onTap: () => _toggle(item),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: Checkbox(
                                                  value: isChecked,
                                                  onChanged: (_) => _toggle(item),
                                                  activeColor: group.color,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                  side: BorderSide(color: borderColor, width: 1.5),
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  item,
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 14,
                                                    color: isChecked ? textMuted : textPrimary,
                                                    decoration: isChecked ? TextDecoration.lineThrough : null,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
