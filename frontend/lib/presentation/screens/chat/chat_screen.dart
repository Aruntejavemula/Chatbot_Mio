import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/loading_words.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/funny_warnings.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/chat_service.dart';
import '../../widgets/chat/document_viewer_widget.dart';
import '../../widgets/chat/file_upload_widget.dart';
import '../../widgets/chat/export_menu_widget.dart';
import '../../widgets/chat/plus_panel_widget.dart';
import '../../widgets/chat/prompt_maker_widget.dart';
import '../../widgets/chat/token_cap_banner.dart';
import '../../widgets/chat/voice_input_widget.dart';
import '../../widgets/common/funny_snackbar.dart';
import '../../widgets/common/ghost_mascot.dart';
import '../../widgets/sidebar/sidebar_widget.dart';
import '../../../core/utils/responsive.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? chatId;
  final String? projectId;
  const ChatScreen({super.key, this.chatId, this.projectId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with TickerProviderStateMixin {
  bool _isSidebarOpen = false;
  bool _isModelDropdownOpen = false;
  String _selectedModel = 'Think now';
  String _selectedProvider = '';
  bool _hasText = false;
  bool _isFocused = false;
  final bool _hasApiKeys = false; // TODO: wire to actual data
  String _searchQuery = '';
  late TextEditingController _inputController;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  final ChatService _chatService = ChatService();
  List<SelectedFileInfo> _selectedFiles = [];
  late AnimationController _sendButtonAnimController;
  bool _isPanelOpen = false;
  bool _showScrollButton = false;
  late AnimationController _scrollButtonAnimController;
  late Animation<double> _scrollButtonFadeAnimation;

  final List<Map<String, dynamic>> _availableModels = [
    {'provider': 'OpenAI', 'model': 'GPT-4o', 'color': const Color(0xFF10A37F)},
    {'provider': 'OpenAI', 'model': 'GPT-4o mini', 'color': const Color(0xFF10A37F)},
    {'provider': 'Anthropic', 'model': 'Claude 4 Sonnet', 'color': const Color(0xFFD97757)},
    {'provider': 'Anthropic', 'model': 'Claude 3.5 Haiku', 'color': const Color(0xFFD97757)},
    {'provider': 'Google', 'model': 'Gemini 2.5 Pro', 'color': const Color(0xFF4285F4)},
    {'provider': 'DeepSeek', 'model': 'DeepSeek R1', 'color': const Color(0xFF4D6BFE)},
  ];

  List<Map<String, dynamic>> get _filteredModels {
    if (_searchQuery.isEmpty) return _availableModels;
    return _availableModels
        .where((m) =>
            (m['model'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (m['provider'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  bool get _isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  bool get _isMobile {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _sendButtonAnimController = AnimationController(
      vsync: this,
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
    _scrollButtonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scrollButtonFadeAnimation = CurvedAnimation(
      parent: _scrollButtonAnimController,
      curve: Curves.easeOut,
    );
    _scrollController.addListener(_onScrollChanged);
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
    if (_isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _sendButtonAnimController.dispose();
    _scrollButtonAnimController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    if (_isMobile) HapticFeedback.lightImpact();
    setState(() => _isPanelOpen = !_isPanelOpen);
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      if (_isMobile) HapticFeedback.mediumImpact();
      FunnySnackbar.show(context, FunnyWarnings.signInRequired, type: SnackbarType.warning);
      return;
    }
    if (_selectedModel == 'Think now') {
      if (_isMobile) HapticFeedback.mediumImpact();
      FunnySnackbar.show(context, FunnyWarnings.modelNotSelected, type: SnackbarType.warning);
      return;
    }
    if (_isMobile) HapticFeedback.mediumImpact();
    _inputController.clear();
    setState(() {
      _hasText = false;
      _selectedFiles = [];
    });
    // TODO: Create chat if needed, then send message
    // For now just print
    debugPrint('Send: $text with model: $_selectedModel provider: $_selectedProvider');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        final distanceFromBottom = maxScroll - currentScroll;

        if (distanceFromBottom <= 100) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final distanceFromBottom = maxScroll - currentScroll;

    if (distanceFromBottom > 200 && !_showScrollButton) {
      setState(() => _showScrollButton = true);
      _scrollButtonAnimController.forward();
    } else if (distanceFromBottom <= 200 && _showScrollButton) {
      _scrollButtonAnimController.reverse().then((_) {
        if (mounted) setState(() => _showScrollButton = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final isStreaming = ref.watch(isStreamingProvider);
    final streamingText = ref.watch(streamingTextProvider);
    final loadingWordIndex = ref.watch(loadingWordIndexProvider);
    final tokenCap = ref.watch(tokenCapProvider);
    ref.watch(chatsProvider);
    ref.watch(currentChatProvider);
    ref.watch(isAuthenticatedProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<Map<String, Object?>?>(tokenCapProvider, (prev, next) {
      if (prev == null && next != null && _isMobile) {
        HapticFeedback.heavyImpact();
      }
    });

    if (messages.isNotEmpty || isStreaming) {
      _scrollToBottom();
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool showPermanentSidebar =
              Responsive.isDesktop(context) ||
              (Responsive.isTablet(context) && Responsive.isLandscape(context));
          final double sidebarWidth =
              Responsive.isDesktop(context) ? 300.0 : AppSizes.sidebarWidth;

          return Row(
            children: [
              // Permanent sidebar for desktop / tablet-landscape
              if (showPermanentSidebar)
                SizedBox(
                  width: sidebarWidth,
                  child: SidebarWidget(
                    isOpen: true,
                    permanent: true,
                    onClose: () {},
                    onNewChat: () => context.go(AppRoutes.chat),
                  ),
                ),
              // Chat area
              Expanded(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_isModelDropdownOpen) {
                          setState(() => _isModelDropdownOpen = false);
                        }
                        FocusScope.of(context).unfocus();
                      },
                      child: Column(
                        children: [
                          // Top bar
                          _buildTopBar(isDark, showPermanentSidebar: showPermanentSidebar),
                          // Model selector bar
                          _buildModelSelectorBar(isDark),
                          // BYOK banner
                          if (!_hasApiKeys && _selectedModel == 'Think now')
                            _buildByokBanner(isDark),
                          // Chat messages area
                          Expanded(
                            child: Container(
                              color: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
                              child: messages.isEmpty && !isStreaming
                                  ? _buildEmptyState(isDark)
                                  : _buildMessagesList(
                                      isDark, messages, isStreaming, streamingText, loadingWordIndex),
                            ),
                          ),
                          // Input bar
                          if (tokenCap != null)
                            TokenCapBanner(
                              capType: (tokenCap['cap_type'] as String?) ?? '',
                              used: (tokenCap['used'] as int?) ?? 0,
                              limit: (tokenCap['limit'] as int?) ?? 1,
                              resetsIn: (tokenCap['resets_in'] as String?) ?? '',
                              onAddKey: () => context.go(AppRoutes.apiKeys),
                            ),
                          if (_selectedFiles.isNotEmpty)
                            DocumentViewerWidget(
                              files: _selectedFiles,
                              onRemoveFile: (int index) {
                                setState(() {
                                  _selectedFiles.removeAt(index);
                                });
                              },
                              isDark: isDark,
                            ),
                          PlusPanelWidget(
                            isOpen: _isPanelOpen,
                            onToggle: _togglePanel,
                            userPlan: 'free', // TODO: wire to actual user plan
                            connectedProviders: const [], // TODO: wire to actual data
                            onFilesSelected: (List<SelectedFileInfo> files) {
                              setState(() {
                                _selectedFiles.addAll(files);
                                _isPanelOpen = false;
                              });
                            },
                          ),
                          _buildInputBar(isDark),
                        ],
                      ),
                    ),
                    // Model dropdown overlay
                    if (_isModelDropdownOpen) _buildModelDropdown(isDark),
                    // Sidebar drawer overlay (phone / tablet-portrait only)
                    if (!showPermanentSidebar && _isSidebarOpen)
                      SidebarWidget(
                        isOpen: _isSidebarOpen,
                        onClose: () => setState(() => _isSidebarOpen = false),
                        onNewChat: () {
                          setState(() => _isSidebarOpen = false);
                          context.go(AppRoutes.chat);
                        },
                      ),
                    // Scroll to bottom button
                    if (_showScrollButton)
                      Positioned(
                        bottom: 80,
                        right: 16,
                        child: FadeTransition(
                          opacity: _scrollButtonFadeAnimation,
                          child: GestureDetector(
                            onTap: () {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(bool isDark, {bool showPermanentSidebar = false}) {
    final messages = ref.watch(messagesProvider);
    final currentChat = ref.watch(currentChatProvider);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final bool isEmptyState = widget.chatId == null && currentChat == null && messages.isEmpty;

    return Container(
      height: AppSizes.topBarHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (!showPermanentSidebar)
              IconButton(
                onPressed: () => setState(() => _isSidebarOpen = true),
                icon: Icon(
                  Icons.menu_rounded,
                  size: 20,
                  color: textMuted,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isEmptyState)
                    Text(
                      'Mio',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else ...[
                    Text(
                      currentChat?.title ?? 'New Chat',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.projectId != null && widget.projectId!.isNotEmpty)
                      Text(
                        'Project',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.persian,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ],
              ),
            ),
            if (!isEmptyState) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (messages.isNotEmpty && widget.chatId != null && widget.chatId!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: GestureDetector(
                        onTap: () {
                          ExportMenuWidget.showExportSheet(
                            context: context,
                            chatId: widget.chatId!,
                            userPlan: 'free',
                          );
                        },
                        child: Icon(
                          Icons.download_outlined,
                          size: 20,
                          color: textMuted,
                        ),
                      ),
                    ),
                  if (messages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: showPermanentSidebar
                          ? TextButton(
                              onPressed: _shareChat,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Share',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textMuted,
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: _shareChat,
                              child: Icon(
                                Icons.ios_share_outlined,
                                size: 20,
                                color: textMuted,
                              ),
                            ),
                    ),
                  GestureDetector(
                    onTap: () => _showMoreOptionsSheet(isDark),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _shareChat() {
    final messages = ref.read(messagesProvider);
    if (messages.isEmpty) return;
    final buffer = StringBuffer('Chat from Mio\n\n');
    for (final msg in messages) {
      final role = msg.role == 'user' ? 'You' : 'AI';
      buffer.writeln('$role: ${msg.content}\n');
    }
    Share.share(buffer.toString());
  }

  void _showMoreOptionsSheet(bool isDark) {
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_outlined, color: textColor),
                title: Text(
                  'Rename chat',
                  style: GoogleFonts.dmSans(fontSize: 15, color: textColor),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRenameDialog(isDark);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_sweep_outlined, color: textColor),
                title: Text(
                  'Clear chat',
                  style: GoogleFonts.dmSans(fontSize: 15, color: textColor),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showClearConfirmDialog(isDark);
                },
              ),
              ListTile(
                leading: Icon(Icons.add_outlined, color: textColor),
                title: Text(
                  'New chat',
                  style: GoogleFonts.dmSans(fontSize: 15, color: textColor),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.chat);
                },
              ),
              Divider(color: borderColor),
              ListTile(
                leading: const Icon(Icons.delete_outlined, color: AppColors.error),
                title: Text(
                  'Delete chat',
                  style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showDeleteConfirmDialog(isDark);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(bool isDark) {
    final currentChat = ref.read(currentChatProvider);
    final controller = TextEditingController(text: currentChat?.title ?? '');
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final bgColor = isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: bgColor,
          title: Text(
            'Rename chat',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.dmSans(fontSize: 15, color: textColor),
            decoration: InputDecoration(
              hintText: 'Chat title',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 15,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newTitle = controller.text.trim();
                if (newTitle.isEmpty || widget.chatId == null) return;
                final navigator = Navigator.of(dialogContext);
                try {
                  final chatService = ref.read(chatServiceProvider);
                  await chatService.updateChatTitle(widget.chatId!, newTitle);
                  final chat = ref.read(currentChatProvider);
                  if (chat != null) {
                    ref.read(currentChatProvider.notifier).state =
                        chat.copyWith(title: newTitle);
                  }
                  if (dialogContext.mounted) navigator.pop();
                } catch (e) {
                  if (mounted) {
                    if (_isMobile) HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to rename chat: $e')),
                    );
                  }
                }
              },
              child: Text(
                'Save',
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

  void _showClearConfirmDialog(bool isDark) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final bgColor = isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: bgColor,
          title: Text(
            'Clear all messages?',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          content: Text(
            'This will remove all messages from this chat.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(messagesProvider.notifier).state = [];
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(bool isDark) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final bgColor = isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: bgColor,
          title: Text(
            'Delete this chat?',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          content: Text(
            'This action cannot be undone.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (widget.chatId == null) return;
                try {
                  final chatService = ref.read(chatServiceProvider);
                  await chatService.deleteChat(widget.chatId!);
                  final chats = ref.read(chatsProvider);
                  ref.read(chatsProvider.notifier).state =
                      chats.where((c) => c.id != widget.chatId).toList();
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (mounted) context.go(AppRoutes.chat);
                } catch (e) {
                  if (mounted) {
                    if (_isMobile) HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete chat: $e')),
                    );
                  }
                }
              },
              child: Text(
                'Delete',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModelSelectorBar(bool isDark) {
    return Container(
      height: AppSizes.modelBarHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => setState(() => _isModelDropdownOpen = !_isModelDropdownOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(
                color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedModel,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _selectedModel == 'Think now'
                        ? AppColors.persian
                        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _isModelDropdownOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelDropdown(bool isDark) {
    return Positioned(
      top: AppSizes.topBarHeight + AppSizes.modelBarHeight + MediaQuery.of(context).padding.top + 4,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(
              color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _hasApiKeys ? _buildModelList(isDark) : _buildNoApiKeysContent(isDark),
        ),
      ),
    );
  }

  Widget _buildNoApiKeysContent(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No API keys added yet',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(AppRoutes.apiKeys),
            child: Text(
              'Add API Key',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.persian,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelList(bool isDark) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final model in _filteredModels) {
      final provider = model['provider'] as String;
      grouped.putIfAbsent(provider, () => []);
      grouped[provider]!.add(model);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search field
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
                width: 1,
              ),
            ),
          ),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search models...',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
              border: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
        // Model list
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                ),
                for (final model in entry.value)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedModel = model['model'] as String;
                        _selectedProvider = model['provider'] as String;
                        _isModelDropdownOpen = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: model['color'] as Color,
                            ),
                            child: Center(
                              child: Text(
                                (model['provider'] as String)[0],
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            model['model'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedModel == model['model'])
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.persian,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        // Divider
        Divider(
          height: 1,
          color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
        ),
        // Bottom row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go(AppRoutes.apiKeys),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                '+ Add another provider',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.persian,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildByokBanner(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.key, size: 16, color: AppColors.persian),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add an AI key to start chatting',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.apiKeys),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(
              'Add Key',
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            // TODO: Replace with mascot
            child: Center(child: PenguinMascot(size: 48)),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              AppStrings.getGreeting(),
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(
    bool isDark,
    List messages,
    bool isStreaming,
    String streamingText,
    int loadingWordIndex,
  ) {
    return ListView.builder(
      controller: _scrollController,
      reverse: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length + (isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final message = messages[index];
          final isUser = message.role == 'user';
          return Padding(
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
                child: Text(
                  message.content,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }

        // Streaming message
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: streamingText.isEmpty
                ? Text(
                    '${LoadingWords.getWord(loadingWordIndex)}...',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  )
                : Text(
                    streamingText,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppSizes.radiusInput),
          border: Border.all(
            color: _isFocused
                ? AppColors.persian
                : (isDark ? AppColors.darkBorderDefault : AppColors.borderDefault),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Plus button with rotation and file badge
            GestureDetector(
              onTap: _togglePanel,
              child: SizedBox(
                width: 28,
                height: 28,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: AnimatedRotation(
                        turns: _isPanelOpen ? 0.125 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.add,
                          size: 22,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (_selectedFiles.isNotEmpty)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.persian,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Center(
                            child: Text(
                              _selectedFiles.length > 9
                                  ? '9+'
                                  : '${_selectedFiles.length}',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Prompt maker button
            PromptMakerWidget(
              hasText: _hasText,
              inputController: _inputController,
              onPromptImproved: (String text) {
                setState(() {
                  _inputController.text = text;
                  _hasText = text.isNotEmpty;
                });
              },
              selectedProvider: _selectedProvider,
              selectedModel: _selectedModel,
              chatService: _chatService,
            ),
            const SizedBox(width: 8),
            // Text field
            Expanded(
              child: Focus(
                onKeyEvent: (node, event) {
                  if (_isDesktop &&
                      event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter) {
                    if (!HardwareKeyboard.instance.isShiftPressed) {
                      _sendMessage();
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: AppStrings.chatPlaceholder,
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  maxLines: 6,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  onChanged: (value) => setState(() => _hasText = value.trim().isNotEmpty),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Mic button (only when no text)
            if (!_hasText) ...[
              VoiceInputWidget(
                onTranscript: (text) {
                  setState(() {
                    _inputController.text = text;
                    _hasText = text.isNotEmpty;
                  });
                },
                onCancel: () {},
              ),
              const SizedBox(width: 8),
            ],
            // Send button
            AnimatedBuilder(
              animation: _sendButtonAnimController,
              builder: (context, child) {
                return GestureDetector(
                  onTapDown: _hasText
                      ? (_) {
                          _sendButtonAnimController.animateTo(
                            0.88,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                          );
                        }
                      : null,
                  onTapUp: _hasText
                      ? (_) {
                          final simulation = SpringSimulation(
                            MioAnimations.spring,
                            _sendButtonAnimController.value,
                            1.0,
                            0,
                          );
                          _sendButtonAnimController.animateWith(simulation);
                          _sendMessage();
                        }
                      : null,
                  onTapCancel: _hasText
                      ? () {
                          final simulation = SpringSimulation(
                            MioAnimations.spring,
                            _sendButtonAnimController.value,
                            1.0,
                            0,
                          );
                          _sendButtonAnimController.animateWith(simulation);
                        }
                      : null,
                  child: Transform.scale(
                    scale: _sendButtonAnimController.value,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _hasText
                            ? AppColors.persian
                            : const Color(0xFF9CA3AF),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}
