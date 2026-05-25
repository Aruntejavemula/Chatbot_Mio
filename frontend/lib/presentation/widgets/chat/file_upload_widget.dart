import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

enum SelectedFileType { image, document, code }

class SelectedFileInfo {
  final String name;
  final String path;
  final int sizeBytes;
  final SelectedFileType type;

  const SelectedFileInfo({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.type,
  });

  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      final kb = (sizeBytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else {
      final mb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb MB';
    }
  }
}

class FileUploadWidget extends StatefulWidget {
  final Function(List<SelectedFileInfo>) onFilesSelected;
  final Function(int index) onFileRemoved;
  final bool isPremium;

  const FileUploadWidget({
    super.key,
    required this.onFilesSelected,
    required this.onFileRemoved,
    this.isPremium = true,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final ImagePicker _imagePicker = ImagePicker();

  void _showFileUploadSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add to chat',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildOptionTile(
                    context: sheetContext,
                    icon: Icons.photo_library_outlined,
                    label: 'Photo',
                    isDark: isDark,
                    onTap: () => _pickPhoto(sheetContext),
                  ),
                  _buildOptionTile(
                    context: sheetContext,
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    isDark: isDark,
                    onTap: () => _pickCamera(sheetContext),
                  ),
                  _buildOptionTile(
                    context: sheetContext,
                    icon: Icons.attach_file_outlined,
                    label: 'File',
                    isDark: isDark,
                    onTap: () => _pickFile(sheetContext),
                  ),
                  _buildOptionTile(
                    context: sheetContext,
                    icon: Icons.document_scanner_outlined,
                    label: 'Scan',
                    isDark: isDark,
                    onTap: () => _pickScan(sheetContext),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: widget.isPremium ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorderDefault
                : AppColors.borderDefault,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: AppColors.persian,
                ),
                if (!widget.isPremium)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Icon(
                      Icons.lock,
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.isPremium ? label : 'Upgrade to attach files',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext sheetContext) async {
    Navigator.of(sheetContext).pop();
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      final selected = SelectedFileInfo(
        name: image.name,
        path: image.path,
        sizeBytes: size,
        type: SelectedFileType.image,
      );
      widget.onFilesSelected([selected]);
    }
  }

  Future<void> _pickCamera(BuildContext sheetContext) async {
    Navigator.of(sheetContext).pop();
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      final selected = SelectedFileInfo(
        name: image.name,
        path: image.path,
        sizeBytes: size,
        type: SelectedFileType.image,
      );
      widget.onFilesSelected([selected]);
    }
  }

  Future<void> _pickFile(BuildContext sheetContext) async {
    Navigator.of(sheetContext).pop();
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'docx',
        'txt',
        'md',
        'csv',
        'py',
        'js',
        'ts',
        'dart',
        'json',
        'yaml',
      ],
    );
    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.first;
      final filePath = pickedFile.path;
      if (filePath != null) {
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

  Future<void> _pickScan(BuildContext sheetContext) async {
    Navigator.of(sheetContext).pop();
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      final selected = SelectedFileInfo(
        name: image.name,
        path: image.path,
        sizeBytes: size,
        type: SelectedFileType.image,
      );
      widget.onFilesSelected([selected]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showFileUploadSheet(context),
      child: Icon(
        Icons.add,
        size: 22,
        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
      ),
    );
  }

  static Widget buildFilePreview({
    required SelectedFileInfo fileInfo,
    required bool isDark,
    required VoidCallback onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (fileInfo.type == SelectedFileType.image)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(fileInfo.path),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBgTertiary
                          : AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.image,
                      size: 24,
                      color: AppColors.persian,
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBgTertiary
                    : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                fileInfo.type == SelectedFileType.code
                    ? Icons.code
                    : Icons.description_outlined,
                size: 24,
                color: AppColors.persian,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileInfo.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  fileInfo.formattedSize,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
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
}
