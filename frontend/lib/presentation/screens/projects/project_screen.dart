import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/router.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/services/project_service.dart';

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
  bool _isStarred = false;

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
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Last message ${diff.inSeconds} seconds ago';
    if (diff.inMinutes < 60) return 'Last message ${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return 'Last message ${diff.inHours} hours ago';
    if (diff.inDays < 7) return 'Last message ${diff.inDays} days ago';
    return 'Last message ${DateFormat('MMM d').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPrimary = isDark ? Colors.black : AppColors.bgPrimary;
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF999999);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4DFD8);
    final cardBg = isDark ? const Color(0xFF111111) : Colors.white;
    final isWide = MediaQuery.of(context).size.width > 900;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgPrimary,
        body: const Center(child: CircularProgressIndicator(color: AppColors.persian)),
      );
    }

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // ← All projects
              GestureDetector(
                onTap: () => context.go(AppRoutes.projects),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16, color: textMuted),
                    const SizedBox(width: 6),
                    Text('All projects',
                        style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Title row: name + dots + star
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _project?.name ?? 'Project',
                      style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, size: 20, color: textMuted),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      _isStarred ? Icons.star : Icons.star_border,
                      size: 20,
                      color: _isStarred ? AppColors.persian : textMuted,
                    ),
                    onPressed: () => setState(() => _isStarred = !_isStarred),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Main content: input + chats (left) + Instructions/Files (right)
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildLeftContent(isDark, textPrimary, textMuted, borderColor, cardBg)),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildRightPanels(isDark, textPrimary, textMuted, borderColor, cardBg)),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildLeftContent(isDark, textPrimary, textMuted, borderColor, cardBg),
                            const SizedBox(height: 24),
                            _buildRightPanels(isDark, textPrimary, textMuted, borderColor, cardBg),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftContent(bool isDark, Color textPrimary, Color textMuted, Color borderColor, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input box (like Claude project detail)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How can I help you today?',
                  style: GoogleFonts.dmSans(fontSize: 15, color: textMuted)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.add, size: 20, color: textMuted),
                  const Spacer(),
                  Text('Select model',
                      style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: textMuted),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Info tip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D0D0A) : const Color(0xFFF5F2EC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            'Start a chat to keep conversations organized and re-use project knowledge.',
            style: GoogleFonts.dmSans(fontSize: 13, color: textMuted, height: 1.4),
          ),
        ),
        const SizedBox(height: 20),
        // Chat list
        if (_chats.isNotEmpty)
          ..._chats.map((chat) => GestureDetector(
                onTap: () => context.go('${AppRoutes.chat}/${chat.id}'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chat.title,
                          style: GoogleFonts.dmSans(
                              fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                      const SizedBox(height: 3),
                      Text(_formatRelative(chat.updatedAt),
                          style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildRightPanels(bool isDark, Color textPrimary, Color textMuted, Color borderColor, Color cardBg) {
    return Column(
      children: [
        // Instructions panel
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instructions',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 4),
                    Text("Add instructions to tailor Mio's responses",
                        style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)),
                  ],
                ),
              ),
              Icon(Icons.add, size: 20, color: textMuted),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Files panel
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Files',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                  const Spacer(),
                  Icon(Icons.add, size: 20, color: textMuted),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D0D0A) : const Color(0xFFF5F2EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined, size: 32, color: textMuted),
                      const SizedBox(height: 8),
                      Text(
                        'Add PDFs, documents, or other text to\nreference in this project.',
                        style: GoogleFonts.dmSans(fontSize: 12, color: textMuted, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
