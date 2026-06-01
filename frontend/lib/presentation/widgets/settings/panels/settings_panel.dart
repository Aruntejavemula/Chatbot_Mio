import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/settings_repository.dart';

class SettingsPanel extends ConsumerStatefulWidget {
  const SettingsPanel({super.key});

  @override
  ConsumerState<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends ConsumerState<SettingsPanel> {
  String _language = 'English';
  bool _receiveExclusive = true;
  bool _emailOnTask = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTheme = ref.watch(themeProvider);
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE);
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        // General section
        Text('General', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.persian, letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text('Language', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _language,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: textMuted, size: 20),
              dropdownColor: cardBg,
              style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
                DropdownMenuItem(value: 'French', child: Text('French')),
                DropdownMenuItem(value: 'German', child: Text('German')),
                DropdownMenuItem(value: 'Japanese', child: Text('Japanese')),
                DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _language = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Appearance
        Divider(color: borderColor, height: 1),
        const SizedBox(height: 20),
        Text('Appearance', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        const SizedBox(height: 14),
        Row(
          children: [
            _themeOption(
              label: 'Light',
              mode: ThemeMode.light,
              currentMode: currentTheme,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
              borderColor: borderColor,
              icon: Icons.light_mode_outlined,
            ),
            const SizedBox(width: 14),
            _themeOption(
              label: 'Dark',
              mode: ThemeMode.dark,
              currentMode: currentTheme,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
              borderColor: borderColor,
              icon: Icons.dark_mode_outlined,
            ),
            const SizedBox(width: 14),
            _themeOption(
              label: 'Follow System',
              mode: ThemeMode.system,
              currentMode: currentTheme,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
              borderColor: borderColor,
              icon: Icons.settings_suggest_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Communication preferences
        Divider(color: borderColor, height: 1),
        const SizedBox(height: 20),
        Text('Communication preferences', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        const SizedBox(height: 16),
        _toggleRow(
          title: 'Receive exclusive content',
          subtitle: 'Get exclusive offers, event updates, excellent case examples and new feature guides.',
          value: _receiveExclusive,
          onChanged: (val) => setState(() => _receiveExclusive = val),
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        const SizedBox(height: 16),
        _toggleRow(
          title: 'Email me when my queued task starts',
          subtitle: 'When enabled, we\'ll send you a timely email once your task finishes queuing and begins processing.',
          value: _emailOnTask,
          onChanged: (val) => setState(() => _emailOnTask = val),
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        const SizedBox(height: 24),
        Divider(color: borderColor, height: 1),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Manage Cookies', style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary)),
            const Spacer(),
            OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cookie preferences saved')),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text('Manage', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _themeOption({
    required String label,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color borderColor,
    required IconData icon,
  }) {
    final isSelected = currentMode == mode;
    const selectedBorder = AppColors.persian;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(themeProvider.notifier).state = mode;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedBorder : borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 36,
                decoration: BoxDecoration(
                  color: mode == ThemeMode.dark
                      ? const Color(0xFF1A1A1A)
                      : mode == ThemeMode.light
                          ? const Color(0xFFF5F3EF)
                          : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F3EF)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Icon(icon, size: 18, color: isSelected ? AppColors.persian : textMuted),
              ),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? textPrimary : textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.persian,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFD0D0D0),
        ),
      ],
    );
  }
}
