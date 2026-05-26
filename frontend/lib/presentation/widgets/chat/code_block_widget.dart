import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class CodeBlockWidget extends StatefulWidget {
  final String code;
  final String language;
  final bool canRun;

  const CodeBlockWidget({
    super.key,
    required this.code,
    required this.language,
    this.canRun = false,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _isRunning = false;
  String? _output;
  bool _hasError = false;

  Future<void> _executeCode() async {
    setState(() {
      _isRunning = true;
      _output = null;
      _hasError = false;
    });

    try {
      final dio = Dio();
      final response = await dio.post<Map<String, dynamic>>(
        '/chat/execute-code',
        data: {'code': widget.code, 'language': widget.language},
      );

      final data = response.data;
      if (data != null) {
        final exitCode = data['exit_code'] as int? ?? 1;
        final output = data['output'] as String? ?? '';
        final error = data['error'] as String? ?? '';
        setState(() {
          _hasError = exitCode != 0;
          _output = _hasError ? error : output;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _output = 'Execution failed';
      });
    } finally {
      setState(() => _isRunning = false);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary;
    final borderColor =
        isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(isDark, textMuted),
          _buildCodeContent(isDark),
          if (_isRunning) _buildRunningIndicator(),
          if (_output != null) _buildOutput(isDark, borderColor, textMuted),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDark, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
      child: Row(
        children: [
          Text(
            widget.language.isNotEmpty ? widget.language.toUpperCase() : 'CODE',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const Spacer(),
          if (widget.canRun)
            GestureDetector(
              onTap: _isRunning ? null : _executeCode,
              child: Text(
                'Run',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.persian,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (widget.canRun) const SizedBox(width: 12),
          GestureDetector(
            onTap: _copyCode,
            child: Icon(Icons.copy_outlined, size: 14, color: textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeContent(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        widget.code,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildRunningIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.persian,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Running...',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.persian),
          ),
        ],
      ),
    );
  }

  Widget _buildOutput(bool isDark, Color borderColor, Color textMuted) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'OUTPUT',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (_hasError)
                Text(
                  'Error',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.error,
                  ),
                )
              else
                const Icon(
                  Icons.check_circle_outline,
                  size: 12,
                  color: AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            _output ?? '',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: _hasError
                  ? AppColors.error
                  : (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
