import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import 'file_upload_widget.dart';

class DocumentViewerWidget extends StatelessWidget {
  final List<SelectedFileInfo> files;
  final Function(int index) onRemoveFile;
  final bool isDark;

  const DocumentViewerWidget({
    super.key,
    required this.files,
    required this.onRemoveFile,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Container(
      color: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        height: 120,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(files.length, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index < files.length - 1 ? 8 : 0),
                child: _buildPreviewCard(files[index], index),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(SelectedFileInfo fileInfo, int index) {
    return SizedBox(
      width: 140,
      child: Stack(
        children: [
          Container(
            width: 140,
            constraints: const BoxConstraints(maxHeight: 120),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
              border: Border.all(
                color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPreviewContent(fileInfo),
                ),
                const SizedBox(height: 4),
                Text(
                  fileInfo.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fileInfo.formattedSize,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemoveFile(index),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(SelectedFileInfo fileInfo) {
    final extension = _getExtension(fileInfo.name);

    if (fileInfo.type == SelectedFileType.image) {
      return _buildImagePreview(fileInfo);
    }

    if (extension == 'pdf') {
      return _buildPdfPreview(fileInfo);
    }

    if (_isTextFile(extension)) {
      return _buildTextPreview(fileInfo);
    }

    if (fileInfo.type == SelectedFileType.code) {
      return _buildCodePreview(fileInfo, extension);
    }

    // Default document preview
    return _buildDocumentPreview();
  }

  Widget _buildImagePreview(SelectedFileInfo fileInfo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(fileInfo.path),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image,
              size: 32,
              color: AppColors.persian,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPdfPreview(SelectedFileInfo fileInfo) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.picture_as_pdf,
          size: 32,
          color: AppColors.persian,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'PDF',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextPreview(SelectedFileInfo fileInfo) {
    final lines = _readFileLines(fileInfo.path, 3);
    if (lines == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 28,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            'Text file',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        lines.join('\n'),
        style: GoogleFonts.sourceCodePro(
          fontSize: 10,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCodePreview(SelectedFileInfo fileInfo, String extension) {
    final lines = _readFileLines(fileInfo.path, 2);

    return Stack(
      children: [
        if (lines != null)
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                lines.join('\n'),
                style: GoogleFonts.sourceCodePro(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
        else
          Center(
            child: Icon(
              Icons.code,
              size: 28,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '.$extension',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentPreview() {
    return Center(
      child: Icon(
        Icons.description_outlined,
        size: 28,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
    );
  }

  String _getExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return '';
  }

  bool _isTextFile(String extension) {
    return ['txt', 'md', 'csv'].contains(extension);
  }

  List<String>? _readFileLines(String path, int maxLines) {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final lines = file.readAsLinesSync();
      if (lines.isEmpty) return null;
      return lines.take(maxLines).toList();
    } catch (_) {
      return null;
    }
  }
}
