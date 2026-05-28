import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../widgets/chat/streaming_text.dart';
import '../../widgets/chat/thinking_block_widget.dart';

class ChatMessageList extends ConsumerWidget {
  final ScrollController scrollController;
  final bool isDark;

  const ChatMessageList({
    super.key,
    required this.scrollController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);
    final isStreaming = ref.watch(isStreamingProvider);
    final streamingText = ref.watch(streamingTextProvider);
    final streamingThinkingText = ref.watch(streamingThinkingTextProvider);
    final isThinkingStreaming = ref.watch(isThinkingStreamingProvider);
    ref.watch(loadingWordIndexProvider);

    return ListView.builder(
      controller: scrollController,
      reverse: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      itemCount: messages.length + (isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final message = messages[index];
          final isUser = message.role == 'user';
          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.gapMessage),
              child: Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.8 : 0.85),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? (isDark ? AppColors.darkUserBubble : AppColors.userBubble)
                        : Colors.transparent,
                    borderRadius: isUser
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(4),
                            bottomLeft: Radius.circular(20),
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser &&
                          message.thinkingContent != null &&
                          message.thinkingContent!.isNotEmpty)
                        ThinkingBlockWidget(
                          thinkingContent: message.thinkingContent!,
                          isStreaming: false,
                        ),
                      Text(
                        message.content,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Streaming message
        return RepaintBoundary(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (streamingThinkingText.isNotEmpty)
                    ThinkingBlockWidget(
                      thinkingContent: streamingThinkingText,
                      isStreaming: isThinkingStreaming,
                    ),
                  if (streamingText.isEmpty && streamingThinkingText.isEmpty)
                    const TypingIndicator()
                  else if (streamingText.isNotEmpty)
                    StreamingText(
                      text: streamingText,
                      textColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
