import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../widgets/common/trial_banner_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTheme = ref.watch(themeProvider);
    final user = ref.watch(currentUserProvider);

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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        children: [
          const TrialBannerWidget(),
          const SizedBox(height: 8),
          // ACCOUNT section
          _buildSectionHeader('ACCOUNT', isDark),
          _buildUserInfoTile(isDark, user),
          _buildTile(
            icon: Icons.credit_card_outlined,
            title: 'Manage Subscription',
            subtitle: 'Free',
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            onTap: () => context.go(AppRoutes.subscription),
            isDark: isDark,
          ),
          _buildTile(
            icon: Icons.logout,
            title: 'Sign out',
            iconColor: AppColors.error,
            titleColor: AppColors.error,
            onTap: () => _showSignOutDialog(isDark),
            isDark: isDark,
          ),

          // AI PROVIDERS section
          _buildSectionHeader('AI PROVIDERS', isDark),
          _buildTile(
            icon: Icons.key_outlined,
            title: 'API Keys',
            subtitle: 'Manage API keys',
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            onTap: () => context.go(AppRoutes.apiKeys),
            isDark: isDark,
          ),

          // USAGE section
          _buildSectionHeader('USAGE', isDark),
          _buildTile(
            icon: Icons.bar_chart_outlined,
            title: 'Token Usage',
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            onTap: () => context.go(AppRoutes.usage),
            isDark: isDark,
          ),

          // DEVICES section
          _buildSectionHeader('DEVICES', isDark),
          _buildTile(
            icon: Icons.devices_outlined,
            title: 'Manage Devices',
            subtitle: 'Manage connected devices',
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            onTap: () => context.go(AppRoutes.devices),
            isDark: isDark,
          ),

          // STORAGE section
          _buildSectionHeader('STORAGE', isDark),
          _buildTile(
            icon: Icons.cloud_outlined,
            title: 'Storage & Sync',
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            onTap: () => context.go(AppRoutes.storage),
            isDark: isDark,
          ),

          // APPEARANCE section
          _buildSectionHeader('APPEARANCE', isDark),
          _buildThemeTile(isDark, currentTheme),

          // ABOUT section
          _buildSectionHeader('ABOUT', isDark),
          _buildTile(
            icon: Icons.info_outline,
            title: 'Version',
            trailing: Text(
              '1.0.0',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            isDark: isDark,
          ),
          _buildTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            onTap: () => context.go(AppRoutes.privacy),
            isDark: isDark,
          ),
          _buildTile(
            icon: Icons.description_outlined,
            title: 'Terms',
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            onTap: () => context.go(AppRoutes.terms),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildUserInfoTile(bool isDark, dynamic user) {
    final name = user?.name ?? 'User';
    final email = user?.email ?? 'user@example.com';
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.persian,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              firstLetter,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
    Color? iconColor,
    Color? titleColor,
  }) {
    return _AnimatedTile(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: iconColor ??
                  (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ??
                          (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile(bool isDark, ThemeMode currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.palette_outlined,
            size: 22,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            'Theme',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _buildThemeOption('Light', ThemeMode.light, currentTheme, isDark),
              const SizedBox(width: 4),
              _buildThemeOption(
                  'System', ThemeMode.system, currentTheme, isDark),
              const SizedBox(width: 4),
              _buildThemeOption('Dark', ThemeMode.dark, currentTheme, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    String label,
    ThemeMode mode,
    ThemeMode currentTheme,
    bool isDark,
  ) {
    final isSelected = currentTheme == mode;

    return GestureDetector(
      onTap: () {
        ref.read(settingsRepositoryProvider).saveTheme(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.persian : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        title: Text(
          'Sign Out',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.dmSans(
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final router = GoRouter.of(this.context);
              navigator.pop();
              await ref.read(authRepositoryProvider).signOut();
              if (mounted) {
                router.go(AppRoutes.welcome);
              }
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.dmSans(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTile extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _AnimatedTile({
    required this.child,
    this.onTap,
  });

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _scale = 0.97);
      },
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _scale = 1.0);
      },
      child: AnimatedScale(
        scale: _scale,
        duration: MioAnimations.fast,
        curve: MioAnimations.curve,
        child: widget.child,
      ),
    );
  }
}
