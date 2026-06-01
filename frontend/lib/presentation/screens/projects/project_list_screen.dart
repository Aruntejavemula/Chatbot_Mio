import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/router.dart';
import '../../../data/models/project_model.dart';
import '../../../data/services/project_service.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/common/animated_empty_state.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  final ProjectService _projectService = ProjectService();
  final TextEditingController _searchController = TextEditingController();
  List<ProjectModel> _projects = [];
  bool _isLoading = true;
  String _sortBy = 'Activity';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _projectService.getProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateProjectDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF999999);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DBD2);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.bgPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a personal project',
                style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: textPrimary),
              ),
              const SizedBox(height: 24),
              Text('What are you working on?',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: GoogleFonts.dmSans(fontSize: 15, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Name your project',
                  hintStyle: GoogleFonts.dmSans(fontSize: 15, color: textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.persian),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              Text('What are you trying to achieve?',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                style: GoogleFonts.dmSans(fontSize: 15, color: textPrimary),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your project, goals, subject, etc...',
                  hintStyle: GoogleFonts.dmSans(fontSize: 15, color: textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.persian),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.dmSans(color: textPrimary, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      Navigator.of(ctx).pop();
                      try {
                        await _projectService.createProject(
                          name: nameController.text.trim(),
                          color: '#CC5801',
                          systemPrompt: descController.text.trim(),
                        );
                        _loadProjects();
                      } catch (_) {}
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : const Color(0xFF1A1814),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Create project',
                        style: GoogleFonts.dmSans(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatUpdated(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Updated just now';
    if (diff.inHours < 1) return 'Updated ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Updated 1 day ago';
    if (diff.inDays < 7) return 'Updated ${diff.inDays} days ago';
    return 'Updated ${DateFormat('MMM d').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPrimary = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF999999);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4DFD8);

    final query = _searchController.text.toLowerCase();
    final filtered = query.isEmpty
        ? _projects
        : _projects.where((p) => p.name.toLowerCase().contains(query)).toList();

    // Sort
    if (_sortBy == 'Activity') {
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } else {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Header
                  Row(
                    children: [
                      Text('Projects',
                          style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: textPrimary)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showCreateProjectDialog,
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
                              Text('New project',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13, fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.black : Colors.white,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search
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
                        hintText: 'Search projects...',
                        hintStyle: GoogleFonts.dmSans(fontSize: 14, color: textMuted),
                        prefixIcon: Icon(Icons.search, size: 20, color: textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sort
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Sort by', style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _sortBy = _sortBy == 'Activity' ? 'Name' : 'Activity';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_sortBy,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 16, color: textMuted),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Grid
                  Expanded(
                    child: _isLoading
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              final crossCount = constraints.maxWidth > 500 ? 2 : 1;
                              return MioSkeleton.cardGrid(
                                isDark: isDark,
                                count: crossCount == 2 ? 4 : 3,
                                crossAxisCount: crossCount,
                                childAspectRatio: crossCount == 2 ? 1.6 : 2.5,
                              );
                            },
                          )
                        : filtered.isEmpty
                            ? (query.isEmpty
                                ? AnimatedEmptyState(
                                    icon: Icons.folder_open_rounded,
                                    title: 'No projects yet',
                                    subtitle:
                                        'Create a project to group related chats and instructions.',
                                    actionLabel: 'New project',
                                    onAction: _showCreateProjectDialog,
                                  )
                                : const AnimatedEmptyState(
                                    icon: Icons.search_off_rounded,
                                    title: 'No matching projects',
                                    subtitle: 'Try a different search term.',
                                  ))
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final crossCount = constraints.maxWidth > 500 ? 2 : 1;
                                  return GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossCount,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: crossCount == 2 ? 1.6 : 2.5,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) =>
                                        _buildProjectCard(filtered[index], isDark, textPrimary, textMuted, borderColor),
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
    );
  }

  Widget _buildProjectCard(
      ProjectModel project, bool isDark, Color textPrimary, Color textMuted, Color borderColor) {
    return GestureDetector(
      onTap: () => context.go('${AppRoutes.projects}/${project.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'project-title-${project.id}',
              flightShuttleBuilder: (_, __, ___, ____, toContext) =>
                  DefaultTextStyle(
                style: DefaultTextStyle.of(toContext).style,
                child: (toContext.widget as Hero).child,
              ),
              child: Material(
                color: Colors.transparent,
                child: Text(
                  project.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (project.systemPrompt.isNotEmpty) ...[
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  project.systemPrompt,
                  style: GoogleFonts.dmSans(fontSize: 13, color: textMuted, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else
              const Spacer(),
            Text(
              _formatUpdated(project.updatedAt),
              style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
