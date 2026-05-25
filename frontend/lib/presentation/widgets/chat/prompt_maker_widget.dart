import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/chat_service.dart';

class PromptMakerWidget extends StatefulWidget {
  final bool hasText;
  final TextEditingController inputController;
  final void Function(String improvedPrompt) onPromptImproved;
  final String selectedProvider;
  final String selectedModel;
  final ChatService chatService;

  const PromptMakerWidget({
    super.key,
    required this.hasText,
    required this.inputController,
    required this.onPromptImproved,
    required this.selectedProvider,
    required this.selectedModel,
    required this.chatService,
  });

  @override
  State<PromptMakerWidget> createState() => _PromptMakerWidgetState();
}

class _PromptMakerWidgetState extends State<PromptMakerWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.hasText) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PromptMakerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasText && !oldWidget.hasText) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.hasText && oldWidget.hasText) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_isLoading) return;

    final currentText = widget.inputController.text.trim();

    if (currentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type something first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final improvedPrompt = await widget.chatService.makePrompt(
        roughText: currentText,
        provider: widget.selectedProvider,
        model: widget.selectedModel,
      );
      if (!mounted) return;
      widget.onPromptImproved(improvedPrompt);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompt improved')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.message ?? 'Failed to improve prompt';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(4),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.persian,
          ),
        ),
      );
    }

    final icon = Icon(
      Icons.auto_awesome,
      size: 20,
      color: widget.hasText
          ? AppColors.persian
          : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
    );

    return GestureDetector(
      onTap: _onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: widget.hasText
            ? FadeTransition(
                opacity: _pulseAnimation,
                child: icon,
              )
            : icon,
      ),
    );
  }
}
