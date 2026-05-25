import 'package:dio/dio.dart';

import '../models/subscription_model.dart';
import 'api_service.dart';

class PaymentService extends ApiService {
  Future<String> createStripeCheckout(String plan, String period) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/payments/stripe/create-checkout',
        data: {'plan': plan, 'period': period},
      );
      return response.data!['url'] as String;
    } on DioException {
      rethrow;
    }
  }

  Future<String> createStripePortal() async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/payments/stripe/create-portal',
      );
      return response.data!['url'] as String;
    } on DioException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createRazorpayOrder(String plan) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/payments/razorpay/create-subscription',
        data: {'plan': plan},
      );
      return response.data ?? {};
    } on DioException {
      rethrow;
    }
  }

  Future<void> verifyRazorpayPayment({
    required String paymentId,
    required String subscriptionId,
    required String signature,
  }) async {
    try {
      await post(
        '/payments/razorpay/verify-payment',
        data: {
          'payment_id': paymentId,
          'subscription_id': subscriptionId,
          'signature': signature,
        },
      );
    } on DioException {
      rethrow;
    }
  }

  Future<SubscriptionModel> getSubscriptionStatus() async {
    try {
      final response = await get<Map<String, dynamic>>('/payments/status');
      return SubscriptionModel.fromJson(response.data!);
    } on DioException {
      rethrow;
    }
  }
}
