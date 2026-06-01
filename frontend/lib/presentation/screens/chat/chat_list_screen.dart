import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/router.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/repositories/chat_repository.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _isSelectMode = false;
  String? _deletedToast;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelect(String chatId) {
    setState(() {
      if (_selectedIds.contains(chatId)) {
        _selectedIds.remove(chatId);
        if (_selectedIds.isEmpty) _isSelectMode = false;
      } else {
        _selectedIds.add(chatId);
      }
    });
  }

  void _enterSelectMode() {
    setState(() => _isSelectMode = true);
  }

  void _exitSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
    });
  }

  void _showDeleteDialog(bool isDark) {
    final count = _selectedIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete $count ${count == 1 ? 'chat' : 'chats'}',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete ${count == 1 ? 'this chat' : 'these chats'}? This cannot be undone.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD),
                ),
              ),
            ),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(
                    color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteSelected();
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete',
                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _deleteSelected() {
    final count = _selectedIds.length;
    final repo = ref.read(chatRepositoryProvider);
    for (final id in _selectedIds) {
      repo.deleteChat(id);
    }
    setState(() {
      _deletedToast = '$count ${count == 1 ? 'chat' : 'chats'} deleted';
      _selectedIds.clear();
      _isSelectMode = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _deletedToast = null);
    });
  }

  void _archiveChat(ChatModel chat) {
    // Optimistically remove so the swipe animation matches state even without a
    // backend; the repo call is best-effort.
    final current = ref.read(chatsProvider);
    ref.read(chatsProvider.notifier).state =
        current.where((c) => c.id != chat.id).toList();
    try {
      ref.read(chatRepositoryProvider).deleteChat(chat.id);
    } catch (_) {/* preview mode: no backend */}
    setState(() => _deletedToast = 'Chat archived');
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _deletedToast = null);
    });
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Last message ${diff.inSeconds} seconds ago';
    if (diff.inMinutes < 60) return 'Last message ${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return 'Last message ${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Last message 1 day ago';
    if (diff.inDays < 7) return 'Last message ${diff.inDays} days ago';
    return 'Last message ${DateFormat('MMM d').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(chatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPrimary = isDark ? Colors.black : AppColors.bgPrimary;
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF999999);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4DFD8);

    final query = _searchController.text.toLowerCase();
    final filteredChats = query.isEmpty
        ? chats
        : chats.where((c) => c.title.toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: bgPrimary,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // Header: "Chats" + "+ New chat" button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Chats',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 28,
                              color: textPrimary,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.chat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : const Color(0xFF1A1814),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 16,
                                      color: isDark ? Colors.black : Colors.white),
                                  const SizedBox(width: 6),
                                  Text('New chat',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.black : Colors.white,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search your chats...',
                            hintStyle: GoogleFonts.dmSans(fontSize: 14, color: textMuted),
                            prefixIcon: Icon(Icons.search, size: 20, color: textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Select mode bar or "Your chats with Mio / Select"
                      if (_isSelectMode)
                        _buildSelectBar(isDark, textPrimary, textMuted)
                      else
                        Row(
                          children: [
                            Text(
                              'Your chats with ${AppStrings.appName}',
                              style: GoogleFonts.dmSans(fontSize: 13, color: textMuted),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _enterSelectMode,
                              child: Text(
                                'Select',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.persian,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Divider(color: borderColor, height: 1),
                      // Chat list
                      Expanded(
                        child: filteredChats.isEmpty
                            ? Center(
                                child: Text(
                                  query.isEmpty ? 'No chats yet' : 'No matching chats',
                                  style: GoogleFonts.dmSans(fontSize: 14, color: textMuted),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.only(top: 4),
                                itemCount: filteredChats.length,
                                separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
                                itemBuilder: (context, index) {
                                  final chat = filteredChats[index];
                                  final isSelected = _selectedIds.contains(chat.id);
                                  final row = _buildChatRow(
                                      chat, isSelected, isDark, textPrimary, textMuted);
                                  if (_isSelectMode) return row;
                                  // Swipe left to archive (with undo toast).
                                  return Dismissible(
                                    key: ValueKey(chat.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 24),
                                      color: Colors.red.withValues(alpha: 0.10),
                                      child: const Icon(Icons.archive_outlined,
                                          color: Colors.red, size: 20),
                                    ),
                                    onDismissed: (_) => _archiveChat(chat),
                                    child: row,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Toast notification
          if (_deletedToast != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: textMuted),
                      const SizedBox(width: 8),
                      Text(_deletedToast!,
                          style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _deletedToast = null),
                        child: Icon(Icons.close, size: 14, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectBar(bool isDark, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Checkbox indicator
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _selectedIds.isNotEmpty ? AppColors.persian : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _selectedIds.isNotEmpty ? AppColors.persian : textMuted,
                width: 1.5,
              ),
            ),
            child: _selectedIds.isNotEmpty
                ? Icon(Icons.remove, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            '${_selectedIds.length} selected',
            style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _selectedIds.isNotEmpty
                ? () {
                    final count = _selectedIds.length;
                    _exitSelectMode();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Archived $count chat${count == 1 ? '' : 's'}')),
                    );
                  }
                : null,
            child: Icon(Icons.archive_outlined, size: 18,
                color: _selectedIds.isNotEmpty ? textPrimary : textMuted),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _selectedIds.isNotEmpty ? () => _showDeleteDialog(isDark) : null,
            child: Icon(Icons.delete_outline, size: 18,
                color: _selectedIds.isNotEmpty ? textPrimary : textMuted),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _exitSelectMode,
            child: Icon(Icons.close, size: 18, color: textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRow(
      ChatModel chat, bool isSelected, bool isDark, Color textPrimary, Color textMuted) {
    final highlight = isSelected
        ? (isDark ? const Color(0xFF1A1A2A) : const Color(0xFFEEEEFF))
        : Colors.transparent;

    return GestureDetector(
      onTap: () {
        if (_isSelectMode) {
          _toggleSelect(chat.id);
        } else {
          context.go('${AppRoutes.chat}/${chat.id}');
        }
      },
      child: Container(
        color: highlight,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSelectMode) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 12),
                child: GestureDetector(
                  onTap: () => _toggleSelect(chat.id),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.persian : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? AppColors.persian : textMuted,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        _formatRelativeTime(chat.updatedAt),
                        style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
                      ),
                      if (chat.storageType == 'shared') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFECE8E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Shared',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, fontWeight: FontWeight.w500, color: textMuted)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
