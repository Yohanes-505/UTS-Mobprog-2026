import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionCheckoutResult {
  final String snapToken;
  final String redirectUrl;
  final String orderId;

  SubscriptionCheckoutResult({
    required this.snapToken,
    required this.redirectUrl,
    required this.orderId,
  });
}

class SubscriptionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<SubscriptionCheckoutResult> createTransaction(String tier) async {
    final response = await _client.functions.invoke(
      'create-transaction',
      body: {'tier': tier},
    );

    if (response.status != 200) {
      final message = (response.data is Map && response.data['error'] != null)
          ? response.data['error']
          : 'Gagal membuat transaksi (status ${response.status})';
      throw Exception(message);
    }

    final data = response.data as Map<String, dynamic>;

    return SubscriptionCheckoutResult(
      snapToken: data['snap_token'] as String,
      redirectUrl: data['redirect_url'] as String,
      orderId: data['order_id'] as String,
    );
  }

  Future<Map<String, dynamic>?> getMySubscription() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return data;
  }

  Future<void> cancelSubscription() async {
    await _client.rpc('cancel_subscription');
  }

  Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}