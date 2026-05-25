import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/chat_model.dart';

class ChatItem extends StatelessWidget {
  final ChatModel chat;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ChatItem({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final chatDay = DateTime(date.year, date.month, date.day);

    if (chatDay == today) {
      return DateFormat.jm().format(date);
    } else if (chatDay == yesterday) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final bgTertiary = isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? bgTertiary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: isSelected
              ? const Border(
                  left: BorderSide(
                    color: AppColors.persian,
                    width: 2,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.lastPreview,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTimestamp(chat.updatedAt),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
