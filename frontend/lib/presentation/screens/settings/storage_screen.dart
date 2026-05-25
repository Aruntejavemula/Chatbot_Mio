import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/router.dart';

class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  String _currentPlan = 'free';
  String? _selectedProvider;

  @override
  void initState() {
    super.initState();
    _loadStorageSettings();
  }

  Future<void> _loadStorageSettings() async {
    try {
      setState(() {
        _currentPlan = 'free';
        _selectedProvider = null;
      });
    } catch (e) {
      rethrow;
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Storage & Sync',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(isDark),
            const SizedBox(height: 20),
            _buildPlanContent(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    final providerLabel = _selectedProvider ?? 'None';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border.all(
          color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_done_outlined,
            color: AppColors.persian,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Currently syncing to:',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              providerLabel,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanContent(bool isDark) {
    switch (_currentPlan) {
      case 'basic':
        return _buildBasicContent(isDark);
      case 'pro':
        return _buildProContent(isDark);
      default:
        return _buildFreeContent(isDark);
    }
  }

  Widget _buildFreeContent(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.persian),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync across devices',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to Basic to sync chats to Google Drive, iCloud, or OneDrive',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.subscription),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.persian,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
            child: Text(
              'Upgrade',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your sync provider',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
        Text(
          'Pick one. Your chats sync there. We store nothing.',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        _buildProviderTile(
          isDark: isDark,
          providerKey: 'google_drive',
          name: 'Google Drive',
          subtitle: 'Syncs to your Google account',
          avatarColor: const Color(0xFF4CAF50),
          avatarLabel: 'G',
        ),
        const SizedBox(height: 12),
        if (Platform.isIOS || Platform.isMacOS) ...[
          _buildProviderTile(
            isDark: isDark,
            providerKey: 'icloud',
            name: 'iCloud Drive',
            subtitle: 'Syncs to your Apple account',
            avatarColor: const Color(0xFF2196F3),
            avatarLabel: 'i',
          ),
          const SizedBox(height: 12),
        ],
        _buildProviderTile(
          isDark: isDark,
          providerKey: 'onedrive',
          name: 'OneDrive',
          subtitle: 'Syncs to your Microsoft account',
          avatarColor: const Color(0xFF0078D4),
          avatarLabel: 'M',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Switching providers will not transfer existing chats.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProviderTile({
    required bool isDark,
    required String providerKey,
    required String name,
    required String subtitle,
    required Color avatarColor,
    required String avatarLabel,
  }) {
    final isSelected = _selectedProvider == providerKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProvider = providerKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
          border: Border.all(
            color:
                isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: avatarColor,
              child: Text(
                avatarLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.persian,
              )
            else
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedProvider = providerKey;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.persian,
                  side: const BorderSide(color: AppColors.persian),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
                child: Text(
                  'Connect',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProContent(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border.all(
          color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_done,
            color: AppColors.persian,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-time sync active',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Your chats sync instantly across all your devices via '
                  "Mio's secure cloud.",
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
