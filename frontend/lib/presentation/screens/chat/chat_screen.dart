import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/loading_words.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/connectivity_service.dart';
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
import '../../widgets/chat/thinking_block_widget.dart';
import '../../widgets/chat/token_cap_banner.dart';
import '../../widgets/chat/voice_input_widget.dart';
import '../../widgets/common/funny_snackbar.dart';
import '../../widgets/common/shaking_hands.dart';
import '../../widgets/common/offline_banner_widget.dart';
import '../../widgets/sidebar/sidebar_widget.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/services/notification_service.dart';
import '../../widgets/settings/ollama_setup_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? chatId;
  final String? projectId;
  const ChatScreen({super.key, this.chatId, this.projectId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
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
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  late AnimationController _scrollButtonAnimController;
  late Animation<double> _scrollButtonFadeAnimation;
  bool _showDisclaimer = true;
  bool _isOnline = true;
  final LayerLink _plusLayerLink = LayerLink();
  OverlayEntry? _plusOverlay;
  bool _webSearchActive = false;

  final List<Map<String, dynamic>> _availableModels = [
    {'provider': 'OpenAI', 'model': 'GPT-4o', 'color': const Color(0xFF10A37F)},
    {'provider': 'OpenAI', 'model': 'GPT-4o mini', 'color': const Color(0xFF10A37F)},
    {'provider': 'Anthropic', 'model': 'Claude 4 Sonnet', 'color': const Color(0xFFD97757)},
    {'provider': 'Anthropic', 'model': 'Claude 3.5 Haiku', 'color': const Color(0xFFD97757)},
    {'provider': 'Google', 'model': 'Gemini 2.5 Pro', 'color': const Color(0xFF4285F4)},
    {'provider': 'DeepSeek', 'model': 'DeepSeek R1', 'color': const Color(0xFF4D6BFE)},
    {'provider': 'Ollama', 'model': 'Ollama (Local)', 'color': const Color(0xFF0EA5E9)},
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
    WidgetsBinding.instance.addObserver(this);
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
    // Load disclaimer dismissed state
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() {
          _showDisclaimer = !(prefs.getBool('disclaimer_dismissed') ?? false);
        });
      }
    });
    // Listen to connectivity changes
    _isOnline = ConnectivityService.instance.isOnline.value;
    ConnectivityService.instance.isOnline.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ConnectivityService.instance.isOnline.removeListener(_onConnectivityChanged);
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _sendButtonAnimController.dispose();
    _scrollButtonAnimController.dispose();
    _plusOverlay?.remove();
    _plusOverlay = null;
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (mounted) {
      setState(() {
        _isOnline = ConnectivityService.instance.isOnline.value;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
  }

  void _togglePanel() {
    if (_isMobile) HapticFeedback.lightImpact();
    setState(() => _isPanelOpen = !_isPanelOpen);
  }

  Future<void> _showAttachMenu(BuildContext ctx) async {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final box = ctx.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    final offset = box?.localToGlobal(Offset.zero, ancestor: overlay) ?? Offset.zero;
    final size = box?.size ?? Size.zero;

    final result = await showMenu<String>(
      context: ctx,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 52,
        overlay.size.width - offset.dx - size.width,
        overlay.size.height - offset.dy,
      ),
      elevation: 4,
      color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
      items: [
        PopupMenuItem<String>(
          value: 'files',
          height: 40,
          child: Row(children: [
            Icon(Icons.attach_file_outlined, size: 16,
                color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333)),
            const SizedBox(width: 10),
            Text('Upload file',
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A))),
          ]),
        ),
        if (!kIsWeb)
          PopupMenuItem<String>(
            value: 'photo',
            height: 40,
            child: Row(children: [
              Icon(Icons.photo_library_outlined, size: 16,
                  color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333)),
              const SizedBox(width: 10),
              Text('Photo library',
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A))),
            ]),
          ),
      ],
    );

    if (result == 'files') await _pickAttachFile();
    if (result == 'photo') await _pickAttachPhoto();
  }

  Future<void> _pickAttachFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'md', 'csv', 'py', 'js', 'ts', 'dart', 'json', 'yaml'],
    );
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      if (f.path != null) {
        final codeExts = {'py', 'js', 'ts', 'dart', 'json', 'yaml'};
        final ext = f.extension ?? '';
        setState(() {
          _selectedFiles.add(SelectedFileInfo(
            name: f.name,
            path: f.path!,
            sizeBytes: f.size,
            type: codeExts.contains(ext) ? SelectedFileType.code : SelectedFileType.document,
          ));
        });
      }
    }
  }

  Future<void> _pickAttachPhoto() async {
    // On non-web mobile only — image_picker not available on web
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      if (f.path != null) {
        setState(() {
          _selectedFiles.add(SelectedFileInfo(
            name: f.name,
            path: f.path!,
            sizeBytes: f.size,
            type: SelectedFileType.image,
          ));
        });
      }
    }
  }

  void _hidePlusMenu() {
    _plusOverlay?.remove();
    _plusOverlay = null;
    setState(() => _isPanelOpen = false);
  }

  void _showPlusMenu() {
    if (_plusOverlay != null) {
      _hidePlusMenu();
      return;
    }
    setState(() => _isPanelOpen = true);
    const mutedColor = Color(0xFF8E8E93);
    const dividerColor = Color(0xFF3A3A3C);

    _plusOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Full-screen dismiss layer
          Positioned.fill(
            child: GestureDetector(
              onTap: _hidePlusMenu,
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _plusLayerLink,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            offset: const Offset(-8, -8),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: AppColors.darkBgTertiary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _plusItem(icon: Icons.attach_file_rounded, label: 'Add files or photos',
                          onTap: () { _hidePlusMenu(); _pickAttachFile(); }),
                      _plusDivider(dividerColor),
                      _plusItem(icon: Icons.folder_outlined, label: 'Add to project',
                          hasArrow: true, onTap: _hidePlusMenu),
                      _plusDivider(dividerColor),
                      _plusItem(icon: Icons.grid_view_rounded, label: 'Skills',
                          hasArrow: true, onTap: _hidePlusMenu),
                      _plusDivider(dividerColor),
                      _plusItem(icon: Icons.cable_outlined, label: 'Connectors',
                          hasArrow: true, onTap: _hidePlusMenu),
                      _plusDivider(dividerColor),
                      _plusItem(icon: Icons.extension_outlined, label: 'Plugins',
                          textColor: mutedColor, disabled: true, onTap: null),
                      _plusDivider(dividerColor),
                      _plusItem(icon: Icons.science_outlined, label: 'Research',
                          onTap: _hidePlusMenu),
                      _plusDivider(dividerColor),
                      StatefulBuilder(
                        builder: (_, setLocal) => _plusItem(
                          icon: Icons.language_outlined,
                          label: 'Web search',
                          trailing: _webSearchActive
                              ? const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF34C759))
                              : null,
                          onTap: () {
                            setState(() => _webSearchActive = !_webSearchActive);
                            _plusOverlay?.markNeedsBuild();
                          },
                        ),
                      ),
                      _plusDivider(dividerColor),
                      _plusItem(icon: Icons.edit_outlined, label: 'Use style',
                          hasArrow: true, isLast: true, onTap: _hidePlusMenu),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_plusOverlay!);
  }

  Widget _plusItem({
    required IconData icon,
    required String label,
    Color textColor = Colors.white,
    bool hasArrow = false,
    bool disabled = false,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 15, color: textColor, fontWeight: FontWeight.w400)),
            ),
            if (trailing != null)
              trailing
            else if (hasArrow)
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF636366)),
          ],
        ),
      ),
    );
  }

  Widget _plusDivider(Color color) =>
      Divider(height: 1, thickness: 1, indent: 50, endIndent: 0, color: color);

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
    final streamingThinkingText = ref.watch(streamingThinkingTextProvider);
    final isThinkingStreaming = ref.watch(isThinkingStreamingProvider);
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

    ref.listen<bool>(isStreamingProvider, (previous, current) {
      if (previous == true && current == false) {
        if (_appLifecycleState == AppLifecycleState.paused ||
            _appLifecycleState == AppLifecycleState.inactive) {
          NotificationService.requestPermission().then((_) {
            NotificationService.showTaskComplete('AI Response');
          });
        }
      }
    });

    if (messages.isNotEmpty || isStreaming) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.bgPrimary,
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
                          if (!_isOnline) const OfflineBannerWidget(),
                          _buildTopBar(isDark, showPermanentSidebar: showPermanentSidebar),
                          Expanded(
                            child: messages.isEmpty && !isStreaming
                                ? _buildEmptyState(isDark)
                                : Column(
                                    children: [
                                      Expanded(
                                        child: _buildMessagesList(
                                          isDark, messages, isStreaming, streamingText,
                                          loadingWordIndex, streamingThinkingText, isThinkingStreaming),
                                      ),
                                      if (_showDisclaimer) _buildDisclaimerPill(isDark),
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
                                          onRemoveFile: (int index) => setState(() => _selectedFiles.removeAt(index)),
                                          isDark: isDark,
                                        ),
                                      _buildInputBar(isDark),
                                    ],
                                  ),
                          ),
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
    final circleBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final circleBorder = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE);

    final bool isEmptyState = widget.chatId == null && currentChat == null && messages.isEmpty;
    final bool hasMessages = messages.isNotEmpty;

    return Container(
      height: AppSizes.topBarHeight,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : AppColors.bgPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Left: sidebar toggle (circular button)
            if (!showPermanentSidebar)
              GestureDetector(
                onTap: () => setState(() => _isSidebarOpen = true),
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
            // Center: model selector or chat title
            Expanded(
              child: Center(
                child: isEmptyState || !hasMessages
                    ? GestureDetector(
                        onTap: () => setState(() => _isModelDropdownOpen = !_isModelDropdownOpen),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedModel == 'Think now' ? 'Select model' : _selectedModel,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: _isModelDropdownOpen ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textMuted),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.persian),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
              ),
            ),
            // Right: new chat or more options (circular button)
            if (isEmptyState || !hasMessages)
              GestureDetector(
                onTap: () => context.go(AppRoutes.chat),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasMessages && widget.chatId != null && widget.chatId!.isNotEmpty)
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
                        child: Icon(Icons.download_outlined, size: 20, color: textMuted),
                      ),
                    ),
                  if (hasMessages)
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
                              child: Text('Share',
                                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted)),
                            )
                          : GestureDetector(
                              onTap: _shareChat,
                              child: Icon(Icons.ios_share_outlined, size: 20, color: textMuted),
                            ),
                    ),
                  GestureDetector(
                    onTap: () => _showMoreOptionsSheet(isDark),
                    child: Icon(Icons.more_horiz_rounded, size: 20, color: textMuted),
                  ),
                ],
              ),
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

  Widget _buildModelSelectorBar(bool isDark) => const SizedBox.shrink();

  Widget _buildModelDropdown(bool isDark) {
    return Positioned(
      bottom: 90 + MediaQuery.of(context).viewPadding.bottom,
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
                    onTap: () async {
                      setState(() {
                        _selectedModel = model['model'] as String;
                        _selectedProvider = model['provider'] as String;
                        _isModelDropdownOpen = false;
                      });
                      if (model['provider'] == 'Ollama') {
                        try {
                          const storage = FlutterSecureStorage();
                          final savedUrl = await storage.read(key: 'ollama_url');
                          if (savedUrl == null || savedUrl.isEmpty) {
                            if (!mounted) return;
                            await OllamaSetupSheet.show(context);
                          }
                        } catch (_) {
                          if (!mounted) return;
                          await OllamaSetupSheet.show(context);
                        }
                      }
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
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_isModelDropdownOpen) setState(() => _isModelDropdownOpen = false);
              FocusScope.of(context).unfocus();
            },
            behavior: HitTestBehavior.translucent,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ShakingHands(size: 48, animate: false),
                    const SizedBox(height: 24),
                    Text(
                      _getTimeGreeting(),
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 28,
                        height: 1.3,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_selectedFiles.isNotEmpty)
          DocumentViewerWidget(
            files: _selectedFiles,
            onRemoveFile: (int index) => setState(() => _selectedFiles.removeAt(index)),
            isDark: isDark,
          ),
        _buildInputBar(isDark),
      ],
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'How can I help you\nthis morning?';
    if (hour >= 12 && hour < 17) return 'How can I help you\nthis afternoon?';
    if (hour >= 17 && hour < 21) return 'How can I help you\nthis evening?';
    return 'How can I help you\nthis late night?';
  }

  Widget _buildMessagesList(
    bool isDark,
    List messages,
    bool isStreaming,
    String streamingText,
    int loadingWordIndex,
    String streamingThinkingText,
    bool isThinkingStreaming,
  ) {
    return ListView.builder(
      controller: _scrollController,
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
        return Align(
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
                  Text(
                    '${LoadingWords.getWord(loadingWordIndex)}...',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  )
                else if (streamingText.isNotEmpty)
                  Text(
                    streamingText,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisclaimerPill(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBgSecondary
            : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'AI can make mistakes. Don\'t rely on it for medical or legal advice.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              setState(() => _showDisclaimer = false);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('disclaimer_dismissed', true);
            },
            child: Icon(
              Icons.close,
              size: 16,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : AppColors.bgPrimary,
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).viewPadding.bottom),
      child: _buildInputContent(isDark),
    );
  }

  Widget _buildInputContent(bool isDark) {
    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF999999);
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final inputBg = isDark ? const Color(0xFF141414) : const Color(0xFFF0ECE5);
    final borderColor = _isFocused
        ? AppColors.persian.withValues(alpha: 0.4)
        : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DBD2));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: Focus(
              onKeyEvent: (node, event) {
                if (_isDesktop && event is KeyDownEvent &&
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
                  hintText: 'Chat with ${AppStrings.appName}',
                  hintStyle: GoogleFonts.dmSans(fontSize: 15, color: textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: GoogleFonts.dmSans(fontSize: 15, color: textPrimary),
                maxLines: 6,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                onChanged: (value) => setState(() => _hasText = value.trim().isNotEmpty),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CompositedTransformTarget(
                  link: _plusLayerLink,
                  child: GestureDetector(
                    onTap: _showPlusMenu,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.add, size: 22,
                          color: _isPanelOpen ? AppColors.persian : textMuted),
                    ),
                  ),
                ),
                const Spacer(),
                if (!_hasText) ...[
                  VoiceInputWidget(
                    onTranscript: (text) => setState(() {
                      _inputController.text = text;
                      _hasText = text.isNotEmpty;
                    }),
                    onCancel: () {},
                  ),
                  const SizedBox(width: 8),
                ],
                AnimatedBuilder(
                  animation: _sendButtonAnimController,
                  builder: (context, child) {
                    return GestureDetector(
                      onTapDown: _hasText
                          ? (_) => _sendButtonAnimController.animateTo(0.88,
                              duration: const Duration(milliseconds: 150), curve: Curves.easeOut)
                          : null,
                      onTapUp: _hasText
                          ? (_) {
                              final sim = SpringSimulation(MioAnimations.spring,
                                  _sendButtonAnimController.value, 1.0, 0);
                              _sendButtonAnimController.animateWith(sim);
                              _sendMessage();
                            }
                          : null,
                      onTapCancel: _hasText
                          ? () {
                              final sim = SpringSimulation(MioAnimations.spring,
                                  _sendButtonAnimController.value, 1.0, 0);
                              _sendButtonAnimController.animateWith(sim);
                            }
                          : null,
                      child: Transform.scale(
                        scale: _sendButtonAnimController.value,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            color: _hasText
                                ? (isDark ? Colors.white : const Color(0xFF1A1814))
                                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFD6D0C6)),
                          ),
                          child: Center(
                            child: Icon(Icons.arrow_upward_rounded, size: 18,
                                color: _hasText
                                    ? (isDark ? Colors.black : Colors.white)
                                    : textMuted),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
