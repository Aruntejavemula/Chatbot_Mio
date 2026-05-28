import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/router.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../widgets/common/shaking_hands.dart';
import '../../widgets/sidebar/chat_item.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(chatsProvider);
    final currentChat = ref.watch(currentChatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool showSplitPanel = Responsive.isDesktop(context) ||
        (Responsive.isTablet(context) && Responsive.isLandscape(context));

    if (showSplitPanel) {
      return _buildSplitLayout(isDark, chats, currentChat);
    }

    return _buildFullScreenList(isDark, chats);
  }

  Widget _buildSplitLayout(bool isDark, List<ChatModel> chats, ChatModel? currentChat) {
    return Scaffold(
      body: Row(
        children: [
          // Left panel - chat list
          SizedBox(
            width: 320,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
                border: Border(
                  right: BorderSide(
                    color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingCard),
                      child: Text(
                        'Chats',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildChatListView(isDark, chats, currentChat),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right panel - selected chat or empty state
          Expanded(
            child: currentChat != null
                ? _buildSelectedChatPlaceholder(isDark)
                : _buildEmptyState(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenList(bool isDark, List<ChatModel> chats) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chats',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
        elevation: 0,
      ),
      body: Container(
        color: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
        child: _buildChatListView(isDark, chats, null),
      ),
    );
  }

  Widget _buildChatListView(bool isDark, List<ChatModel> chats, ChatModel? currentChat) {
    if (chats.isEmpty) {
      return Center(
        child: Text(
          'No chats yet',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatItem(
          chat: chat,
          isSelected: currentChat != null && chat.id == currentChat.id,
          onTap: () {
            ref.read(currentChatProvider.notifier).state = chat;
            if (!Responsive.isDesktop(context) &&
                !(Responsive.isTablet(context) && Responsive.isLandscape(context))) {
              context.go('${AppRoutes.chat}/${chat.id}');
            }
          },
          onDelete: () {
            ref.read(chatRepositoryProvider).deleteChat(chat.id);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ShakingHands(size: AppSizes.mascotSizeMedium),
            const SizedBox(height: 16),
            Text(
              'Select a chat to continue',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChatPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      child: Center(
        child: Text(
          'Chat selected',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
