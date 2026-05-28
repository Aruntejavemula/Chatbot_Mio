import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/animations.dart';

class _DeviceInfo {
  final String name;
  final String browser;
  final String os;
  final IconData osIcon;
  final String lastActive;
  final bool isCurrent;

  const _DeviceInfo({
    required this.name,
    required this.browser,
    required this.os,
    required this.osIcon,
    required this.lastActive,
    this.isCurrent = false,
  });
}

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showMioModal(
      context: context,
      builder: (_) => const DevicesScreen(),
    );
  }

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  static const List<_DeviceInfo> _devices = [
    _DeviceInfo(
      name: 'Device 1',
      browser: 'Chrome',
      os: 'Windows',
      osIcon: Icons.desktop_windows_outlined,
      lastActive: 'Active now',
      isCurrent: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final cardBg = isDark ? AppColors.darkBgSecondary : Colors.white;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 480,
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Active Devices',
                        style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: textPrimary),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textMuted, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Device list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return _buildDeviceCard(device, isDark, textPrimary, textSecondary, textMuted, borderColor);
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Footer buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC3545),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Logout From All',
                          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(
    _DeviceInfo device,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(device.osIcon, size: 20, color: textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.name,
                      style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary),
                    ),
                    if (device.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.persian.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CURRENT',
                          style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.persian, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${device.browser}, ${device.os}',
                      style: GoogleFonts.dmSans(fontSize: 13, color: textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Icon(device.osIcon, size: 14, color: textMuted),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  device.lastActive,
                  style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
