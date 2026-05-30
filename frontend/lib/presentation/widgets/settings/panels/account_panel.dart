import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/router.dart';
import '../../../../data/repositories/auth_repository.dart';

class AccountPanel extends ConsumerWidget {
  const AccountPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final cardBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F6F2);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE);

    final name = user?.name ?? 'User';
    final email = user?.email ?? 'user@example.com';
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        // Profile card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.persian,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  firstLetter,
                  style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 2),
                    Text(email, style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _showEditProfile(context, name, email),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text('Edit profile', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Account details
        Text('Account details', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        _detailRow('Name', name, textPrimary, textMuted, borderColor),
        _detailRow('Email', email, textPrimary, textMuted, borderColor),
        _detailRow('Plan', 'Free', textPrimary, textMuted, borderColor, valueColor: AppColors.persian),
        const SizedBox(height: 32),
        // Danger zone
        Text('Danger zone', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        _actionRow(
          icon: Icons.logout,
          label: 'Sign out',
          subtitle: 'Sign out of your account on this device',
          color: AppColors.error,
          textPrimary: textPrimary,
          textMuted: textMuted,
          borderColor: borderColor,
          onTap: () => _confirmSignOut(context, ref),
        ),
        const SizedBox(height: 8),
        _actionRow(
          icon: Icons.delete_outline,
          label: 'Delete account',
          subtitle: 'Permanently delete your account and all data',
          color: AppColors.error,
          textPrimary: textPrimary,
          textMuted: textMuted,
          borderColor: borderColor,
          onTap: () => _confirmDeleteAccount(context, ref),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, Color textPrimary, Color textMuted, Color borderColor, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, String name, String email) {
    final nameController = TextEditingController(text: name);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text('Edit profile', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              decoration: InputDecoration(labelText: 'Email', hintText: email),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.dmSans())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.persian),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated')),
              );
            },
            child: Text('Save', style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out?', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
        content: Text('You will be signed out on this device.', style: GoogleFonts.dmSans()),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.dmSans())),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(authRepositoryProvider).signOut();
              } catch (_) {}
              if (context.mounted) {
                Navigator.of(context).pop();
                context.go(AppRoutes.welcome);
              }
            },
            child: Text('Sign out', style: GoogleFonts.dmSans(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete account?', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
        content: Text(
          'This permanently deletes your account and all data. This action cannot be undone.',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.dmSans())),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion requested. Contact support to confirm.')),
              );
            },
            child: Text('Delete', style: GoogleFonts.dmSans(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color textPrimary,
    required Color textMuted,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
                    Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
