import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int currentPage = 0;
  int? selectedProviderIndex;
  final TextEditingController apiKeyController = TextEditingController();
  bool isKeyVisible = false;
  bool isTestingKey = false;
  bool isSavingKey = false;
  Set<String> selectedPreferences = {};

  late final AnimationController _floatingController;
  late final Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pageController.dispose();
    apiKeyController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'onboarding_complete', value: 'true');
    if (mounted) {
      context.go(AppRoutes.chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: currentPage == 0
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => currentPage = index);
              },
              children: [
                _buildPage1(isDark),
                _buildPage2(isDark),
                _buildPage3(isDark),
                _buildPage4(isDark),
                _buildPage5(isDark),
              ],
            ),
            // Back arrow on pages 2-4
            if (currentPage >= 1 && currentPage <= 3)
              Positioned(
                top: 12,
                left: 16,
                child: IconButton(
                  onPressed: () => _goToPage(currentPage - 1),
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            // Page indicator dots on pages 1-4
            if (currentPage < 4)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final isActive = index == currentPage;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 8 : 6,
                      height: isActive ? 8 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.persian
                            : (isDark
                                ? AppColors.darkBorderDefault
                                : AppColors.borderDefault),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // PAGE 1 - Welcome To Mio
  Widget _buildPage1(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBgSecondary
                    : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: const Center(
                child: Text(
                  '\u{1F47B}',
                  style: TextStyle(fontSize: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No fluff. Just answers.',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Mio gives you direct, honest AI responses.\nNo pleasantries. No filler. No yapping.\nJust exactly what you asked for.',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _goToPage(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.persian,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Next',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PAGE 2 - Bring Your Own Key
  Widget _buildPage2(bool isDark) {
    final providers = [
      {'label': 'O', 'color': const Color(0xFF10A37F)},
      {'label': 'A', 'color': const Color(0xFFD97757)},
      {'label': 'D', 'color': const Color(0xFF4D6BFE)},
      {'label': 'G', 'color': const Color(0xFF4285F4)},
      {
        'label': '+',
        'color': isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 80),
          // Provider icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: providers.map((p) {
              final isMore = p['label'] == '+';
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p['color'] as Color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    p['label'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isMore
                          ? (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted)
                          : Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Your keys. Your models.',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Connect your own API keys from any\nAI provider. Use GPT, Claude, Gemini,\nDeepSeek, and more. Your keys stay encrypted.\nWe never read them. Ever.',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Info box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorderDefault
                    : AppColors.borderDefault,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: AppColors.persian,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AES-256 encrypted on our servers',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Primary button
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _goToPage(2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.persian,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add my API key now',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary outline button
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _goToPage(3),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkBorderDefault
                          : AppColors.borderDefault,
                    ),
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // PAGE 3 - Add First API Key
  Widget _buildPage3(bool isDark) {
    final providerList = [
      {'name': 'OpenAI', 'initial': 'O', 'color': const Color(0xFF10A37F)},
      {'name': 'Anthropic', 'initial': 'A', 'color': const Color(0xFFD97757)},
      {
        'name': 'Google Gemini',
        'initial': 'G',
        'color': const Color(0xFF4285F4)
      },
      {'name': 'DeepSeek', 'initial': 'D', 'color': const Color(0xFF4D6BFE)},
      {'name': 'Kimi', 'initial': 'K', 'color': const Color(0xFF6366F1)},
      {'name': 'Groq', 'initial': 'G', 'color': const Color(0xFFF97316)},
      {
        'name': 'Together AI',
        'initial': 'T',
        'color': const Color(0xFF0EA5E9)
      },
      {
        'name': 'OpenRouter',
        'initial': 'R',
        'color': const Color(0xFF8B5CF6)
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Text(
            'Add your first AI key',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a provider to get started',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // 2-column grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: providerList.length,
            itemBuilder: (context, index) {
              final provider = providerList[index];
              final isSelected = selectedProviderIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedProviderIndex = index;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBgSecondary
                        : AppColors.bgSecondary,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.persian : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: provider['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            provider['initial'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider['name'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Show API key input when provider is selected
          if (selectedProviderIndex != null) ...[
            const SizedBox(height: 24),
            TextField(
              controller: apiKeyController,
              obscureText: !isKeyVisible,
              decoration: InputDecoration(
                hintText: 'Paste your API key here',
                hintStyle: GoogleFonts.dmSans(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkBgSecondary
                    : AppColors.bgSecondary,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMedium),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorderDefault
                        : AppColors.borderDefault,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMedium),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorderDefault
                        : AppColors.borderDefault,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMedium),
                  borderSide: const BorderSide(
                    color: AppColors.persian,
                  ),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => isKeyVisible = !isKeyVisible);
                  },
                  icon: Icon(
                    isKeyVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted,
                  ),
                ),
              ),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      // ignore: avoid_print
                      onPressed: isTestingKey ? null : () { print('test key pressed'); },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.persian),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                      ),
                      child: isTestingKey
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.persian,
                              ),
                            )
                          : Text(
                              'Test',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.persian,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      // ignore: avoid_print
                      onPressed: isSavingKey ? null : () { print('save key pressed'); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.persian,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        elevation: 0,
                      ),
                      child: isSavingKey
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => _goToPage(3),
            child: Text(
              'Skip for now',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // PAGE 4 - What Do You Use AI For
  Widget _buildPage4(bool isDark) {
    final chips = [
      'Coding',
      'Writing',
      'Research',
      'Learning',
      'Business',
      'Creative',
      'Math',
      'Data Analysis',
      'Language learning',
      'General chat',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What do you mainly use AI for?',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "We'll suggest the best models for you",
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: chips.map((chip) {
              final isSelected = selectedPreferences.contains(chip);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedPreferences.remove(chip);
                    } else {
                      selectedPreferences.add(chip);
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.persian
                        : (isDark
                            ? AppColors.darkBgSecondary
                            : AppColors.bgSecondary),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.persian
                          : (isDark
                              ? AppColors.darkBorderDefault
                              : AppColors.borderDefault),
                    ),
                  ),
                  child: Text(
                    chip,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _goToPage(4),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.persian,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _goToPage(4),
            child: Text(
              'Skip',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PAGE 5 - You Are Ready
  Widget _buildPage5(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: child,
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBgSecondary
                    : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: const Center(
                child: Text(
                  '\u{1F47B}',
                  style: TextStyle(fontSize: 50),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "You're all set!",
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Start chatting with any AI model.\nDirect answers. Zero fluff. Always.',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _completeOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.persian,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Start chatting',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
