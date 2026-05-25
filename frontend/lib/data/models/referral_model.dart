class ReferralModel {
  final String code;
  final int totalReferrals;
  final int completedReferrals;
  final int totalBonusTokens;

  const ReferralModel({
    required this.code,
    required this.totalReferrals,
    required this.completedReferrals,
    required this.totalBonusTokens,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      code: json['code'] as String? ?? '',
      totalReferrals: json['total_referrals'] as int? ?? 0,
      completedReferrals: json['completed_referrals'] as int? ?? 0,
      totalBonusTokens: json['total_bonus_tokens'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'total_referrals': totalReferrals,
        'completed_referrals': completedReferrals,
        'total_bonus_tokens': totalBonusTokens,
      };
}
