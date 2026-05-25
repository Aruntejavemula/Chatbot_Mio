class AppStrings {
  AppStrings._();

  static const appName = 'Mio';
  static const tagline = 'Think. Not yap.';
  static const chatPlaceholder = 'Chat with Mio';
  static const searchPlaceholder = 'Search chats...';
  static const newChat = 'New chat';
  static const continueGoogle = 'Continue with Google';
  static const continueApple = 'Continue with Apple';
  static const tryWithout = 'Try without signing in';
  static const termsText =
      'By continuing you agree to our Terms and Privacy Policy';

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good morning. What's on your mind?";
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon. Let\'s think.';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening. What do you need?';
    } else {
      return 'Burning the midnight oil?';
    }
  }
}
