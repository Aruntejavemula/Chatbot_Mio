import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/repositories/chat_repository.dart';

class ChatTopBar extends ConsumerWidget {
  final bool isDark;
  final bool showPermanentSidebar;
  final String? chatId;
  final VoidCallback onToggleSidebar;
  final VoidCallback onNewChat;
  final VoidCallback onShareChat;
  final VoidCallback onShowMoreOptions;

  const ChatTopBar({
    super.key,
    required this.isDark,
    required this.showPermanentSidebar,
    this.chatId,
    required this.onToggleSidebar,
    required this.onNewChat,
    required this.onShareChat,
    required this.onShowMoreOptions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);
    final currentChat = ref.watch(currentChatProvider);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final circleBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final circleBorder = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE);

    final bool isEmptyState = chatId == null && currentChat == null && messages.isEmpty;
    final bool hasMessages = messages.isNotEmpty;

    return Container(
      height: AppSizes.topBarHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Left: sidebar toggle (mobile only)
            if (!showPermanentSidebar)
              GestureDetector(
                onTap: onToggleSidebar,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleBg,
                    border: Border.all(color: circleBorder, width: 1),
                  ),
                  child: Icon(Icons.tune_rounded, size: 18, color: textMuted),
                ),
              ),
            // Center content
            Expanded(
              child: Center(
                child: (isEmptyState || !hasMessages)
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        onTap: onShowMoreOptions,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                currentChat?.title ?? 'New Chat',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textMuted),
                          ],
                        ),
                      ),
              ),
            ),
            // Right side
            if (isEmptyState || !hasMessages)
              // Empty: new chat icon
              GestureDetector(
                onTap: onNewChat,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleBg,
                    border: Border.all(color: circleBorder, width: 1),
                  ),
                  child: Icon(Icons.chat_bubble_outline_rounded, size: 18, color: textMuted),
                ),
              )
            else
              // Active: Share button (desktop text, mobile icon)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasMessages)
                    showPermanentSidebar
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DBD2),
                                width: 1,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: onShareChat,
                              child: Text(
                                'Share',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: onShareChat,
                                child: Icon(Icons.ios_share_outlined, size: 20, color: textMuted),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: onShowMoreOptions,
                                child: Icon(Icons.more_horiz_rounded, size: 20, color: textMuted),
                              ),
                            ],
                          ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
