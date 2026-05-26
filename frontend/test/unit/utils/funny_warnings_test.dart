import 'package:flutter_test/flutter_test.dart';
import 'package:mio/core/utils/funny_warnings.dart';

void main() {
  group('FunnyWarnings', () {
    test('tokenWarning is non-empty', () {
      expect(FunnyWarnings.tokenWarning.isNotEmpty, true);
    });

    test('tokenBlocked is non-empty', () {
      expect(FunnyWarnings.tokenBlocked.isNotEmpty, true);
    });

    test('deviceLimit is non-empty', () {
      expect(FunnyWarnings.deviceLimit.isNotEmpty, true);
    });

    test('noApiKey is non-empty', () {
      expect(FunnyWarnings.noApiKey.isNotEmpty, true);
    });

    test('fileTooLarge is non-empty', () {
      expect(FunnyWarnings.fileTooLarge.isNotEmpty, true);
    });

    test('rateLimit is non-empty', () {
      expect(FunnyWarnings.rateLimit.isNotEmpty, true);
    });

    test('voiceError is non-empty', () {
      expect(FunnyWarnings.voiceError.isNotEmpty, true);
    });

    test('memoryFull is non-empty', () {
      expect(FunnyWarnings.memoryFull.isNotEmpty, true);
    });

    test('ollamaNotRunning is non-empty', () {
      expect(FunnyWarnings.ollamaNotRunning.isNotEmpty, true);
    });

    test('connectionError is non-empty', () {
      expect(FunnyWarnings.connectionError.isNotEmpty, true);
    });

    test('modelNotSelected is non-empty', () {
      expect(FunnyWarnings.modelNotSelected.isNotEmpty, true);
    });

    test('signInRequired is non-empty', () {
      expect(FunnyWarnings.signInRequired.isNotEmpty, true);
    });

    test('upgradeRequired is non-empty', () {
      expect(FunnyWarnings.upgradeRequired.isNotEmpty, true);
    });

    test('all warnings contain meaningful text', () {
      final allWarnings = [
        FunnyWarnings.tokenWarning,
        FunnyWarnings.tokenBlocked,
        FunnyWarnings.deviceLimit,
        FunnyWarnings.noApiKey,
        FunnyWarnings.fileTooLarge,
        FunnyWarnings.rateLimit,
        FunnyWarnings.voiceError,
        FunnyWarnings.memoryFull,
        FunnyWarnings.ollamaNotRunning,
        FunnyWarnings.connectionError,
        FunnyWarnings.modelNotSelected,
        FunnyWarnings.signInRequired,
        FunnyWarnings.upgradeRequired,
      ];

      for (final warning in allWarnings) {
        expect(warning.length, greaterThan(5));
      }
    });
  });
}
