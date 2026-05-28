import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/loading_words.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../../core/utils/funny_warnings.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../widgets/chat/document_viewer_widget.dart';
import '../../widgets/chat/file_upload_widget.dart';
import '../../widgets/chat/export_menu_widget.dart';
import '../../widgets/chat/thinking_block_widget.dart';
import '../../widgets/chat/token_cap_banner.dart';
import '../../widgets/chat/voice_input_widget.dart';
import '../../widgets/common/funny_snackbar.dart';
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
  String _searchQuery = '';
  late TextEditingController _inputController;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
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

    final bool isEmptyState = widget.chatId == null && currentChat == null && messages.isEmpty;

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
                  if (!isEmptyState) ...[
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
          child: _buildModelList(isDark),
        ),
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


  Widget _buildEmptyState(bool isDark) {
    final greeting = _getGreeting('');
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Mascot
                    Image.asset('assets/images/mascot.png', width: 72, height: 72),
                    const SizedBox(height: 24),
                    // Greeting
                    Text(
                      greeting,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 22,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    // Mode tiles
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _modeTile('✍️', 'Write', textPrimary, textMuted, isDark),
                          _modeTile('🔍', 'Research', textPrimary, textMuted, isDark),
                          _modeTile('💻', 'Code', textPrimary, textMuted, isDark),
                        ],
                      ),
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
      ],
    );
  }

  Widget _modeTile(String emoji, String label, Color textPrimary, Color textMuted, bool isDark) {
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFEDE9E3);
    final border = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFD8D2CA);
    return GestureDetector(
      onTap: () {
        final starters = {
          'Write': 'Help me write',
          'Research': 'Research topic:',
          'Code': 'Write code for',
        };
        _inputController.text = starters[label] ?? label;
        setState(() => _hasText = true);
        _focusNode.requestFocus();
      },
      child: Container(
        width: 88,
        height: 80,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _greetings = [
    "How can I help?",
    "What's on your mind?",
    "What are we working on?",
    "Ready when you are.",
    "What can I do for you?",
    "Let's get to work.",
  ];

  String _getGreeting(String name) {
    final base = _greetings[DateTime.now().millisecond % _greetings.length];
    return base;
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
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final userTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final userBorder = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DAD2);

    return ListView.builder(
      controller: _scrollController,
      reverse: false,
      padding: const EdgeInsets.symmetric(vertical: 20),
      addAutomaticKeepAlives: false,
      itemCount: messages.length + (isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final message = messages[index];
          final isUser = message.role == 'user';
          final borderColor = isUser ? userBorder : AppColors.persian;
          final label = isUser ? 'YOU' : 'MIO';
          final labelColor = mutedColor;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: borderColor, width: 2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isUser && message.thinkingContent != null && message.thinkingContent!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ThinkingBlockWidget(
                      thinkingContent: message.thinkingContent!,
                      isStreaming: false,
                    ),
                  ),
                if (isUser)
                  SelectableText(
                    message.content,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: userTextColor,
                      height: 1.7,
                    ),
                  )
                else
                  MarkdownBody(
                    data: message.content,
                    selectable: true,
                    onTapLink: (text, href, title) {
                      if (href != null) launchUrl(Uri.parse(href));
                    },
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.dmSans(fontSize: 15, color: textColor, height: 1.7),
                      h1: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
                      h2: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
                      h3: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                      listBullet: GoogleFonts.dmSans(fontSize: 15, color: textColor, height: 1.7),
                      code: GoogleFonts.jetBrainsMono(fontSize: 13, color: textColor, backgroundColor: isDark ? const Color(0xFF111111) : const Color(0xFFF5F1EB)),
                      a: GoogleFonts.dmSans(fontSize: 15, color: AppColors.persian, decoration: TextDecoration.underline),
                      strong: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: textColor, height: 1.7),
                      em: GoogleFonts.dmSans(fontSize: 15, fontStyle: FontStyle.italic, color: textColor, height: 1.7),
                    ),
                  ),
              ],
            ),
          );
        }

        // Streaming message
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.persian, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MIO',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              if (streamingThinkingText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ThinkingBlockWidget(
                    thinkingContent: streamingThinkingText,
                    isStreaming: isThinkingStreaming,
                  ),
                ),
              if (streamingText.isEmpty && streamingThinkingText.isEmpty)
                Text(
                  '${LoadingWords.getWord(loadingWordIndex)}...',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: mutedColor,
                  ),
                )
              else if (streamingText.isNotEmpty)
                MarkdownBody(
                  data: streamingText,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.dmSans(fontSize: 15, color: textColor, height: 1.7),
                    code: GoogleFonts.jetBrainsMono(fontSize: 13, color: textColor, backgroundColor: isDark ? const Color(0xFF111111) : const Color(0xFFF5F1EB)),
                  ),
                ),
            ],
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
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + MediaQuery.of(context).viewPadding.bottom),
      child: _buildInputContent(isDark),
    );
  }

  Widget _buildInputContent(bool isDark) {
    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF999999);
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final inputBg = isDark ? const Color(0xFF0D0D0D) : AppColors.bgPrimary;
    final borderColor = _isFocused
        ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFC8C4BC))
        : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE0DAD2));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Transparent textarea — no inner border, no inner bg
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
                  hintText: 'How can I help you today?',
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
          // Bottom toolbar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // + button with LayerLink anchor
                CompositedTransformTarget(
                  link: _plusLayerLink,
                  child: GestureDetector(
                    onTap: _showPlusMenu,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.add, size: 20,
                          color: _isPanelOpen ? AppColors.persian : textMuted),
                    ),
                  ),
                ),
                const Spacer(),
                // Model selector — plain gray text + chevron only
                GestureDetector(
                  onTap: () => setState(() => _isModelDropdownOpen = !_isModelDropdownOpen),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedModel == 'Think now' ? 'Select model' : _selectedModel,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 3),
                      AnimatedRotation(
                        turns: _isModelDropdownOpen ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down, size: 16, color: textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Mic
                if (!_hasText) ...[
                  VoiceInputWidget(
                    onTranscript: (text) => setState(() {
                      _inputController.text = text;
                      _hasText = text.isNotEmpty;
                    }),
                    onCancel: () {},
                  ),
                  const SizedBox(width: 6),
                ],
                // Send button
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
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _hasText
                                ? AppColors.persian
                                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4DFD8)),
                          ),
                          child: Center(
                            child: Icon(Icons.arrow_upward_rounded, size: 17,
                                color: _hasText ? Colors.white : textMuted),
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
