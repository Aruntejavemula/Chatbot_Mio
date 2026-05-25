import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/animations.dart';
import '../../../data/models/message_model.dart';
import 'artifact_viewer.dart';

class ChatBubble extends StatefulWidget {
  final MessageModel message;
  final bool isLast;
  final VoidCallback? onRegenerate;
  final Function(String)? onEditResend;

  const ChatBubble({
    super.key,
    required this.message,
    this.isLast = false,
    this.onRegenerate,
    this.onEditResend,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  bool _isCopied = false;
  final Set<int> _copiedCodeBlocks = {};
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: MioAnimations.standard,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: MioAnimations.curve,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  bool get _isUser => widget.message.role == 'user';

  static Color _providerColor(String? model) {
    final provider = (model ?? '').toLowerCase();
    if (provider.contains('openai') || provider.contains('gpt')) {
      return const Color(0xFF10A37F);
    }
    if (provider.contains('anthropic') || provider.contains('claude')) {
      return const Color(0xFFD97757);
    }
    if (provider.contains('deepseek')) {
      return const Color(0xFF4D8EF7);
    }
    if (provider.contains('gemini')) {
      return const Color(0xFF4285F4);
    }
    if (provider.contains('kimi')) {
      return const Color(0xFF6C5CE7);
    }
    if (provider.contains('groq')) {
      return const Color(0xFFF55036);
    }
    if (provider.contains('together')) {
      return const Color(0xFF3B82F6);
    }
    if (provider.contains('fireworks')) {
      return const Color(0xFFEF4444);
    }
    if (provider.contains('openrouter')) {
      return const Color(0xFF8B5CF6);
    }
    return AppColors.persian;
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeController,
        child: GestureDetector(
          onLongPress: () => _showContextMenu(context),
          child: _isUser ? _buildUserBubble(context) : _buildAiBubble(context),
        ),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkUserBubble : AppColors.userBubble;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusLarge),
                  topRight: Radius.circular(AppSizes.radiusLarge),
                  bottomLeft: Radius.circular(AppSizes.radiusLarge),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: SelectableText(
                widget.message.content,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: textColor,
                  height: 1.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat.jm().format(widget.message.createdAt),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: mutedColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBubble(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final modelName = widget.message.model ?? 'AI';
    final providerColor = _providerColor(widget.message.model);

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider header
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: providerColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    modelName[0].toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  modelName,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          // Content - parsed with code blocks
          _buildAiContent(context, isDark, textColor, mutedColor),
          // Action row
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCopyMessageButton(mutedColor),
                const SizedBox(width: 16),
                _buildRetryButton(mutedColor),
              ],
            ),
          ),
          // Artifact detection
          _buildArtifactButton(context),
        ],
      ),
    );
  }

  Widget _buildAiContent(
      BuildContext context, bool isDark, Color textColor, Color mutedColor) {
    final segments = _parseContentSegments(widget.message.content);

    if (segments.length == 1 && segments[0].type == _SegmentType.text) {
      return _buildMarkdownSegment(context, segments[0].content, isDark,
          textColor, mutedColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.asMap().entries.map((entry) {
        final index = entry.key;
        final segment = entry.value;
        if (segment.type == _SegmentType.text) {
          return _buildMarkdownSegment(
              context, segment.content, isDark, textColor, mutedColor);
        } else {
          return _buildCodeBlock(
              context, segment.content, segment.language, index, isDark,
              textColor, mutedColor);
        }
      }).toList(),
    );
  }

  Widget _buildMarkdownSegment(BuildContext context, String content,
      bool isDark, Color textColor, Color mutedColor) {
    final bgSecondary =
        isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;

    return MarkdownBody(
      data: content,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href));
        }
      },
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.dmSans(
          fontSize: 15,
          color: textColor,
          height: 1.5,
        ),
        h1: GoogleFonts.dmSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        h2: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        h3: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        listBullet: GoogleFonts.dmSans(
          fontSize: 15,
          color: textColor,
          height: 1.5,
        ),
        code: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          color: textColor,
          backgroundColor: bgSecondary,
        ),
        a: GoogleFonts.dmSans(
          fontSize: 15,
          color: AppColors.persian,
          decoration: TextDecoration.underline,
        ),
        strong: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.5,
        ),
        em: GoogleFonts.dmSans(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: textColor,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildCodeBlock(BuildContext context, String code, String? language,
      int index, bool isDark, Color textColor, Color mutedColor) {
    final bgSecondary =
        isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;
    final bgTertiary =
        isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary;
    final borderColor =
        isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final isCopied = _copiedCodeBlocks.contains(index);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top bar
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bgTertiary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusMedium),
                topRight: Radius.circular(AppSizes.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Text(
                  (language ?? '').toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _copyCodeBlock(code, index),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy,
                        size: 14,
                        color: mutedColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCopied ? 'Copied \u2713' : 'Copy',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Code content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SelectableText(
              code,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyMessageButton(Color mutedColor) {
    return GestureDetector(
      onTap: _copyMessage,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.copy_outlined,
            size: 14,
            color: mutedColor,
          ),
          const SizedBox(width: 4),
          Text(
            _isCopied ? 'Copied!' : 'Copy',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton(Color mutedColor) {
    return GestureDetector(
      onTap: () => debugPrint('retry: ${widget.message.id}'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.refresh,
            size: 14,
            color: mutedColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Retry',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtifactButton(BuildContext context) {
    final artifactType =
        ArtifactViewer.detectArtifactType(widget.message.content);
    if (artifactType == ArtifactType.unknown) {
      return const SizedBox.shrink();
    }

    final label =
        artifactType == ArtifactType.html ? 'Preview' : 'View';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () => ArtifactViewer.showArtifactModal(
          context,
          widget.message.content,
          artifactType,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.open_in_new,
              size: 14,
              color: AppColors.persian,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.persian,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      if (Platform.isIOS || Platform.isAndroid) {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {}

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildContextOption(
                context: sheetContext,
                icon: Icons.copy_outlined,
                label: 'Copy',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(sheetContext);
                  Clipboard.setData(ClipboardData(text: widget.message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied')),
                  );
                },
              ),
              if (widget.message.content.isNotEmpty)
                _buildContextOption(
                  context: sheetContext,
                  icon: Icons.ios_share_outlined,
                  label: 'Share',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Share.share(widget.message.content);
                  },
                ),
              if (!_isUser && widget.onRegenerate != null)
                _buildContextOption(
                  context: sheetContext,
                  icon: Icons.refresh_outlined,
                  label: 'Regenerate',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    widget.onRegenerate!();
                  },
                ),
              if (_isUser && widget.onEditResend != null)
                _buildContextOption(
                  context: sheetContext,
                  icon: Icons.edit_outlined,
                  label: 'Edit & Resend',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    widget.onEditResend!(widget.message.content);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContextOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _copyCodeBlock(String code, int index) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copiedCodeBlocks.add(index));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copiedCodeBlocks.remove(index));
      }
    });
  }

  List<_ContentSegment> _parseContentSegments(String content) {
    final segments = <_ContentSegment>[];
    final codeBlockRegex = RegExp(r'```(\w*)\n([\s\S]*?)```');
    var lastEnd = 0;

    for (final match in codeBlockRegex.allMatches(content)) {
      if (match.start > lastEnd) {
        final text = content.substring(lastEnd, match.start).trim();
        if (text.isNotEmpty) {
          segments.add(_ContentSegment(_SegmentType.text, text));
        }
      }
      final language = match.group(1);
      final code = match.group(2) ?? '';
      segments.add(_ContentSegment(
        _SegmentType.code,
        code.trimRight(),
        language: language?.isNotEmpty == true ? language : null,
      ));
      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      final text = content.substring(lastEnd).trim();
      if (text.isNotEmpty) {
        segments.add(_ContentSegment(_SegmentType.text, text));
      }
    }

    if (segments.isEmpty) {
      segments.add(_ContentSegment(_SegmentType.text, content));
    }

    return segments;
  }
}

enum _SegmentType { text, code }

class _ContentSegment {
  final _SegmentType type;
  final String content;
  final String? language;

  _ContentSegment(this.type, this.content, {this.language});
}
