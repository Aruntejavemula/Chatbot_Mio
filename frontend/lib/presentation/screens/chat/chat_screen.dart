import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/loading_words.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/chat_service.dart';
import '../../widgets/chat/file_upload_widget.dart';
import '../../widgets/chat/export_menu_widget.dart';
import '../../widgets/chat/plus_panel_widget.dart';
import '../../widgets/chat/prompt_maker_widget.dart';
import '../../widgets/chat/token_cap_banner.dart';
import '../../widgets/chat/voice_input_widget.dart';
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
  double _sendButtonScale = 1.0;
  bool _isPanelOpen = false;

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
    _sendButtonAnimController.addListener(() {
      setState(() => _sendButtonScale = _sendButtonAnimController.value);
    });
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _sendButtonAnimController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() => _isPanelOpen = !_isPanelOpen);
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    setState(() {
      _hasText = false;
      _selectedFiles = [];
    });
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to chat')),
      );
      return;
    }
    if (_selectedModel == 'Think now') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a model first')),
      );
      return;
    }
    // TODO: Create chat if needed, then send message
    // For now just print
    debugPrint('Send: $text with model: $_selectedModel provider: $_selectedProvider');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
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
                          if (_selectedFiles.isNotEmpty) _buildFilePreviewBar(isDark),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Hamburger pill button (only for phone/tablet-portrait)
            if (!showPermanentSidebar)
              GestureDetector(
                onTap: () => setState(() => _isSidebarOpen = true),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.menu,
                    size: 20,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
            // Export button (only when messages exist and chatId is available)
            if (messages.isNotEmpty && widget.chatId != null && widget.chatId!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12),
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
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ),
            const Spacer(),
            // Ghost mascot pill button
            GestureDetector(
              onTap: () => context.go(AppRoutes.settings),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
                    width: 1,
                  ),
                ),
                // TODO: Replace with mascot image
                child: const Center(
                  child: PenguinMascot(size: 28, animate: false),
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildFilePreviewBar(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _selectedFiles.asMap().entries.map((entry) {
          final index = entry.key;
          final fileInfo = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FileUploadWidget.buildFilePreview(
              fileInfo: fileInfo,
              isDark: isDark,
              onRemove: () {
                setState(() {
                  _selectedFiles.removeAt(index);
                });
              },
            ),
          );
        }).toList(),
      ),
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
            // Plus button with rotation
            GestureDetector(
              onTap: _togglePanel,
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
            GestureDetector(
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
                scale: _sendButtonScale,
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
            ),
          ],
        ),
      ),
    );
  }

}
