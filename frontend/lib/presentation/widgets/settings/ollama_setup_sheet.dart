import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

enum _OllamaConnectionState { initial, testing, connected, error }

class OllamaSetupSheet extends StatefulWidget {
  const OllamaSetupSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OllamaSetupSheet(),
    );
  }

  @override
  State<OllamaSetupSheet> createState() => _OllamaSetupSheetState();
}

class _OllamaSetupSheetState extends State<OllamaSetupSheet> {
  final TextEditingController _urlController = TextEditingController(
    text: 'http://localhost:11434',
  );
  final Dio _dio = Dio();
  _OllamaConnectionState _connectionState = _OllamaConnectionState.initial;
  List<String> _availableModels = [];
  String _errorMessage = '';

  @override
  void dispose() {
    _urlController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _connectionState = _OllamaConnectionState.testing;
      _errorMessage = '';
      _availableModels = [];
    });

    try {
      final url = _urlController.text.trim();
      final response = await _dio.get<Map<String, dynamic>>(
        '$url/api/tags',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final models = data['models'] as List<dynamic>?;
        if (models != null && models.isNotEmpty) {
          final modelNames = models
              .map((dynamic m) => (m as Map<String, dynamic>)['name'] as String?)
              .where((String? name) => name != null && name.isNotEmpty)
              .cast<String>()
              .toList();
          setState(() {
            _availableModels = modelNames;
            _connectionState = _OllamaConnectionState.connected;
          });
        } else {
          setState(() {
            _availableModels = [];
            _connectionState = _OllamaConnectionState.connected;
          });
        }
      } else {
        setState(() {
          _connectionState = _OllamaConnectionState.error;
          _errorMessage = 'Unexpected response (${response.statusCode})';
        });
      }
    } on DioException catch (e) {
      setState(() {
        _connectionState = _OllamaConnectionState.error;
        _errorMessage = e.message ?? 'Connection failed. Is Ollama running?';
      });
    } catch (e) {
      setState(() {
        _connectionState = _OllamaConnectionState.error;
        _errorMessage = 'Connection failed: $e';
      });
    }
  }

  Future<void> _saveAndClose() async {
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'ollama_url', value: _urlController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save URL: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSecondary : AppColors.bgPrimary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLarge),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBorderDefault
                      : AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingScreen,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: 24),
                      if (_connectionState == _OllamaConnectionState.connected)
                        _buildConnectedContent(isDark)
                      else
                        _buildSetupContent(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ollama Setup',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Run AI models locally on your machine',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSetupContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepItem(1, 'Install Ollama from ollama.com', isDark),
        const SizedBox(height: 12),
        _buildStepItem(2, 'Pull a model: ollama pull llama3', isDark),
        const SizedBox(height: 12),
        _buildStepItem(3, 'Start the server: ollama serve', isDark),
        const SizedBox(height: 12),
        _buildStepItem(4, 'Connect below', isDark),
        const SizedBox(height: 24),
        Text(
          'Server URL',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            hintText: 'http://localhost:11434',
            hintStyle: GoogleFonts.dmSans(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkBgTertiary : AppColors.bgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkBorderDefault
                    : AppColors.borderDefault,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkBorderDefault
                    : AppColors.borderDefault,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              borderSide: const BorderSide(color: AppColors.persian),
            ),
          ),
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (_connectionState == _OllamaConnectionState.error) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _connectionState == _OllamaConnectionState.testing
                ? null
                : _testConnection,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.persian,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.persian.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              elevation: 0,
            ),
            child: _connectionState == _OllamaConnectionState.testing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Test Connection',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildConnectedContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connected to Ollama',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_availableModels.isNotEmpty) ...[
          Text(
            'Available Models',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableModels.map((String model) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBgTertiary
                      : AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorderDefault
                        : AppColors.borderDefault,
                  ),
                ),
                child: Text(
                  model,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ] else ...[
          Text(
            'No models found. Pull a model first:',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Text(
              'ollama pull llama3',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontFamily: 'monospace',
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saveAndClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.persian,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              elevation: 0,
            ),
            child: Text(
              'Use Ollama',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _connectionState = _OllamaConnectionState.initial;
                _availableModels = [];
              });
            },
            child: Text(
              'Test again',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStepItem(int number, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.persian.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.persian,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
