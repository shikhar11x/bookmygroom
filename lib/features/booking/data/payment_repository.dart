import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentException implements Exception {
  const PaymentException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PaymentOrder {
  const PaymentOrder(this.orderId, this.amount, this.keyId);
  final String orderId;
  final int amount; // paise
  final String keyId;
}

String _friendly(String? code) {
  switch (code) {
    case 'hold_expired':
      return 'Your slot hold expired. Please book again.';
    case 'not_payable':
      return 'This booking can no longer be paid for.';
    case 'bad_signature':
      return 'Payment could not be verified. If money was deducted, contact support.';
    case 'hold_expired_contact_support':
      return 'Payment received after the slot expired. Please contact support for a refund.';
    default:
      return 'Payment service error. Please try again.';
  }
}

class PaymentRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<PaymentOrder> createOrder(String appointmentId) async {
    try {
      final res = await _db.functions
          .invoke('create-payment-order', body: {'appointment_id': appointmentId});
      final d = res.data as Map<String, dynamic>;
      return PaymentOrder(
        d['order_id'] as String,
        d['amount'] as int,
        d['key_id'] as String,
      );
    } on FunctionException catch (e) {
      final code = (e.details is Map) ? (e.details as Map)['error'] as String? : null;
      throw PaymentException(_friendly(code));
    }
  }

  Future<void> verify({
    required String appointmentId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      await _db.functions.invoke('verify-payment', body: {
        'appointment_id': appointmentId,
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      });
    } on FunctionException catch (e) {
      final code = (e.details is Map) ? (e.details as Map)['error'] as String? : null;
      throw PaymentException(_friendly(code));
    }
  }
}

final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) => PaymentRepository());