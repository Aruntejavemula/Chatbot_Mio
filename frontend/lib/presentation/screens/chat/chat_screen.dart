
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../../core/utils/funny_warnings.dart';
import '../../../core/utils/router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../widgets/chat/document_viewer_widget.dart';
import '../../widgets/chat/file_upload_widget.dart';
import '../../widgets/chat/token_cap_banner.dart';
import '../../widgets/common/funny_snackbar.dart';
import '../../widgets/common/offline_banner_widget.dart';
import '../../widgets/sidebar/sidebar_widget.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/services/notification_service.dart';
import 'chat_empty_state.dart';
import 'chat_input_bar.dart';
import 'chat_message_list.dart';
import 'chat_top_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? chatId;
  final String? projectId;

  const ChatScreen({super.key, this.chatId, this.projectId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isSidebarOpen = false;
  bool _isModelDropdownOpen = false;
  String _selectedModel = 'Think now';
  String _selectedProvider = '';
  final List<Map<String, dynamic>> _availableModels = [
    {'provider': 'OpenAI', 'model': 'GPT-4o', 'color': const Color(0xFF10A37F)},
    {'provider': 'OpenAI', 'model': 'GPT-4o mini', 'color': const Color(0xFF10A37F)},
    {'provider': 'Anthropic', 'model': 'Claude 4 Sonnet', 'color': const Color(0xFFD97757)},
    {'provider': 'Anthropic', 'model': 'Claude 3.5 Haiku', 'color': const Color(0xFFD97757)},
    {'provider': 'Google', 'model': 'Gemini 2.5 Pro', 'color': const Color(0xFF4285F4)},
    {'provider': 'DeepSeek', 'model': 'DeepSeek R1', 'color': const Color(0xFF4D6BFE)},
    {'provider': 'Ollama', 'model': 'Ollama (Local)', 'color': const Color(0xFF0EA5E9)},
  ];

  late ScrollController _scrollController;
  bool _showScrollButton = false;
  late AnimationController _scrollButtonAnimController;
  late Animation<double> _scrollButtonFadeAnimation;

  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  bool _isOnline = true;

  bool _showDisclaimer = true;
  List<SelectedFileInfo> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _scrollButtonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scrollButtonFadeAnimation = CurvedAnimation(
      parent: _scrollButtonAnimController,
      curve: Curves.easeOut,
    );
    _scrollController.addListener(_onScrollChanged);

    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() {
          _showDisclaimer = !(prefs.getBool('disclaimer_dismissed') ?? false);
        });
      }
    });

    _isOnline = ConnectivityService.instance.isOnline.value;
    ConnectivityService.instance.isOnline.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ConnectivityService.instance.isOnline.removeListener(_onConnectivityChanged);
    _scrollController.dispose();
    _scrollButtonAnimController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
  }

  void _onConnectivityChanged() {
    if (mounted) {
      setState(() => _isOnline = ConnectivityService.instance.isOnline.value);
    }
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

  void _sendMessage(String text, List<SelectedFileInfo> files) {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      FunnySnackbar.show(context, FunnyWarnings.signInRequired, type: SnackbarType.warning);
      return;
    }
    if (_selectedModel == 'Think now') {
      FunnySnackbar.show(context, FunnyWarnings.modelNotSelected, type: SnackbarType.warning);
      return;
    }

    setState(() => _selectedFiles = []);
    debugPrint('Send: $text with model: $_selectedModel provider: $_selectedProvider');
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
                title: Text('Rename chat', style: TextStyle(color: textColor)),
                onTap: () => Navigator.pop(sheetContext),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete chat', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: 8),
              Container(height: 1, color: borderColor),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.settings_outlined, color: textColor),
                title: Text('Settings', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.settings);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onModelSelected(String model, String provider) {
    setState(() {
      _selectedModel = model;
      _selectedProvider = provider;
      _isModelDropdownOpen = false;
    });
  }

  Widget _buildDisclaimerPill(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
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
              "AI can make mistakes. Don't rely on it for medical or legal advice.",
              style: TextStyle(
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

  Widget _buildModelDropdown(bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

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
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableModels.length,
            itemBuilder: (context, index) {
              final model = _availableModels[index];
              final isSelected = _selectedModel == model['model'];
              return InkWell(
                onTap: () => _onModelSelected(
                  model['model'] as String,
                  model['provider'] as String,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: model['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        model['model'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? AppColors.persian : textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check, size: 16, color: AppColors.persian),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final isStreaming = ref.watch(isStreamingProvider);
    final tokenCap = ref.watch(tokenCapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    final showPermanentSidebar = Responsive.isDesktop(context) ||
        (Responsive.isTablet(context) && Responsive.isLandscape(context));
    final sidebarWidth = Responsive.isDesktop(context) ? 300.0 : AppSizes.sidebarWidth;
    final hasMessages = messages.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.bgPrimary,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
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
                          ChatTopBar(
                            isDark: isDark,
                            showPermanentSidebar: showPermanentSidebar,
                            chatId: widget.chatId,
                            selectedModel: _selectedModel,
                            isModelDropdownOpen: _isModelDropdownOpen,
                            onToggleSidebar: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                            onToggleModelDropdown: () => setState(() => _isModelDropdownOpen = !_isModelDropdownOpen),
                            onNewChat: () => context.go(AppRoutes.chat),
                            onShareChat: _shareChat,
                            onShowMoreOptions: () => _showMoreOptionsSheet(isDark),
                          ),
                          Expanded(
                            child: messages.isEmpty && !isStreaming
                                ? ChatEmptyState(
                                    isDark: isDark,
                                    isDesktop: showPermanentSidebar,
                                    selectedFiles: _selectedFiles,
                                    onRemoveFile: (index) => setState(() => _selectedFiles.removeAt(index)),
                                    inputBar: ChatInputBar(
                                      selectedFiles: _selectedFiles,
                                      hasMessages: hasMessages,
                                      onSend: _sendMessage,
                                      onAttachFile: _pickAttachFile,
                                      onShowModelSelector: () => setState(() => _isModelDropdownOpen = !_isModelDropdownOpen),
                                    ),
                                    onSuggestionTap: (label) {},
                                    onTapBackground: () {
                                      if (_isModelDropdownOpen) setState(() => _isModelDropdownOpen = false);
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : Column(
                                    children: [
                                      Expanded(
                                        child: ChatMessageList(
                                          scrollController: _scrollController,
                                          isDark: isDark,
                                        ),
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
                                          onRemoveFile: (index) => setState(() => _selectedFiles.removeAt(index)),
                                          isDark: isDark,
                                        ),
                                      ChatInputBar(
                                        selectedFiles: _selectedFiles,
                                        hasMessages: hasMessages,
                                        onSend: _sendMessage,
                                        onAttachFile: _pickAttachFile,
                                        onShowModelSelector: () => setState(() => _isModelDropdownOpen = !_isModelDropdownOpen),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (_isModelDropdownOpen) _buildModelDropdown(isDark),
                    if (!showPermanentSidebar && _isSidebarOpen)
                      SidebarWidget(
                        isOpen: _isSidebarOpen,
                        onClose: () => setState(() => _isSidebarOpen = false),
                        onNewChat: () {
                          setState(() => _isSidebarOpen = false);
                          context.go(AppRoutes.chat);
                        },
                      ),
                    if (_showScrollButton)
                      Positioned(
                        right: 16,
                        bottom: 80 + MediaQuery.of(context).viewPadding.bottom,
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
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
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
}
