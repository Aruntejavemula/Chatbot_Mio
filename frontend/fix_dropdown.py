import re

with open('lib/presentation/screens/chat/chat_screen.dart', 'r', encoding='utf-8', newline='') as f:
    content = f.read()

# Replace the old model list with a richer structure
old_models = """  final List<Map<String, dynamic>> _availableModels = [
    {'provider': 'OpenAI', 'model': 'GPT-4o', 'color': const Color(0xFF10A37F)},
    {'provider': 'OpenAI', 'model': 'GPT-4o mini', 'color': const Color(0xFF10A37F)},
    {'provider': 'Anthropic', 'model': 'Claude 4 Sonnet', 'color': const Color(0xFFD97757)},
    {'provider': 'Anthropic', 'model': 'Claude 3.5 Haiku', 'color': const Color(0xFFD97757)},
    {'provider': 'Google', 'model': 'Gemini 2.5 Pro', 'color': const Color(0xFF4285F4)},
    {'provider': 'DeepSeek', 'model': 'DeepSeek R1', 'color': const Color(0xFF4D6BFE)},
    {'provider': 'Ollama', 'model': 'Ollama (Local)', 'color': const Color(0xFF0EA5E9)},
  ];"""

new_models = """  final List<Map<String, dynamic>> _availableModels = [
    {'provider': 'Anthropic', 'model': 'Claude 4 Sonnet', 'description': 'Most capable for everyday tasks', 'color': const Color(0xFFD97757)},
    {'provider': 'OpenAI', 'model': 'GPT-4o', 'description': 'Great for reasoning and coding', 'color': const Color(0xFF10A37F)},
    {'provider': 'Google', 'model': 'Gemini 2.5 Pro', 'description': 'Long context and multimodal', 'color': const Color(0xFF4285F4)},
    {'provider': 'DeepSeek', 'model': 'DeepSeek R1', 'description': 'Deep reasoning, open weights', 'color': const Color(0xFF4D6BFE)},
    {'provider': 'Anthropic', 'model': 'Claude 3.5 Haiku', 'description': 'Fastest for quick answers', 'color': const Color(0xFFD97757)},
    {'provider': 'OpenAI', 'model': 'GPT-4o mini', 'description': 'Lightweight and cost-efficient', 'color': const Color(0xFF10A37F)},
    {'provider': 'Ollama', 'model': 'Ollama (Local)', 'description': 'Run models on your machine', 'color': const Color(0xFF0EA5E9)},
  ];"""

content = content.replace(old_models, new_models)

# Replace _buildModelDropdown method
old_dropdown_start = '  Widget _buildModelDropdown(bool isDark) {'
old_dropdown_end = '  }\n\n  @override\n  Widget build(BuildContext context) {'

new_dropdown = """  Widget _buildModelDropdown(bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final bg = isDark ? const Color(0xFF262626) : Colors.white;

    return Positioned(
      bottom: 90 + MediaQuery.of(context).viewPadding.bottom,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 380),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableModels.length + 1,
            itemBuilder: (context, index) {
              if (index == _availableModels.length) {
                return GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.expand_more, size: 18, color: textMuted),
                        const SizedBox(width: 12),
                        Text(
                          'More models',
                          style: TextStyle(
                            fontSize: 14,
                            color: textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, size: 18, color: textMuted),
                      ],
                    ),
                  ),
                );
              }
              final model = _availableModels[index];
              final isSelected = _selectedModel == model['model'];
              return GestureDetector(
                onTap: () => _onModelSelected(
                  model['model'] as String,
                  model['provider'] as String,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: model['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              model['model'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                            Text(
                              model['description'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check, size: 18, color: Color(0xFF4285F4)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {"""

# Find and replace the old dropdown method
start_idx = content.find(old_dropdown_start)
if start_idx != -1:
    end_idx = content.find(old_dropdown_end, start_idx)
    if end_idx != -1:
        content = content[:start_idx] + new_dropdown + content[end_idx + len(old_dropdown_end) - len('  }\n\n  @override\n  Widget build(BuildContext context) {'):]
        print('Replaced model dropdown')
    else:
        print('Could not find end of dropdown method')
else:
    print('Could not find start of dropdown method')

with open('lib/presentation/screens/chat/chat_screen.dart', 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)
print('Done')
