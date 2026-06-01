import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/animations.dart';
import '../../../data/models/search_result_model.dart';

class WebSearchResultsWidget extends StatefulWidget {
  final String query;
  final List<SearchResultModel> results;
  final bool isSearching;

  const WebSearchResultsWidget({
    super.key,
    required this.query,
    required this.results,
    required this.isSearching,
  });

  @override
  State<WebSearchResultsWidget> createState() => _WebSearchResultsWidgetState();
}

class _WebSearchResultsWidgetState extends State<WebSearchResultsWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;
    final borderColor =
        isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _buildHeader(textMuted, isDark),
          _buildContent(isDark, borderColor, textMuted),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textMuted, bool isDark) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 16,
              color: widget.isSearching ? AppColors.persian : textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.isSearching
                    ? 'Searching: "${widget.query}"'
                    : '${widget.results.length} sources found',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.isSearching ? AppColors.persian : textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!widget.isSearching)
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0.0,
                duration: MioAnimations.fast,
                child: Icon(Icons.expand_more, size: 18, color: textMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Color borderColor, Color textMuted) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: MioAnimations.curve,
      alignment: Alignment.topCenter,
      child: _isExpanded && widget.results.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: widget.results.take(5).map((result) {
                  return _buildResultItem(result, isDark, textMuted);
                }).toList(),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildResultItem(
      SearchResultModel result, bool isDark, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.language_outlined, size: 12, color: textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  result.url,
                  style:
                      GoogleFonts.dmSans(fontSize: 11, color: AppColors.persian),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (result.snippet.isNotEmpty)
                  Text(
                    result.snippet,
                    style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.open_in_new, size: 14, color: textMuted),
            onPressed: () => _launchUrl(result.url),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
