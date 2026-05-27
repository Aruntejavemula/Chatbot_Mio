import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/router.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../screens/projects/create_project_sheet.dart';
import 'chat_item.dart';

final projectsProvider = StateProvider<List<ProjectModel>>((ref) => []);

class SidebarWidget extends ConsumerStatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onNewChat;
  final bool permanent;

  const SidebarWidget({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onNewChat,
    this.permanent = false,
  });

  @override
  ConsumerState<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends ConsumerState<SidebarWidget>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: MioAnimations.standard);
    _slideAnimation = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: MioAnimations.curve));
  }

  @override
  void didUpdateWidget(covariant SidebarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) _slideController.forward();
    else if (!widget.isOpen && oldWidget.isOpen) _slideController.reverse();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<dynamic>>> _groupChatsByDate(List<dynamic> chats) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final last7Days = today.subtract(const Duration(days: 7));
    final last30Days = today.subtract(const Duration(days: 30));
    final Map<String, List<dynamic>> groups = {};
    for (final chat in chats) {
      final chatDate = DateTime(chat.updatedAt.year, chat.updatedAt.month, chat.updatedAt.day);
      String group;
      if (chatDate == today) group = 'TODAY';
      else if (chatDate == yesterday) group = 'YESTERDAY';
      else if (chatDate.isAfter(last7Days)) group = 'LAST 7 DAYS';
      else if (chatDate.isAfter(last30Days)) group = 'LAST 30 DAYS';
      else group = 'OLDER';
      groups.putIfAbsent(group, () => []);
      groups[group]!.add(chat);
    }
    const order = ['TODAY', 'YESTERDAY', 'LAST 7 DAYS', 'LAST 30 DAYS', 'OLDER'];
    return order.where((k) => groups.containsKey(k)).map((k) => MapEntry(k, groups[k]!)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(chatsProvider);
    final currentChat = ref.watch(currentChatProvider);
    ref.watch(isAuthenticatedProvider);
    ref.watch(themeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = widget.permanent || constraints.maxWidth >= 768;
        if (isDesktop) {
          return _buildContent(isDark: isDark, chats: chats, currentChat: currentChat,
              currentUser: currentUser, isMobile: false,
              width: widget.permanent ? constraints.maxWidth : AppSizes.sidebarWidth);
        }
        if (!widget.isOpen) return const SizedBox.shrink();
        final screenWidth = MediaQuery.of(context).size.width;
        final sidebarWidth = (screenWidth - 60) < 320 ? screenWidth - 60 : 320.0;
        return Stack(
          children: [
            GestureDetector(
              onTap: widget.onClose,
              child: Container(width: double.infinity, height: double.infinity,
                  color: Colors.black.withValues(alpha: 0.5)),
            ),
            SlideTransition(
              position: _slideAnimation,
              child: _buildContent(isDark: isDark, chats: chats, currentChat: currentChat,
                  currentUser: currentUser, isMobile: true, width: sidebarWidth),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent({
    required bool isDark,
    required List chats,
    required dynamic currentChat,
    required dynamic currentUser,
    required bool isMobile,
    required double width,
  }) {
    final bg = isDark ? Colors.black : AppColors.bgPrimary;
    final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFECE8E1);
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF888888);

    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
              child: Text('Mio',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 17, color: textPrimary, fontWeight: FontWeight.w400)),
            ),
            // Top nav items
            _navRow(icon: Icons.add, label: 'New chat', textPrimary: textPrimary, textMuted: textMuted,
                onTap: () { widget.onNewChat(); if (isMobile) widget.onClose(); }),
            _navRow(icon: Icons.search, label: 'Search', textPrimary: textPrimary, textMuted: textMuted,
                onTap: () {}),
            _navRow(icon: Icons.tune_outlined, label: 'Customize', textPrimary: textPrimary, textMuted: textMuted,
                onTap: () => context.go(AppRoutes.settings)),
            const SizedBox(height: 8),
            // Section nav
            _navRow(icon: Icons.chat_bubble_outline, label: 'Chats', textPrimary: textPrimary, textMuted: textMuted,
                onTap: () {}),
            _navRow(icon: Icons.folder_outlined, label: 'Projects', textPrimary: textPrimary, textMuted: textMuted,
                onTap: () { context.go(AppRoutes.projects); if (isMobile) widget.onClose(); }),
            _navRow(icon: Icons.auto_awesome_outlined, label: 'Capabilities', textPrimary: textPrimary, textMuted: textMuted,
                onTap: () {}),
            _navRow(
              icon: Icons.code_outlined,
              label: 'Connectors',
              textPrimary: textPrimary,
              textMuted: textMuted,
              onTap: () {},
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFECE8E1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Upgrade',
                    style: GoogleFonts.dmSans(
                        fontSize: 10, fontWeight: FontWeight.w500, color: textMuted)),
              ),
            ),
            const SizedBox(height: 12),
            // Recents
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text('Recents',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted)),
            ),
            Expanded(child: _buildChatList(chats: chats, currentChat: currentChat, textMuted: textMuted, textPrimary: textPrimary, isMobile: isMobile)),
            // Bottom profile
            _buildProfile(isDark: isDark, currentUser: currentUser, textPrimary: textPrimary, textMuted: textMuted, borderColor: borderColor),
          ],
        ),
      ),
    );
  }

  Widget _navRow({
    required IconData icon,
    required String label,
    required Color textPrimary,
    required Color textMuted,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 16, color: textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w400)),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildChatList({
    required List chats,
    required dynamic currentChat,
    required Color textMuted,
    required Color textPrimary,
    required bool isMobile,
  }) {
    final filteredChats = _searchQuery.isEmpty
        ? chats
        : chats.where((c) {
            final q = _searchQuery.toLowerCase();
            return c.title.toLowerCase().contains(q) || c.lastPreview.toLowerCase().contains(q);
          }).toList();

    if (chats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text('No chats yet',
            style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
      );
    }

    if (filteredChats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text('No results', style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
      );
    }

    final grouped = _groupChatsByDate(filteredChats);

    return ListView.builder(
      padding: EdgeInsets.zero,
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      itemCount: grouped.fold<int>(0, (sum, e) => sum + 1 + e.value.length),
      itemBuilder: (context, index) {
        int cur = 0;
        for (final entry in grouped) {
          if (index == cur) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
              child: Text(entry.key,
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: textMuted)),
            );
          }
          cur++;
          if (index < cur + entry.value.length) {
            final chat = entry.value[index - cur];
            return InkWell(
              onTap: () {
                ref.read(currentChatProvider.notifier).state = chat;
                if (isMobile) widget.onClose();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                child: Text(
                  chat.title,
                  style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }
          cur += entry.value.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfile({
    required bool isDark,
    required dynamic currentUser,
    required Color textPrimary,
    required Color textMuted,
    required Color borderColor,
  }) {
    final userName = currentUser?.name;
    final hasName = userName != null && userName.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 1, color: borderColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.persian.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: hasName
                      ? Text(userName[0].toUpperCase(),
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.persian))
                      : Icon(Icons.person, size: 15, color: textMuted),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hasName ? userName : 'Guest',
                        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Free plan',
                        style: GoogleFonts.dmSans(fontSize: 11, color: textMuted)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.settings),
                child: Icon(Icons.settings_outlined, size: 17, color: textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _parseProjectColor(String hexColor) {
    final hex = hexColor.replaceFirst('#', '');
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    return AppColors.persian;
  }
}
