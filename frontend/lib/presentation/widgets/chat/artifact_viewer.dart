import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

enum ArtifactType { code, html, markdown, chart, unknown }

class ArtifactViewer extends StatefulWidget {
  final String content;
  final ArtifactType artifactType;

  const ArtifactViewer({
    super.key,
    required this.content,
    required this.artifactType,
  });

  static ArtifactType detectArtifactType(String content) {
    if (content.contains('```html')) {
      return ArtifactType.html;
    }

    final codeLanguages = [
      '```dart',
      '```python',
      '```js',
      '```ts',
      '```java',
      '```rust',
      '```go',
      '```cpp',
      '```c\n',
      '```swift',
      '```kotlin',
    ];

    for (final lang in codeLanguages) {
      if (content.contains(lang)) {
        return ArtifactType.code;
      }
    }

    if (content.length > 200) {
      final lines = content.split('\n');
      int headerCount = 0;
      for (final line in lines) {
        if (line.trimLeft().startsWith('#')) {
          headerCount++;
        }
        if (headerCount >= 2) {
          return ArtifactType.markdown;
        }
      }
    }

    return ArtifactType.unknown;
  }

  static String extractArtifactContent(String content, ArtifactType type) {
    switch (type) {
      case ArtifactType.code:
      case ArtifactType.html:
        final codeBlockRegex = RegExp(r'```\w*\n([\s\S]*?)```');
        final match = codeBlockRegex.firstMatch(content);
        if (match != null) {
          return match.group(1)?.trimRight() ?? content;
        }
        return content;
      case ArtifactType.markdown:
        return content;
      case ArtifactType.chart:
        return content;
      case ArtifactType.unknown:
        return content;
    }
  }

  static String? extractLanguage(String content) {
    final langRegex = RegExp(r'```(\w+)\n');
    final match = langRegex.firstMatch(content);
    if (match != null) {
      final lang = match.group(1);
      if (lang != null && lang.isNotEmpty) {
        return lang;
      }
    }
    return null;
  }

  static void showArtifactModal(
    BuildContext context,
    String content,
    ArtifactType type,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => ArtifactViewer(
          content: content,
          artifactType: type,
        ),
      ),
    );
  }

  @override
  State<ArtifactViewer> createState() => _ArtifactViewerState();
}

class _ArtifactViewerState extends State<ArtifactViewer> {
  bool _showingCode = false;

  String get _extractedContent =>
      ArtifactViewer.extractArtifactContent(widget.content, widget.artifactType);

  String get _title {
    switch (widget.artifactType) {
      case ArtifactType.code:
        return 'Code';
      case ArtifactType.html:
        return 'HTML Preview';
      case ArtifactType.markdown:
        return 'Document';
      case ArtifactType.chart:
        return 'Chart';
      case ArtifactType.unknown:
        return 'Artifact';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark, textColor),
      body: Column(
        children: [
          Expanded(child: _buildContent(isDark, textColor)),
          _buildBottomBar(isDark, textColor),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor) {
    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        _title,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      actions: [
        if (widget.artifactType == ArtifactType.html)
          _buildHtmlToggle(isDark, textColor, mutedColor),
        IconButton(
          icon: Icon(Icons.copy_outlined, size: 20, color: mutedColor),
          onPressed: _copyContent,
        ),
        IconButton(
          icon: Icon(Icons.close, size: 20, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildHtmlToggle(bool isDark, Color textColor, Color mutedColor) {
    final activeBg = isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showingCode = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: !_showingCode ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                'Preview',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight:
                      !_showingCode ? FontWeight.w600 : FontWeight.w400,
                  color: !_showingCode ? textColor : mutedColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _showingCode = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _showingCode ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                'Code',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight:
                      _showingCode ? FontWeight.w600 : FontWeight.w400,
                  color: _showingCode ? textColor : mutedColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, Color textColor) {
    switch (widget.artifactType) {
      case ArtifactType.code:
        return _buildCodeView(isDark);
      case ArtifactType.html:
        if (_showingCode) {
          return _buildCodeView(isDark);
        }
        return _buildHtmlPreview(isDark, textColor);
      case ArtifactType.markdown:
        return _buildMarkdownView(isDark, textColor);
      case ArtifactType.chart:
        return _buildCodeView(isDark);
      case ArtifactType.unknown:
        return _buildCodeView(isDark);
    }
  }

  Widget _buildCodeView(bool isDark) {
    final code = _extractedContent;
    final lines = code.split('\n');
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      color: const Color(0xFF0D0D0D),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(lines.length, (index) {
                        return Text(
                          '${index + 1}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: mutedColor,
                            height: 1.5,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SelectableText(
                    code,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _copyContent,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Icon(
                  Icons.copy_outlined,
                  size: 16,
                  color: mutedColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHtmlPreview(bool isDark, Color textColor) {
    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;

    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        'HTML Preview (WebView)',
        style: GoogleFonts.dmSans(
          fontSize: 14,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildMarkdownView(bool isDark, Color textColor) {
    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;
    final bgSecondary =
        isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(20),
      child: Markdown(
        data: _extractedContent,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.dmSans(
            fontSize: 15,
            color: textColor,
            height: 1.6,
          ),
          h1: GoogleFonts.dmSerifDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
          h2: GoogleFonts.dmSerifDisplay(
            fontSize: 22,
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
            height: 1.6,
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
            height: 1.6,
          ),
          em: GoogleFonts.dmSans(
            fontSize: 15,
            fontStyle: FontStyle.italic,
            color: textColor,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, Color textColor) {
    final borderColor =
        isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final bgColor = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (widget.artifactType == ArtifactType.code)
              TextButton.icon(
                onPressed: () => _showComingSoon('Coming soon'),
                icon: Icon(Icons.play_arrow, size: 18, color: mutedColor),
                label: Text(
                  'Run',
                  style: GoogleFonts.dmSans(fontSize: 13, color: mutedColor),
                ),
              ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.download_outlined, size: 20, color: mutedColor),
              onPressed: () => _showComingSoon('Download coming soon'),
            ),
            IconButton(
              icon: Icon(Icons.share_outlined, size: 20, color: mutedColor),
              onPressed: () => _showComingSoon('Share coming soon'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyContent() {
    Clipboard.setData(ClipboardData(text: _extractedContent));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard',
          style: GoogleFonts.dmSans(fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.dmSans(fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
