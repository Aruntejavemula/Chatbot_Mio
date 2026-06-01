import re

with open('lib/presentation/screens/chat/chat_screen.dart', 'r', encoding='utf-8', newline='') as f:
    content = f.read()

# 1. Remove _isModelDropdownOpen field
content = content.replace('  bool _isModelDropdownOpen = false;\n', '')

# 2. Add glow animation controller after _selectedFiles
old_fields = '  bool _showDisclaimer = true;\n  List<SelectedFileInfo> _selectedFiles = [];'
new_fields = '''  bool _showDisclaimer = true;
  List<SelectedFileInfo> _selectedFiles = [];
  late AnimationController _glowController;
  late Animation<Color?> _glowAnimation;'''
content = content.replace(old_fields, new_fields)

# 3. Add glow controller init in initState
old_init = '''    _scrollController.addListener(_onScrollChanged);

    SharedPreferences.getInstance().then((prefs) => {'''
new_init = '''    _scrollController.addListener(_onScrollChanged);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    SharedPreferences.getInstance().then((prefs) => {'''
content = content.replace(old_init, new_init)

# 4. Add glow controller dispose
old_dispose = '''    _scrollController.dispose();
    _scrollButtonAnimController.dispose();
    super.dispose();'''
new_dispose = '''    _scrollController.dispose();
    _scrollButtonAnimController.dispose();
    _glowController.dispose();
    super.dispose();'''
content = content.replace(old_dispose, new_dispose)

# 5. Replace _sendMessage with glow + mock reply
old_send = '''  void _sendMessage(String text, List<SelectedFileInfo> files) {
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
  }'''

new_send = '''  void _sendMessage(String text, List<SelectedFileInfo> files) {
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

    // Add user message
    final userMsg = MessageModel(
      id: 'msg-user-${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chatId ?? 'new-chat',
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );
    final currentMsgs = ref.read(messagesProvider);
    ref.read(messagesProvider.notifier).state = [...currentMsgs, userMsg];

    // Glow animation on send
    _glowAnimation = ColorTween(
      begin: AppColors.persian,
      end: isDark ? const Color(0xFF2A2A2A) : AppColors.borderDefault,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
    ));
    _glowController.forward(from: 0);

    // Mock reply with 2-second loading
    _mockReply(text);
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Future<void> _mockReply(String userText) async {
    ref.read(isStreamingProvider.notifier).state = true;
    ref.read(streamingTextProvider.notifier).state = '';

    // Simulate 2-second thinking/loading
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final mockReplies = [
      "That's a great question! Let me think through this carefully...",
      "I'd be happy to help with that. Here's what I know:",
      "Interesting! Let me provide a thoughtful response.",
      "Great topic. Let me break this down for you.",
    ];
    final reply = mockReplies[userText.length % mockReplies.length];

    // Simulate streaming
    ref.read(streamingTextProvider.notifier).state = reply;
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Finish streaming and add to messages
    final aiMsg = MessageModel(
      id: 'msg-ai-${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chatId ?? 'new-chat',
      role: 'assistant',
      content: reply,
      model: _selectedModel,
      createdAt: DateTime.now(),
    );
    final msgs = ref.read(messagesProvider);
    ref.read(messagesProvider.notifier).state = [...msgs, aiMsg];
    ref.read(isStreamingProvider.notifier).state = false;
    ref.read(streamingTextProvider.notifier).state = '';
  }'''

content = content.replace(old_send, new_send)

# 6. Remove _buildModelDropdown method entirely
pattern = r'  Widget _buildModelDropdown\(bool isDark\) \{.*?\n  \}\n\n  @override\n  Widget build\(BuildContext context\) \{'
new_build = '  @override\n  Widget build(BuildContext context) {'
content = re.sub(pattern, new_build, content, flags=re.DOTALL)

# 7. Remove model dropdown overlay from build
old_dropdown_in_build = '                    if (_isModelDropdownOpen) _buildModelDropdown(isDark),\n'
content = content.replace(old_dropdown_in_build, '')

# 8. Update ChatInputBar calls to pass model data
# First find the empty state inputBar call
old_empty_input = '''                                    inputBar: ChatInputBar(
                                      selectedFiles: _selectedFiles,
                                      hasMessages: hasMessages,
                                      onSend: _sendMessage,
                                      onAttachFile: _pickAttachFile,
                                      onShowModelSelector: () => setState(() => _isModelDropdownOpen = !_isModelDropdownOpen),
                                    ),'''
new_empty_input = '''                                    inputBar: ChatInputBar(
                                      selectedFiles: _selectedFiles,
                                      hasMessages: hasMessages,
                                      selectedModel: _selectedModel,
                                      availableModels: _availableModels,
                                      onSend: _sendMessage,
                                      onAttachFile: _pickAttachFile,
                                      onModelSelected: _onModelSelected,
                                    ),'''
content = content.replace(old_empty_input, new_empty_input)

# 9. Update active chat input bar call
old_active_input = '''                                      ChatInputBar(
                                        selectedFiles: _selectedFiles,
                                        hasMessages: hasMessages,
                                        onSend: _sendMessage,
                                        onAttachFile: _pickAttachFile,
                                        onShowModelSelector: () => setState(() => _isModelDropdownOpen = !_isModelDropdownOpen),
                                      ),'''
new_active_input = '''                                      ChatInputBar(
                                        selectedFiles: _selectedFiles,
                                        hasMessages: hasMessages,
                                        selectedModel: _selectedModel,
                                        availableModels: _availableModels,
                                        onSend: _sendMessage,
                                        onAttachFile: _pickAttachFile,
                                        onModelSelected: _onModelSelected,
                                      ),'''
content = content.replace(old_active_input, new_active_input)

# 10. Remove old top bar model dropdown related params
old_top_bar = '''                          ChatTopBar(
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
                          ),'''
new_top_bar = '''                          ChatTopBar(
                            isDark: isDark,
                            showPermanentSidebar: showPermanentSidebar,
                            chatId: widget.chatId,
                            onToggleSidebar: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                            onNewChat: () => context.go(AppRoutes.chat),
                            onShareChat: _shareChat,
                            onShowMoreOptions: () => _showMoreOptionsSheet(isDark),
                          ),'''
content = content.replace(old_top_bar, new_top_bar)

# 11. Add MessageModel import if missing
if 'import \'../../../data/models/message_model.dart\';' not in content:
    content = content.replace(
        "import '../../../data/repositories/auth_repository.dart';",
        "import '../../../data/models/message_model.dart';\nimport '../../../data/repositories/auth_repository.dart';"
    )

with open('lib/presentation/screens/chat/chat_screen.dart', 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)
print('Updated chat_screen.dart')
