import 'package:flutter_test/flutter_test.dart';
import 'package:mio/data/models/referral_model.dart';

void main() {
  group('ReferralModel', () {
    test('fromJson parses all fields correctly', () {
      final json = <String, dynamic>{
        'code': 'REF-ABC123',
        'total_referrals': 10,
        'completed_referrals': 5,
        'total_bonus_tokens': 50000,
      };

      final model = ReferralModel.fromJson(json);

      expect(model.code, 'REF-ABC123');
      expect(model.totalReferrals, 10);
      expect(model.completedReferrals, 5);
      expect(model.totalBonusTokens, 50000);
    });

    test('fromJson applies defaults when fields are null', () {
      final json = <String, dynamic>{
        'code': null,
        'total_referrals': null,
        'completed_referrals': null,
        'total_bonus_tokens': null,
      };

      final model = ReferralModel.fromJson(json);

      expect(model.code, '');
      expect(model.totalReferrals, 0);
      expect(model.completedReferrals, 0);
      expect(model.totalBonusTokens, 0);
    });

    test('toJson outputs correct snake_case keys', () {
      const model = ReferralModel(
        code: 'REF-XYZ',
        totalReferrals: 3,
        completedReferrals: 2,
        totalBonusTokens: 20000,
      );

      final json = model.toJson();

      expect(json['code'], 'REF-XYZ');
      expect(json['total_referrals'], 3);
      expect(json['completed_referrals'], 2);
      expect(json['total_bonus_tokens'], 20000);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final originalJson = <String, dynamic>{
        'code': 'ROUND-TRIP',
        'total_referrals': 7,
        'completed_referrals': 4,
        'total_bonus_tokens': 35000,
      };

      final model = ReferralModel.fromJson(originalJson);
      final resultJson = model.toJson();

      expect(resultJson['code'], originalJson['code']);
      expect(resultJson['total_referrals'], originalJson['total_referrals']);
      expect(
        resultJson['completed_referrals'],
        originalJson['completed_referrals'],
      );
      expect(
        resultJson['total_bonus_tokens'],
        originalJson['total_bonus_tokens'],
      );
    });

    test('fromJson handles empty JSON map gracefully', () {
      final json = <String, dynamic>{};

      final model = ReferralModel.fromJson(json);

      expect(model.code, '');
      expect(model.totalReferrals, 0);
      expect(model.completedReferrals, 0);
      expect(model.totalBonusTokens, 0);
    });
  });
}
