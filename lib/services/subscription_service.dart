import 'package:supabase_flutter/supabase_flutter.dart';

class TopUpCheckoutResult {
  final String snapToken;
  final String redirectUrl;
  final String orderId;

  TopUpCheckoutResult({
    required this.snapToken,
    required this.redirectUrl,
    required this.orderId,
  });
}

class WalletPurchaseResult {
  final bool success;
  final String message;
  final int? newBalance;
  final int? currentBalance;
  final int? required;
  final String? tier;

  WalletPurchaseResult({
    required this.success,
    required this.message,
    this.newBalance,
    this.currentBalance,
    this.required,
    this.tier,
  });

  factory WalletPurchaseResult.fromMap(Map<String, dynamic> map) {
    return WalletPurchaseResult(
      success: map['success'] as bool,
      message: map['message'] as String,
      newBalance: map['new_balance'] as int?,
      currentBalance: map['current_balance'] as int?,
      required: map['required'] as int?,
      tier: map['tier'] as String?,
    );
  }
}

class SubscriptionService {
  final SupabaseClient _client = Supabase.instance.client;

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

  Future<int> cancelSubscription() async {
    final result = await _client.rpc('cancel_subscription');
    return result as int;
  }

  Future<WalletPurchaseResult> purchaseWithWallet(String tier) async {
    final result = await _client.rpc('purchase_subscription_with_wallet', params: {
      'p_tier': tier,
    });
    return WalletPurchaseResult.fromMap(Map<String, dynamic>.from(result));
  }

  Future<TopUpCheckoutResult> createTopUp(int amount) async {
    final response = await _client.functions.invoke(
      'create-topup-transaction',
      body: {'amount': amount},
    );

    if (response.status != 200) {
      final message = (response.data is Map && response.data['error'] != null)
          ? response.data['error']
          : 'Gagal membuat transaksi top up (status ${response.status})';
      throw Exception(message);
    }

    final data = response.data as Map<String, dynamic>;

    return TopUpCheckoutResult(
      snapToken: data['snap_token'] as String,
      redirectUrl: data['redirect_url'] as String,
      orderId: data['order_id'] as String,
    );
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

  /// Riwayat perubahan saldo wallet (top up, pembelian, refund pembatalan).
  Future<List<Map<String, dynamic>>> getWalletHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('wallet_transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<int> getWalletBalance() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final data = await _client
        .from('wallets')
        .select('balance')
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return 0;
    return data['balance'] as int;
  }
}