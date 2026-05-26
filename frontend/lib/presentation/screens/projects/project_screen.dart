import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/services/project_service.dart';
import '../../widgets/common/ghost_mascot.dart';

class ProjectScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  final ProjectService _projectService = ProjectService();
  List<ChatModel> _chats = [];
  ProjectModel? _project;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    try {
      final projects = await _projectService.getProjects();
      final chats = await _projectService.getProjectChats(widget.projectId);
      if (mounted) {
        setState(() {
          _project = projects.where((p) => p.id == widget.projectId).firstOrNull;
          _chats = chats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return AppColors.persian;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPrimary = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderDefault =
        isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_project != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _parseColor(_project!.color),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _project?.name ?? 'Project',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: textMuted, size: 20),
            onPressed: () {
              // TODO: open edit project sheet
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? _buildEmptyState(textMuted)
              : _buildChatList(
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  borderDefault: borderDefault,
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.persian,
        onPressed: () {
          context.go('/projects/${widget.projectId}/new-chat');
        },
        child: const Icon(Icons.chat_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(Color textMuted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PenguinMascot(size: AppSizes.mascotSizeMedium),
          const SizedBox(height: 16),
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

  Widget _buildChatList({
    required Color textPrimary,
    required Color textMuted,
    required Color borderDefault,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingScreen),
      itemCount: _chats.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: borderDefault,
      ),
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            chat.title,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            chat.lastPreview,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            context.go('/chat/${chat.id}');
          },
        );
      },
    );
  }
}
