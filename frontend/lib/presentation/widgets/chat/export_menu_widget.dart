import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/chat_repository.dart';

class ExportMenuWidget extends ConsumerWidget {
  final String chatId;
  final String userPlan;

  const ExportMenuWidget({
    super.key,
    required this.chatId,
    required this.userPlan,
  });

  static void showExportSheet({
    required BuildContext context,
    required String chatId,
    required String userPlan,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: ExportMenuWidget(
            chatId: chatId,
            userPlan: userPlan,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Chat',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        _buildExportOption(
          context: context,
          ref: ref,
          icon: Icons.description_outlined,
          title: 'Export as Markdown',
          subtitle: '.md file',
          onTap: () => _exportMarkdown(context, ref),
        ),
        const SizedBox(height: 8),
        _buildExportOption(
          context: context,
          ref: ref,
          icon: Icons.picture_as_pdf_outlined,
          title: 'Export as PDF',
          subtitle: '.pdf file',
          onTap: () => _exportPdf(context, ref),
        ),
        const SizedBox(height: 8),
        _buildExportOption(
          context: context,
          ref: ref,
          icon: Icons.folder_zip_outlined,
          title: 'Export All Chats',
          subtitle: 'Single .md',
          onTap: () => _exportAll(context, ref),
        ),
      ],
    );
  }

  Widget _buildExportOption({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppColors.persian,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportMarkdown(BuildContext context, WidgetRef ref) async {
    try {
      Navigator.of(context).pop();
      final chatService = ref.read(chatServiceProvider);
      final bytes = await chatService.exportChatMarkdown(chatId);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/chat_export.md');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat exported successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export chat')),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    if (userPlan == 'free') {
      Navigator.of(context).pop();
      _showUpgradeDialog(context);
      return;
    }
    try {
      Navigator.of(context).pop();
      final chatService = ref.read(chatServiceProvider);
      final bytes = await chatService.exportChatPdf(chatId);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/chat_export.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF exported successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export PDF')),
      );
    }
  }

  Future<void> _exportAll(BuildContext context, WidgetRef ref) async {
    if (userPlan != 'pro') {
      Navigator.of(context).pop();
      _showUpgradeDialog(context);
      return;
    }
    try {
      Navigator.of(context).pop();
      final chatService = ref.read(chatServiceProvider);
      final bytes = await chatService.exportAllChats();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/all_chats_export.md');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All chats exported successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export chats')),
      );
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Upgrade Required',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 18,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          content: Text(
            'This feature is available on a higher plan. Upgrade to unlock it.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Upgrade',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.persian,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
