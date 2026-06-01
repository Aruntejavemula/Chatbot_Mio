import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/funny_warnings.dart';
import '../common/funny_snackbar.dart';
import '../common/permission_dialog.dart';
import 'file_upload_widget.dart';

class PlusPanelWidget extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final String userPlan;
  final List<String> connectedProviders;
  final Function(List<SelectedFileInfo>) onFilesSelected;

  const PlusPanelWidget({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.userPlan,
    required this.connectedProviders,
    required this.onFilesSelected,
  });

  @override
  State<PlusPanelWidget> createState() => _PlusPanelWidgetState();
}

class _PlusPanelWidgetState extends State<PlusPanelWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  final Set<String> _activeSkills = {};
  bool _skillsExpanded = false;
  bool _connectorsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F1EC);
    final textPrimary = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF888888);
    final divider = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E2DA);

    return AnimatedSize(
      duration: Duration(milliseconds: widget.isOpen ? 220 : 160),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: widget.isOpen ? 1.0 : 0.0,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _menuItem(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  textPrimary: textPrimary,
                  divider: divider,
                  onTap: _pickCamera,
                ),
                _menuItem(
                  icon: Icons.photo_library_outlined,
                  label: 'Photos',
                  textPrimary: textPrimary,
                  divider: divider,
                  onTap: _pickPhoto,
                ),
                _menuItem(
                  icon: Icons.attach_file_outlined,
                  label: 'Files',
                  textPrimary: textPrimary,
                  divider: divider,
                  onTap: _pickFile,
                ),
                // Skills expandable
                _expandableSection(
                  icon: Icons.bolt_outlined,
                  label: 'Skills',
                  expanded: _skillsExpanded,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  divider: divider,
                  isDark: isDark,
                  onTap: () => setState(() => _skillsExpanded = !_skillsExpanded),
                  children: [
                    const _SkillItem(name: 'Web Search', icon: Icons.search_outlined, requiredPlan: 'basic'),
                    const _SkillItem(name: 'Calculator', icon: Icons.calculate_outlined, requiredPlan: 'basic'),
                    const _SkillItem(name: 'Translator', icon: Icons.translate_outlined, requiredPlan: 'basic'),
                    const _SkillItem(name: 'Deep Research', icon: Icons.biotech_outlined, requiredPlan: 'pro'),
                    const _SkillItem(name: 'Image Gen', icon: Icons.image_outlined, requiredPlan: 'pro'),
                    const _SkillItem(name: 'Code Runner', icon: Icons.code_outlined, requiredPlan: 'pro'),
                  ],
                ),
                // Connectors expandable
                _expandableSection(
                  icon: Icons.cable_outlined,
                  label: 'Connectors',
                  expanded: _connectorsExpanded,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  divider: divider,
                  isDark: isDark,
                  onTap: () => setState(() => _connectorsExpanded = !_connectorsExpanded),
                  isLast: true,
                  children: [
                    const _SkillItem(name: 'Google Drive', icon: Icons.cloud_outlined, requiredPlan: 'pro'),
                    const _SkillItem(name: 'Notion', icon: Icons.note_outlined, requiredPlan: 'pro'),
                    const _SkillItem(name: 'Gmail', icon: Icons.email_outlined, requiredPlan: 'pro'),
                    const _SkillItem(name: 'GitHub', icon: Icons.code, requiredPlan: 'pro'),
                    const _SkillItem(name: 'Slack', icon: Icons.chat_bubble_outline, requiredPlan: 'pro'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required Color textPrimary,
    required Color divider,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: textPrimary),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: divider),
      ],
    );
  }

  Widget _expandableSection({
    required IconData icon,
    required String label,
    required bool expanded,
    required Color textPrimary,
    required Color textMuted,
    required Color divider,
    required bool isDark,
    required VoidCallback onTap,
    required List<_SkillItem> children,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: divider),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: textPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, size: 18, color: textMuted),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          ...children.map((skill) {
            final isAvailable = _isSkillAvailable(skill.requiredPlan);
            final isActive = _activeSkills.contains(skill.name);
            return InkWell(
              onTap: () {
                if (!isAvailable) {
                  FunnySnackbar.show(context, FunnyWarnings.upgradeRequired, type: SnackbarType.warning);
                  return;
                }
                setState(() {
                  if (isActive) {
                    _activeSkills.remove(skill.name);
                  } else {
                    _activeSkills.add(skill.name);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(50, 10, 16, 10),
                child: Row(
                  children: [
                    Icon(
                      skill.icon,
                      size: 18,
                      color: isActive ? AppColors.persian : textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        skill.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: isActive ? AppColors.persian : textPrimary,
                          fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (!isAvailable)
                      Icon(Icons.lock_outline, size: 14, color: textMuted)
                    else if (isActive)
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.persian,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                  ],
                ),
              ),
            );
          }),
        if (!isLast)
          const SizedBox.shrink()
        else
          const SizedBox(height: 4),
      ],
    );
  }

  bool _isSkillAvailable(String requiredPlan) {
    const planLevels = {'free': 0, 'basic': 1, 'pro': 2};
    final userLevel = planLevels[widget.userPlan] ?? 0;
    final requiredLevel = planLevels[requiredPlan] ?? 0;
    return userLevel >= requiredLevel;
  }

  Future<void> _pickPhoto() async {
    widget.onToggle();
    final currentStatus = await Permission.photos.status;
    if (!currentStatus.isGranted) {
      if (!mounted) return;
      final allowed = await PermissionDialog.photos(context);
      if (!allowed) return;
    }
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      if (size > AppConstants.maxFileSizeBytes) {
        if (!mounted) return;
        FunnySnackbar.show(context, FunnyWarnings.fileTooLarge, type: SnackbarType.error);
        return;
      }
      widget.onFilesSelected([SelectedFileInfo(name: image.name, path: image.path, sizeBytes: size, type: SelectedFileType.image)]);
    }
  }

  Future<void> _pickFile() async {
    widget.onToggle();
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'md', 'csv', 'py', 'js', 'ts', 'dart', 'json', 'yaml'],
    );
    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.first;
      final filePath = pickedFile.path;
      if (filePath != null) {
        if (pickedFile.size > AppConstants.maxFileSizeBytes) {
          if (!mounted) return;
          FunnySnackbar.show(context, FunnyWarnings.fileTooLarge, type: SnackbarType.error);
          return;
        }
        final codeExtensions = ['py', 'js', 'ts', 'dart', 'json', 'yaml'];
        final extension = pickedFile.extension ?? '';
        final fileType = codeExtensions.contains(extension) ? SelectedFileType.code : SelectedFileType.document;
        widget.onFilesSelected([SelectedFileInfo(name: pickedFile.name, path: filePath, sizeBytes: pickedFile.size, type: fileType)]);
      }
    }
  }

  Future<void> _pickCamera() async {
    widget.onToggle();
    final currentStatus = await Permission.camera.status;
    if (!currentStatus.isGranted) {
      if (!mounted) return;
      final allowed = await PermissionDialog.camera(context);
      if (!allowed) return;
    }
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      if (size > AppConstants.maxFileSizeBytes) {
        if (!mounted) return;
        FunnySnackbar.show(context, FunnyWarnings.fileTooLarge, type: SnackbarType.error);
        return;
      }
      widget.onFilesSelected([SelectedFileInfo(name: image.name, path: image.path, sizeBytes: size, type: SelectedFileType.image)]);
    }
  }
}

class _SkillItem {
  final String name;
  final IconData icon;
  final String requiredPlan;
  const _SkillItem({required this.name, required this.icon, required this.requiredPlan});
}
