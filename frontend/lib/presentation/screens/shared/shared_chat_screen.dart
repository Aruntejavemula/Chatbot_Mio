import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/services/chat_service.dart';
import '../../widgets/common/ghost_mascot.dart';

class SharedChatScreen extends ConsumerStatefulWidget {
  final String slug;

  const SharedChatScreen({super.key, required this.slug});

  @override
  ConsumerState<SharedChatScreen> createState() => _SharedChatScreenState();
}

class _SharedChatScreenState extends ConsumerState<SharedChatScreen> {
  final ChatService _chatService = ChatService();

  Map<String, dynamic>? _chatData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSharedChat();
  }

  Future<void> _loadSharedChat() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _chatService.getSharedChat(widget.slug);
      if (mounted) {
        setState(() {
          _chatData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'This shared chat is no longer available.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(isDark)
              : _buildContent(isDark),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingScreen),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PenguinMascot(size: 64),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final title = _chatData?['title'] as String? ?? 'Shared Chat';
    final messages =
        (_chatData?['messages'] as List<dynamic>?) ?? [];

    return Column(
      children: [
        _buildHeader(isDark, title),
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingCard,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index] as Map<String, dynamic>;
                    return _buildMessageBubble(isDark, msg);
                  },
                ),
        ),
        _buildFooter(isDark),
      ],
    );
  }

  Widget _buildHeader(bool isDark, String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: AppSizes.paddingScreen,
        right: AppSizes.paddingScreen,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.persian.withValues(alpha: 0.9),
            AppColors.persianHover.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PenguinMascot(size: 28, animate: false),
              const SizedBox(width: 8),
              Text(
                'Shared via Mio',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Text(
        'No messages in this chat.',
        style: GoogleFonts.dmSans(
          fontSize: 15,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(bool isDark, Map<String, dynamic> msg) {
    final role = msg['role'] as String? ?? 'user';
    final content = msg['content'] as String? ?? '';
    final isUser = role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.userBubbleBg
                : (isDark ? AppColors.darkAiBubbleBg : AppColors.aiBubbleBg),
            border: isUser
                ? null
                : Border.all(
                    color: isDark
                        ? AppColors.darkAiBubbleBorder
                        : AppColors.aiBubbleBorder,
                  ),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: Text(
            content,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isUser
                  ? AppColors.userBubbleText
                  : (isDark
                      ? AppColors.darkAiBubbleText
                      : AppColors.aiBubbleText),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
        left: AppSizes.paddingScreen,
        right: AppSizes.paddingScreen,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkBorderDefault
                : AppColors.borderDefault,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PenguinMascot(size: 20, animate: false),
          const SizedBox(width: 8),
          Text(
            'Made with Mio',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              launchUrl(
                Uri.parse('https://mio.chat'),
                mode: LaunchMode.externalApplication,
              );
            },
            child: Text(
              'Try Mio free',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.persian,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
