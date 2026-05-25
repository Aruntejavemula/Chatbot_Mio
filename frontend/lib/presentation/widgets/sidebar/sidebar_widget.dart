import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
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
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(covariant SidebarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _slideController.forward();
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _slideController.reverse();
    }
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
      final chatDate = DateTime(
        chat.updatedAt.year,
        chat.updatedAt.month,
        chat.updatedAt.day,
      );

      String group;
      if (chatDate == today) {
        group = 'TODAY';
      } else if (chatDate == yesterday) {
        group = 'YESTERDAY';
      } else if (chatDate.isAfter(last7Days)) {
        group = 'LAST 7 DAYS';
      } else if (chatDate.isAfter(last30Days)) {
        group = 'LAST 30 DAYS';
      } else {
        group = 'OLDER';
      }

      groups.putIfAbsent(group, () => []);
      groups[group]!.add(chat);
    }

    const order = ['TODAY', 'YESTERDAY', 'LAST 7 DAYS', 'LAST 30 DAYS', 'OLDER'];
    return order
        .where((key) => groups.containsKey(key))
        .map((key) => MapEntry(key, groups[key]!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(chatsProvider);
    final currentChat = ref.watch(currentChatProvider);
    ref.watch(isAuthenticatedProvider);
    ref.watch(themeProvider);
    final currentUser = ref.watch(currentUserProvider);

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final bgSecondary = isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;
    final bgTertiary = isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary;
    final borderDefault = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = widget.permanent || constraints.maxWidth >= 768;

        if (isDesktop) {
          return _buildSidebarContent(
            width: widget.permanent ? constraints.maxWidth : AppSizes.sidebarWidth,
            bgSecondary: bgSecondary,
            bgTertiary: bgTertiary,
            borderDefault: borderDefault,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            chats: chats,
            currentChat: currentChat,
            currentUser: currentUser,
            isMobile: false,
          );
        }

        // Mobile
        if (!widget.isOpen) {
          return const SizedBox.shrink();
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final sidebarWidth = (screenWidth - 60) < 320 ? screenWidth - 60 : 320.0;

        return Stack(
          children: [
            // Dark overlay
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
            // Sliding sidebar
            SlideTransition(
              position: _slideAnimation,
              child: _buildSidebarContent(
                width: sidebarWidth,
                bgSecondary: bgSecondary,
                bgTertiary: bgTertiary,
                borderDefault: borderDefault,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
                chats: chats,
                currentChat: currentChat,
                currentUser: currentUser,
                isMobile: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebarContent({
    required double width,
    required Color bgSecondary,
    required Color bgTertiary,
    required Color borderDefault,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required List chats,
    required dynamic currentChat,
    required dynamic currentUser,
    required bool isMobile,
  }) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bgSecondary,
        border: Border(
          right: BorderSide(
            color: borderDefault,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top section
            _buildTopSection(
              bgTertiary: bgTertiary,
              borderDefault: borderDefault,
              textSecondary: textSecondary,
              textMuted: textMuted,
              isMobile: isMobile,
            ),
            // Projects section
            _buildProjectsSection(
              textMuted: textMuted,
              borderDefault: borderDefault,
              isMobile: isMobile,
            ),
            // Chat list
            Expanded(
              child: _buildChatList(
                chats: chats,
                currentChat: currentChat,
                textMuted: textMuted,
                isMobile: isMobile,
              ),
            ),
            // Bottom section
            _buildBottomSection(
              bgTertiary: bgTertiary,
              borderDefault: borderDefault,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
              currentUser: currentUser,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection({
    required Color bgTertiary,
    required Color borderDefault,
    required Color textSecondary,
    required Color textMuted,
    required bool isMobile,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // New Chat button
          GestureDetector(
            onTap: () {
              widget.onNewChat();
              if (isMobile) {
                widget.onClose();
              }
            },
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: borderDefault,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    size: 18,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'New chat',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Search bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: bgTertiary,
              border: Border.all(
                color: borderDefault,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 16,
                  color: textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchPlaceholder,
                      hintStyle: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection({
    required Color textMuted,
    required Color borderDefault,
    required bool isMobile,
  }) {
    final bool isProPlan = true;
    if (!isProPlan) return const SizedBox.shrink();

    final projects = ref.watch(projectsProvider);
    if (projects.isEmpty && !isProPlan) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final displayProjects = projects.length > 5 ? projects.sublist(0, 5) : projects;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(
                'PROJECTS',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: textMuted,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: Icon(Icons.add_outlined, color: textMuted, size: 16),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (sheetContext) => CreateProjectSheet(
                        onCreated: (name, color, systemPrompt) {
                          // Placeholder: would call service and refresh
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Project items
          ...displayProjects.map((project) => GestureDetector(
                onTap: () {
                  context.go('/projects/${project.id}');
                  if (isMobile) {
                    widget.onClose();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _parseProjectColor(project.color),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          project.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '0',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          // See all link
          if (projects.length > 5)
            GestureDetector(
              onTap: () {
                context.go(AppRoutes.projects);
                if (isMobile) {
                  widget.onClose();
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'See all',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.persian,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Divider(height: 1, color: borderDefault),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Color _parseProjectColor(String hexColor) {
    final hex = hexColor.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return AppColors.persian;
  }

  Widget _buildChatList({
    required List chats,
    required dynamic currentChat,
    required Color textMuted,
    required bool isMobile,
  }) {
    final filteredChats = _searchQuery.isEmpty
        ? chats
        : chats.where((chat) {
            final query = _searchQuery.toLowerCase();
            return chat.title.toLowerCase().contains(query) ||
                chat.lastPreview.toLowerCase().contains(query);
          }).toList();

    // Empty state - no chats
    if (chats.isEmpty && _searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 32,
              color: textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No chats yet',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: textMuted,
              ),
            ),
          ],
        ),
      );
    }

    // No results state
    if (filteredChats.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 32,
              color: textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No chats found',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final groupedChats = _groupChatsByDate(filteredChats);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: groupedChats.fold<int>(
        0,
        (sum, entry) => sum + 1 + entry.value.length,
      ),
      itemBuilder: (context, index) {
        int currentIndex = 0;
        for (final entry in groupedChats) {
          if (index == currentIndex) {
            // Group header
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                entry.key,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
            );
          }
          currentIndex++;

          if (index < currentIndex + entry.value.length) {
            final chat = entry.value[index - currentIndex];
            return ChatItem(
              chat: chat,
              isSelected: chat.id == currentChat?.id,
              onTap: () {
                ref.read(currentChatProvider.notifier).state = chat;
                if (isMobile) {
                  widget.onClose();
                }
              },
              onDelete: () {
                ref.read(chatRepositoryProvider).deleteChat(chat.id);
              },
            );
          }
          currentIndex += entry.value.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBottomSection({
    required Color bgTertiary,
    required Color borderDefault,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required dynamic currentUser,
  }) {
    final userName = currentUser?.name;
    final hasName = userName != null && userName.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: borderDefault,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgTertiary,
                  border: Border.all(
                    color: borderDefault,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: hasName
                      ? Text(
                          userName[0].toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 16,
                          color: textMuted,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              // User name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasName ? userName : 'Guest',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              // Plan badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: bgTertiary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  'FREE',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Settings icon
              GestureDetector(
                onTap: () {
                  context.go(AppRoutes.settings);
                },
                child: Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
