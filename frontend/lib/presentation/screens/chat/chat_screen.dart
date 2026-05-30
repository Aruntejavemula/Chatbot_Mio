import 'dart:io' show File, Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
import '../../../core/utils/slash_commands.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/chat_service.dart';
import '../../widgets/chat/document_viewer_widget.dart';
import '../../widgets/chat/file_upload_widget.dart';
import '../../widgets/chat/export_menu_widget.dart';
import '../../widgets/chat/prompt_maker_widget.dart';
import '../../widgets/chat/streaming_text.dart';
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
  bool _researchActive = false;
  String? _selectedStyle;
  final ImagePicker _imagePicker = ImagePicker();

  final List<Map<String, dynamic>> _availableModels = [
    {'provider': 'OpenAI', 'model': 'GPT-4o', 'color': const Color(0xFF10A37F), 'desc': 'Powerful flagship for complex tasks'},
    {'provider': 'OpenAI', 'model': 'GPT-4o mini', 'color': const Color(0xFF10A37F), 'desc': 'Fast and affordable for everyday use'},
    {'provider': 'Anthropic', 'model': 'Claude 4 Sonnet', 'color': const Color(0xFFD97757), 'desc': 'Smart, balanced model for most work'},
    {'provider': 'Anthropic', 'model': 'Claude 3.5 Haiku', 'color': const Color(0xFFD97757), 'desc': 'Fastest Claude for quick answers'},
    {'provider': 'Google', 'model': 'Gemini 2.5 Pro', 'color': const Color(0xFF4285F4), 'desc': 'Long-context multimodal reasoning'},
    {'provider': 'DeepSeek', 'model': 'DeepSeek R1', 'color': const Color(0xFF4D6BFE), 'desc': 'Open reasoning model with deep thinking'},
    {'provider': 'Ollama', 'model': 'Ollama (Local)', 'color': const Color(0xFF0EA5E9), 'desc': 'Run open models privately on-device'},
  ];

  List<Map<String, dynamic>> get _filteredModels {
    if (_searchQuery.isEmpty) return _availableModels;
    return _availableModels
        .where((m) =>
            (m['model'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (m['provider'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ── Slash commands (Claude Code / Devin style) ──
  String _slashQuery = '';
  List<SlashCommand> get _slashMatches {
    if (!_slashQuery.startsWith('/')) return const [];
    final q = _slashQuery.substring(1).toLowerCase();
    return kSlashCommands
        .where((c) => c.name.substring(1).toLowerCase().startsWith(q))
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

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final size = await File(image.path).length();
      setState(() {
        _selectedFiles.add(SelectedFileInfo(
          name: image.name,
          path: image.path,
          sizeBytes: size,
          type: SelectedFileType.image,
        ));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open photo library')),
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image == null) return;
      final size = await File(image.path).length();
      setState(() {
        _selectedFiles.add(SelectedFileInfo(
          name: image.name,
          path: image.path,
          sizeBytes: size,
          type: SelectedFileType.image,
        ));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open camera')),
        );
      }
    }
  }

  Widget _buildActiveModesBar(bool isDark) {
    final chips = <Widget>[];
    if (_webSearchActive) {
      chips.add(_modeChip(Icons.language_outlined, 'Web search', isDark,
          () => setState(() => _webSearchActive = false)));
    }
    if (_researchActive) {
      chips.add(_modeChip(Icons.science_outlined, 'Research', isDark,
          () => setState(() => _researchActive = false)));
    }
    if (_selectedStyle != null) {
      chips.add(_modeChip(Icons.edit_outlined, _selectedStyle!, isDark,
          () => setState(() => _selectedStyle = null)));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _modeChip(IconData icon, String label, bool isDark, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.persian.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.persian.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.persian),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.persian)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: AppColors.persian.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  void _showStylePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const styles = <Map<String, dynamic>>[
      {'name': 'Normal', 'desc': 'Default tone', 'icon': Icons.chat_bubble_outline},
      {'name': 'Concise', 'desc': 'Short and to the point', 'icon': Icons.short_text},
      {'name': 'Explanatory', 'desc': 'Detailed and educational', 'icon': Icons.school_outlined},
      {'name': 'Formal', 'desc': 'Professional tone', 'icon': Icons.business_center_outlined},
      {'name': 'Creative', 'desc': 'Playful and imaginative', 'icon': Icons.auto_awesome_outlined},
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Response style', style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
              ),
            ),
            ...styles.map((s) {
              final name = s['name'] as String;
              final isSel = (_selectedStyle ?? 'Normal') == name;
              return ListTile(
                leading: Icon(s['icon'] as IconData,
                    color: isSel ? AppColors.persian : (isDark ? Colors.white70 : Colors.black54)),
                title: Text(name, style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                subtitle: Text(s['desc'] as String, style: GoogleFonts.dmSans(
                    fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                trailing: isSel
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.persian, size: 20)
                    : null,
                onTap: () {
                  setState(() => _selectedStyle = name == 'Normal' ? null : name);
                  if (_isMobile) HapticFeedback.selectionClick();
                  Navigator.of(ctx).pop();
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
                      _plusItem(icon: Icons.attach_file_rounded, label: 'Upload file',
                          onTap: () { _hidePlusMenu(); _pickAttachFile(); }),
                      _plusDivider(dividerColor),
                      _plusItem(icon: Icons.photo_library_outlined, label: 'Photos',
                          onTap: () { _hidePlusMenu(); _pickFromGallery(); }),
                      if (!kIsWeb) ...[
                        _plusDivider(dividerColor),
                        _plusItem(icon: Icons.photo_camera_outlined, label: 'Camera',
                            onTap: () { _hidePlusMenu(); _pickFromCamera(); }),
                      ],
                      _plusDivider(dividerColor),
                      _plusItem(icon: Icons.folder_outlined, label: 'Add to project',
                          hasArrow: true, onTap: () { _hidePlusMenu(); context.push(AppRoutes.projects); }),
                      _plusDivider(dividerColor),
                      _plusItem(icon: Icons.grid_view_rounded, label: 'Skills',
                          hasArrow: true, onTap: () { _hidePlusMenu(); context.push(AppRoutes.prompts); }),
                      _plusDivider(dividerColor),
                      _plusItem(icon: Icons.cable_outlined, label: 'Connectors',
                          hasArrow: true, onTap: () { _hidePlusMenu(); context.push(AppRoutes.connectors); }),
                      _plusDivider(dividerColor),
                      _plusItem(icon: Icons.extension_outlined, label: 'Plugins',
                          hasArrow: true, onTap: () { _hidePlusMenu(); context.push(AppRoutes.connectors); }),
                      _plusDivider(dividerColor),
                      StatefulBuilder(
                        builder: (_, setLocal) => _plusItem(
                          icon: Icons.science_outlined,
                          label: 'Research',
                          trailing: _researchActive
                              ? const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF34C759))
                              : null,
                          onTap: () {
                            setState(() => _researchActive = !_researchActive);
                            _plusOverlay?.markNeedsBuild();
                          },
                        ),
                      ),
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
                          isLast: true, onTap: () { _hidePlusMenu(); _showStylePicker(); }),
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

    // Slash commands run locally and never require auth or a selected model.
    final slash = parseSlashCommand(text);
    if (slash != null) {
      if (_isMobile) HapticFeedback.mediumImpact();
      _runSlashCommand(slash);
      return;
    }

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
      _slashQuery = '';
      _selectedFiles = [];
    });
    // TODO: Create chat if needed, then send message
    // For now just print
    debugPrint('Send: $text with model: $_selectedModel provider: $_selectedProvider '
        'webSearch: $_webSearchActive research: $_researchActive style: ${_selectedStyle ?? "normal"}');
  }

  void _runSlashCommand(SlashParseResult slash) {
    _inputController.clear();
    setState(() {
      _hasText = false;
      _slashQuery = '';
    });

    // /clear empties the conversation.
    if (slash.command.name == '/clear') {
      ref.read(messagesProvider.notifier).state = [];
      FunnySnackbar.show(context, 'Conversation cleared', type: SnackbarType.info);
      return;
    }

    final chatId = widget.chatId ?? 'local';
    final now = DateTime.now();
    final userText = slash.argument.isEmpty
        ? slash.command.name
        : '${slash.command.name} ${slash.argument}';
    final userMsg = MessageModel(
      id: 'u-${now.microsecondsSinceEpoch}',
      chatId: chatId,
      role: 'user',
      content: userText,
      createdAt: now,
    );
    final assistantMsg = MessageModel(
      id: 'a-${now.microsecondsSinceEpoch}',
      chatId: chatId,
      role: 'assistant',
      content: slashCommandResponse(slash.command, slash.argument),
      createdAt: now.add(const Duration(milliseconds: 1)),
      model: _selectedModel == 'Think now' ? null : _selectedModel,
    );
    final current = ref.read(messagesProvider);
    ref.read(messagesProvider.notifier).state = [...current, userMsg, assistantMsg];
    _scrollToBottom();
  }

  void _onInputChanged(String value) {
    setState(() {
      _hasText = value.trim().isNotEmpty;
      final firstToken = value.trimLeft().split(' ').first;
      _slashQuery = firstToken.startsWith('/') ? firstToken : '';
    });
  }

  void _applySlashCommand(SlashCommand command) {
    if (command.needsArgument) {
      _inputController.text = '${command.name} ';
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
      setState(() {
        _hasText = true;
        _slashQuery = '';
      });
      _focusNode.requestFocus();
    } else {
      _inputController.text = command.name;
      _sendMessage();
    }
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
                                ? _buildEmptyState(isDark, isDesktop: showPermanentSidebar)
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
                                      _buildActiveModesBar(isDark),
                                      if (showPermanentSidebar)
                                        Center(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 640),
                                            child: Padding(
                                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                              child: _buildInputContent(isDark, isDesktop: true),
                                            ),
                                          ),
                                        )
                                      else
                                        _buildInputBar(isDark),
                                      if (showPermanentSidebar)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Text(
                                            '${AppStrings.appName} is AI and can make mistakes. Please double-check responses.',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 11,
                                              color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
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
            // Left: sidebar toggle (mobile only)
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
            // Center content
            Expanded(
              child: Center(
                child: (isEmptyState || !hasMessages)
                    // Empty state: mobile=model selector, desktop=nothing (model is in input bar)
                    ? (showPermanentSidebar
                        ? const SizedBox.shrink()
                        : GestureDetector(
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
                          ))
                    // Active chat: title with dropdown
                    : GestureDetector(
                        onTap: () => _showMoreOptionsSheet(isDark),
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
                              border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DBD2), width: 1),
                            ),
                            child: GestureDetector(
                              onTap: _shareChat,
                              child: Text('Share',
                                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _shareChat,
                                child: Icon(Icons.ios_share_outlined, size: 20, color: textMuted),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showMoreOptionsSheet(isDark),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  model['model'] as String,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                ),
                                if (model['desc'] != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    model['desc'] as String,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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

  Widget _buildEmptyState(bool isDark, {bool isDesktop = false}) {
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF999999);

    if (!isDesktop) {
      // Mobile: simple mascot + greeting + input bar at bottom
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
                      FadeSlideIn(
                        duration: MioAnimations.slow,
                        child: const ShakingHands(size: 48, animate: false),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        duration: MioAnimations.slow,
                        child: Text(
                          _getTimeGreeting(),
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 28,
                            height: 1.3,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
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
          _buildInputBar(isDark),
        ],
      );
    }

    // Desktop: Claude-style centered greeting + input with model selector + suggestion pills
    final currentUser = ref.watch(currentUserProvider);
    final userName = currentUser?.name;
    final hasName = userName != null && userName.isNotEmpty;
    final firstName = hasName ? userName.split(' ').first : '';

    return GestureDetector(
      onTap: () {
        if (_isModelDropdownOpen) setState(() => _isModelDropdownOpen = false);
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Greeting with mascot inline
                      FadeSlideIn(
                        duration: MioAnimations.slow,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const ShakingHands(size: 40, animate: true),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _getDesktopGreeting(firstName),
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 32,
                                  height: 1.2,
                                  color: textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Input bar with model selector inside
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        duration: MioAnimations.slow,
                        child: _buildInputBar(isDark, isDesktop: true),
                      ),
                      const SizedBox(height: 16),
                      // Suggestion pills
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 350),
                        duration: MioAnimations.slow,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _desktopSuggestionPill(Icons.edit_outlined, 'Write', textPrimary, textMuted, isDark),
                            _desktopSuggestionPill(Icons.auto_awesome_outlined, 'Learn', textPrimary, textMuted, isDark, prefill: '/learn '),
                            _desktopSuggestionPill(Icons.code, 'Code', textPrimary, textMuted, isDark, prefill: '/init '),
                            _desktopSuggestionPill(Icons.home_outlined, 'Life stuff', textPrimary, textMuted, isDark),
                            _desktopSuggestionPill(Icons.lightbulb_outline, "Mio's choice", textPrimary, textMuted, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopSuggestionPill(IconData icon, String label, Color textPrimary, Color textMuted, bool isDark, {String? prefill}) {
    final bg = isDark ? const Color(0xFF111111) : Colors.white;
    final border = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4DFD8);
    return ScaleTap(
      onTap: () {
        final text = prefill ?? label;
        _inputController.text = text;
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        _onInputChanged(text);
        _focusNode.requestFocus();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: MioAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  String _getDesktopGreeting(String name) {
    final hour = DateTime.now().hour;
    final suffix = name.isNotEmpty ? ', $name' : '';
    if (hour >= 5 && hour < 12) return 'Good morning$suffix';
    if (hour >= 12 && hour < 17) return 'Good afternoon$suffix';
    if (hour >= 17 && hour < 21) return 'Good evening$suffix';
    return 'Good evening$suffix';
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
                  const TypingIndicator()
                else if (streamingText.isNotEmpty)
                  StreamingText(
                    text: streamingText,
                    textColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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

  Widget _buildInputBar(bool isDark, {bool isDesktop = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : AppColors.bgPrimary,
      ),
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 0 : 16,
        8,
        isDesktop ? 0 : 16,
        isDesktop ? 0 : 8 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: _buildInputContent(isDark, isDesktop: isDesktop),
    );
  }

  Widget _buildInputContent(bool isDark, {bool isDesktop = false}) {
    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF999999);
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final inputBg = isDark ? const Color(0xFF141414) : const Color(0xFFF0ECE5);
    final borderColor = _isFocused
        ? AppColors.persian.withValues(alpha: 0.4)
        : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DBD2));

    // Desktop: white bg with subtle border; Mobile: warm bg
    final desktopInputBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final effectiveInputBg = isDesktop ? desktopInputBg : inputBg;
    final desktopBorder = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DBD2);
    final effectiveBorder = isDesktop ? (_isFocused ? AppColors.persian.withValues(alpha: 0.4) : desktopBorder) : borderColor;

    // Active chat on desktop: hint says "Reply..." instead of "Chat with Mio"
    final messages = ref.watch(messagesProvider);
    final isActiveChat = messages.isNotEmpty;
    final hintText = (isDesktop && isActiveChat) ? 'Reply...' : 'How can I help you today?';

    final inputBox = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: effectiveInputBg,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        border: Border.all(color: effectiveBorder, width: 1),
        boxShadow: isDesktop ? [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ] : null,
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
                  hintText: hintText,
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
                onChanged: _onInputChanged,
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
                // Desktop: model selector inside input bar
                if (isDesktop) ...[  
                  GestureDetector(
                    onTap: () => setState(() => _isModelDropdownOpen = !_isModelDropdownOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F2ED),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedModel == 'Think now' ? 'Select model' : _selectedModel,
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
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

    if (_slashMatches.isEmpty) return inputBox;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSlashMenu(isDark),
        const SizedBox(height: 8),
        inputBox,
      ],
    );
  }

  Widget _buildSlashMenu(bool isDark) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final border = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DBD2);
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF777777);
    final matches = _slashMatches;
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: matches.length,
        itemBuilder: (context, i) {
          final cmd = matches[i];
          return InkWell(
            onTap: () => _applySlashCommand(cmd),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(cmd.icon, size: 18, color: AppColors.persian),
                  const SizedBox(width: 12),
                  Text(
                    cmd.name,
                    style: GoogleFonts.dmMono(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cmd.description,
                      style: GoogleFonts.dmSans(fontSize: 12.5, color: textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
