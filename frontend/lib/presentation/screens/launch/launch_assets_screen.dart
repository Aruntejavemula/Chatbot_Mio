import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class _AssetEntry {
  final String platform;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const _AssetEntry({
    required this.platform,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });
}

class LaunchAssetsScreen extends StatefulWidget {
  const LaunchAssetsScreen({super.key});

  @override
  State<LaunchAssetsScreen> createState() => _LaunchAssetsScreenState();
}

class _LaunchAssetsScreenState extends State<LaunchAssetsScreen> {
  final Set<int> _copiedIndices = {};

  static const List<_AssetEntry> _assets = [
    _AssetEntry(
      platform: 'ProductHunt',
      icon: Icons.rocket_launch_outlined,
      iconColor: Color(0xFFDA552F),
      title: 'Tagline',
      content: 'Your AI companion that adapts to you — private, fast, and beautifully simple.',
    ),
    _AssetEntry(
      platform: 'ProductHunt',
      icon: Icons.rocket_launch_outlined,
      iconColor: Color(0xFFDA552F),
      title: 'Description',
      content: 'Mio is a privacy-first AI chatbot that brings together the best language models in one beautiful interface. Switch between providers, keep your data secure, and enjoy a thoughtful experience designed for real conversations.',
    ),
    _AssetEntry(
      platform: 'Twitter / X',
      icon: Icons.alternate_email,
      iconColor: Color(0xFF1DA1F2),
      title: 'Launch Post',
      content: 'Introducing Mio — your new AI companion.\n\nPrivate. Fast. Beautiful.\n\nOne app, multiple AI models, zero data tracking.\n\nTry it free today.',
    ),
    _AssetEntry(
      platform: 'Reddit',
      icon: Icons.forum_outlined,
      iconColor: Color(0xFFFF4500),
      title: 'Launch Post',
      content: 'Hey everyone! We just launched Mio, a privacy-focused AI chatbot that lets you use multiple language models through one clean interface.\n\nKey features:\n• Switch between AI providers (OpenAI, Anthropic, Google, etc.)\n• End-to-end privacy — we never store or train on your data\n• Beautiful, minimal UI that stays out of your way\n• Works offline with on-device models\n\nWould love to hear your feedback!',
    ),
    _AssetEntry(
      platform: 'LinkedIn',
      icon: Icons.work_outline,
      iconColor: Color(0xFF0A66C2),
      title: 'Announcement',
      content: 'Excited to announce the launch of Mio — a privacy-first AI assistant that brings together the best language models in one thoughtfully designed interface.\n\nWe built Mio because we believe AI should be accessible, private, and beautiful. No data tracking, no lock-in, just great conversations.\n\n#AI #ProductLaunch #Privacy #Startup',
    ),
    _AssetEntry(
      platform: 'App Store',
      icon: Icons.phone_iphone,
      iconColor: Color(0xFF007AFF),
      title: 'Description',
      content: 'Mio brings the power of the world\'s best AI models to your fingertips — privately, beautifully, and instantly.\n\nFeatures:\n• Chat with GPT-4, Claude, Gemini, DeepSeek, and more\n• Bring your own API keys — full control, no hidden costs\n• End-to-end encrypted conversations\n• Beautiful dark and light themes\n• Works across all your devices\n\nDownload Mio and start chatting smarter today.',
    ),
  ];

  void _copyAsset(int index) {
    Clipboard.setData(ClipboardData(text: _assets[index].content));
    setState(() => _copiedIndices.add(index));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedIndices.remove(index));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final cardBg = isDark ? AppColors.darkBgSecondary : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: textPrimary, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Hero header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                              : [const Color(0xFFFFF8F3), const Color(0xFFFAF5EF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.campaign_outlined, size: 36, color: AppColors.persian),
                          const SizedBox(height: 16),
                          Text(
                            'Launch Assets',
                            style: GoogleFonts.dmSerifDisplay(fontSize: 36, color: textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ready-to-use marketing copy for every platform. Click to copy and paste anywhere.',
                            style: GoogleFonts.dmSans(fontSize: 15, height: 1.5, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Asset cards
                    ...List.generate(_assets.length, (i) {
                      final asset = _assets[i];
                      final isCopied = _copiedIndices.contains(i);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: asset.iconColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(asset.icon, size: 16, color: asset.iconColor),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(asset.platform, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.5)),
                                        Text(asset.title, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary)),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _copyAsset(i),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isCopied
                                            ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.12)
                                            : (isDark ? AppColors.darkBgTertiary : AppColors.bgSecondary),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isCopied ? Icons.check : Icons.copy,
                                            size: 14,
                                            color: isCopied ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess) : textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isCopied ? 'Copied' : 'Copy',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isCopied ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess) : textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SelectableText(
                                asset.content,
                                style: GoogleFonts.dmSans(fontSize: 14, height: 1.6, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
