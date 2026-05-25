import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
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
  static const int _maxFileSizeBytes = 10 * 1024 * 1024;
  final ImagePicker _imagePicker = ImagePicker();
  final Set<String> _activeSkills = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSize(
      duration: Duration(milliseconds: widget.isOpen ? 300 : 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: widget.isOpen ? 1.0 : 0.0,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
                  width: 1,
                ),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkillsSection(isDark),
                const SizedBox(height: 12),
                _buildConnectorsSection(isDark),
                const SizedBox(height: 12),
                _buildAttachSection(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
      ),
    );
  }

  Widget _buildSkillsSection(bool isDark) {
    final skills = [
      _SkillItem(name: 'Web Search', icon: Icons.search_outlined, requiredPlan: 'basic'),
      _SkillItem(name: 'Calculator', icon: Icons.calculate_outlined, requiredPlan: 'basic'),
      _SkillItem(name: 'Translator', icon: Icons.translate_outlined, requiredPlan: 'basic'),
      _SkillItem(name: 'Deep Research', icon: Icons.biotech_outlined, requiredPlan: 'pro'),
      _SkillItem(name: 'Image Gen', icon: Icons.image_outlined, requiredPlan: 'pro'),
      _SkillItem(name: 'Code Runner', icon: Icons.code_outlined, requiredPlan: 'pro'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Skills', isDark),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: skills.map((skill) {
              final isAvailable = _isSkillAvailable(skill.requiredPlan);
              final isActive = _activeSkills.contains(skill.name);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildSkillChip(skill, isAvailable, isActive, isDark),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  bool _isSkillAvailable(String requiredPlan) {
    const planLevels = {'free': 0, 'basic': 1, 'pro': 2};
    final userLevel = planLevels[widget.userPlan] ?? 0;
    final requiredLevel = planLevels[requiredPlan] ?? 0;
    return userLevel >= requiredLevel;
  }

  Widget _buildSkillChip(_SkillItem skill, bool isAvailable, bool isActive, bool isDark) {
    if (!isAvailable) {
      return GestureDetector(
        onTap: () => _showUpgradeSnackBar(skill.requiredPlan, skill.name),
        child: Opacity(
          opacity: 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
              border: Border.all(
                color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  skill.icon,
                  size: 18,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  skill.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.lock, size: 12),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isActive) {
            _activeSkills.remove(skill.name);
          } else {
            _activeSkills.add(skill.name);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.persian.withOpacity(0.15)
              : (isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary),
          border: Border.all(
            color: isActive
                ? AppColors.persian
                : (isDark ? AppColors.darkBorderDefault : AppColors.borderDefault),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              skill.icon,
              size: 18,
              color: isActive
                  ? AppColors.persian
                  : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              skill.name,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? AppColors.persian
                    : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectorsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Connectors', isDark),
        const SizedBox(height: 10),
        widget.userPlan == 'pro'
            ? _buildProConnectors(isDark)
            : _buildLockedConnectors(isDark),
      ],
    );
  }

  Widget _buildLockedConnectors(bool isDark) {
    return GestureDetector(
      onTap: () => _showUpgradeSnackBar('pro', 'Connectors'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.persian, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Unlock Connectors',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.persian,
          ),
        ),
      ),
    );
  }

  Widget _buildProConnectors(bool isDark) {
    final connectors = [
      _ConnectorItem(name: 'Google Drive', icon: Icons.cloud_outlined),
      _ConnectorItem(name: 'Gmail', icon: Icons.email_outlined),
      _ConnectorItem(name: 'Calendar', icon: Icons.calendar_today_outlined),
      _ConnectorItem(name: 'Notion', icon: Icons.note_outlined),
      _ConnectorItem(name: 'GitHub', icon: Icons.code),
      _ConnectorItem(name: 'Slack', icon: Icons.chat_bubble_outline),
      _ConnectorItem(name: 'Jira', icon: Icons.bug_report_outlined),
      _ConnectorItem(name: 'Linear', icon: Icons.linear_scale),
      _ConnectorItem(name: 'Zapier', icon: Icons.flash_on_outlined),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: connectors.map((connector) {
          final isConnected = widget.connectedProviders.contains(connector.name);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Navigate to ${connector.name} setup')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
                  border: Border.all(
                    color: isConnected
                        ? AppColors.persian
                        : (isDark ? AppColors.darkBorderDefault : AppColors.borderDefault),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connector.icon,
                      size: 18,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      connector.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttachSection(bool isDark) {
    final attachButtons = [
      _AttachItem(name: 'Photos', icon: Icons.photo_library_outlined, onTap: _pickPhoto),
      _AttachItem(name: 'File', icon: Icons.attach_file_outlined, onTap: _pickFile),
      _AttachItem(name: 'Camera', icon: Icons.camera_alt_outlined, onTap: _pickCamera),
      _AttachItem(name: 'Scan', icon: Icons.document_scanner_outlined, onTap: _pickScan),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Attach', isDark),
        const SizedBox(height: 10),
        Row(
          children: attachButtons.map((item) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildAttachButton(item, isDark),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAttachButton(_AttachItem item, bool isDark) {
    final isLocked = widget.userPlan == 'free';

    return GestureDetector(
      onTap: isLocked
          ? () => _showUpgradeSnackBar('basic', 'file attachments')
          : item.onTap,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
                border: Border.all(
                  color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 24,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.lock, size: 18, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeSnackBar(String requiredPlan, String featureName) {
    FunnySnackbar.show(context, FunnyWarnings.upgradeRequired, type: SnackbarType.warning);
  }

  Future<void> _pickPhoto() async {
    final allowed = await PermissionDialog.photos(context);
    if (!allowed) return;

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      if (size > _maxFileSizeBytes) {
        if (!mounted) return;
        FunnySnackbar.show(context, FunnyWarnings.fileTooLarge, type: SnackbarType.error);
        return;
      }
      final selected = SelectedFileInfo(
        name: image.name,
        path: image.path,
        sizeBytes: size,
        type: SelectedFileType.image,
      );
      widget.onFilesSelected([selected]);
    }
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'docx', 'txt', 'md', 'csv',
        'py', 'js', 'ts', 'dart', 'json', 'yaml',
      ],
    );
    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.first;
      final filePath = pickedFile.path;
      if (filePath != null) {
        if (pickedFile.size > _maxFileSizeBytes) {
          if (!mounted) return;
          FunnySnackbar.show(context, FunnyWarnings.fileTooLarge, type: SnackbarType.error);
          return;
        }
        final codeExtensions = ['py', 'js', 'ts', 'dart', 'json', 'yaml'];
        final extension = pickedFile.extension ?? '';
        final fileType = codeExtensions.contains(extension)
            ? SelectedFileType.code
            : SelectedFileType.document;
        final selected = SelectedFileInfo(
          name: pickedFile.name,
          path: filePath,
          sizeBytes: pickedFile.size,
          type: fileType,
        );
        widget.onFilesSelected([selected]);
      }
    }
  }

  Future<void> _pickCamera() async {
    final allowed = await PermissionDialog.camera(context);
    if (!allowed) return;

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      if (size > _maxFileSizeBytes) {
        if (!mounted) return;
        FunnySnackbar.show(context, FunnyWarnings.fileTooLarge, type: SnackbarType.error);
        return;
      }
      final selected = SelectedFileInfo(
        name: image.name,
        path: image.path,
        sizeBytes: size,
        type: SelectedFileType.image,
      );
      widget.onFilesSelected([selected]);
    }
  }

  Future<void> _pickScan() async {
    final allowed = await PermissionDialog.camera(context);
    if (!allowed) return;

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      if (size > _maxFileSizeBytes) {
        if (!mounted) return;
        FunnySnackbar.show(context, FunnyWarnings.fileTooLarge, type: SnackbarType.error);
        return;
      }
      final selected = SelectedFileInfo(
        name: image.name,
        path: image.path,
        sizeBytes: size,
        type: SelectedFileType.image,
      );
      widget.onFilesSelected([selected]);
    }
  }
}

class _SkillItem {
  final String name;
  final IconData icon;
  final String requiredPlan;

  const _SkillItem({
    required this.name,
    required this.icon,
    required this.requiredPlan,
  });
}

class _ConnectorItem {
  final String name;
  final IconData icon;

  const _ConnectorItem({
    required this.name,
    required this.icon,
  });
}

class _AttachItem {
  final String name;
  final IconData icon;
  final VoidCallback onTap;

  const _AttachItem({
    required this.name,
    required this.icon,
    required this.onTap,
  });
}
