import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/subscription_tier.dart';
import '../../services/subscription_service.dart';
import 'transaction_history_screen.dart';
import 'topup_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  String _selectedTierId = 'premium';
  bool _isProcessing = false;
  bool _isLoadingStatus = true;
  Map<String, dynamic>? _activeSubscription;
  int _walletBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
    _loadWalletBalance();
  }

  Future<void> _loadCurrentSubscription() async {
    setState(() => _isLoadingStatus = true);
    try {
      final sub = await _subscriptionService.getMySubscription();
      final isStillActive = sub != null &&
          (sub['status'] == 'active' || sub['status'] == 'cancelled') &&
          sub['expires_at'] != null &&
          DateTime.parse(sub['expires_at']).isAfter(DateTime.now());

      setState(() {
        _activeSubscription = isStillActive ? sub : null;
        if (isStillActive) _selectedTierId = sub['tier'];
      });
    } catch (_) {
      // bukan fatal
    } finally {
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  Future<void> _loadWalletBalance() async {
    try {
      final balance = await _subscriptionService.getWalletBalance();
      if (mounted) setState(() => _walletBalance = balance);
    } catch (_) {
      // bukan fatal
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSub = _activeSubscription != null;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Pilih Paket', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        actions: [
          GestureDetector(
            onTap: () async {
              final topUpDone = await Get.to<bool>(() => const TopUpScreen());
              if (topUpDone == true) _loadWalletBalance();
            },
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Colors.purple),
                    const SizedBox(width: 4),
                    Text(
                      'Rp ${_formatRupiah(_walletBalance)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Riwayat Transaksi',
            onPressed: () => Get.to(() => const TransactionHistoryScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoadingStatus)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(color: Colors.purple, minHeight: 2),
              ),
            if (hasActiveSub) _buildActiveSubscriptionBanner(),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Upgrade untuk pengalaman matching yang lebih maksimal",
                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: SubscriptionTier.all.length,
                itemBuilder: (context, index) {
                  final tier = SubscriptionTier.all[index];
                  final isSelected = tier.id == _selectedTierId;
                  final isFree = tier.priceMonthly == 0;
                  final isCurrentActiveTier = hasActiveSub && _activeSubscription!['tier'] == tier.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: isFree ? null : () => setState(() => _selectedTierId = tier.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isFree ? Colors.grey.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.purple : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(tier.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                if (isCurrentActiveTier) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                                    child: const Text('AKTIF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ] else if (tier.isPopular) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(20)),
                                    child: const Text('POPULER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ],
                                const Spacer(),
                                Icon(
                                  isFree ? Icons.check_circle : (isSelected ? Icons.check_circle : Icons.circle_outlined),
                                  color: isFree ? Colors.grey : (isSelected ? Colors.purple : Colors.grey),
                                  size: 22,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tier.formattedPrice,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isFree ? Colors.grey : Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            ...tier.features.map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check, size: 16, color: Colors.purple),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(f, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_selectedTierId == 'free' ||
                          _isProcessing ||
                          (hasActiveSub && _activeSubscription!['tier'] == _selectedTierId))
                      ? null
                      : _onSubscribePressed,
                  child: _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_buttonLabel(hasActiveSub), style: const TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buttonLabel(bool hasActiveSub) {
    if (_selectedTierId == 'free') return 'Pilih Premium atau VIP';
    if (hasActiveSub && _activeSubscription!['tier'] == _selectedTierId) return 'Paket Ini Sudah Aktif';
    return 'Beli dengan Saldo';
  }

  Widget _buildActiveSubscriptionBanner() {
    final tier = _activeSubscription!['tier'] as String;
    final expiresAt = DateTime.parse(_activeSubscription!['expires_at']);
    final tierName = SubscriptionTier.all.firstWhere((t) => t.id == tier).name;
    final formattedDate = "${expiresAt.day}/${expiresAt.month}/${expiresAt.year}";
    final isCancelled = _activeSubscription!['status'] == 'cancelled';

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.purple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kamu berlangganan $tierName, aktif sampai $formattedDate',
                  style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (!isCancelled) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isProcessing ? null : _onCancelPressed,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Batalkan Langganan', style: TextStyle(fontSize: 12)),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Langganan dibatalkan, akan berhenti otomatis setelah tanggal di atas.',
                style: TextStyle(fontSize: 11, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onCancelPressed() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Batalkan Langganan?'),
        content: const Text(
          'Batalkan dalam 15 menit pertama sejak pembelian: dana kembali 80% ke saldo, tapi subscription langsung nonaktif saat itu juga. '
          'Batalkan setelah 15 menit: dana tidak kembali, tapi kamu tetap bisa pakai fitur premium sampai masa aktif berakhir (tidak lanjut ke bulan berikutnya).',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Batal')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final refundAmount = await _subscriptionService.cancelSubscription();
      await _loadCurrentSubscription();
      await _loadWalletBalance();
      Get.snackbar(
        'Berhasil',
        refundAmount > 0
            ? 'Langganan dibatalkan & langsung nonaktif. Rp ${_formatRupiah(refundAmount)} saldo (80%) ditambahkan ke akun kamu.'
            : 'Langganan dibatalkan. Tidak ada dana kembali, tapi kamu masih bisa pakai fiturnya sampai masa aktif berakhir.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
      );
    } catch (e) {
      Get.snackbar('Gagal', 'Tidak bisa membatalkan langganan: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade100);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _onSubscribePressed() async {
    setState(() => _isProcessing = true);
    try {
      final result = await _subscriptionService.purchaseWithWallet(_selectedTierId);

      if (result.success) {
        await _loadCurrentSubscription();
        await _loadWalletBalance();
        Get.snackbar(
          'Berhasil!',
          'Paket ${result.tier} sekarang aktif.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
      } else {
        // Saldo tidak cukup -> tawarkan top up
        final shortfall = (result.required ?? 0) - (result.currentBalance ?? 0);
        final wantsTopUp = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Saldo Tidak Cukup'),
            content: Text(
              'Saldo kamu Rp ${_formatRupiah(result.currentBalance ?? 0)}, dibutuhkan Rp ${_formatRupiah(result.required ?? 0)}. '
              'Kurang Rp ${_formatRupiah(shortfall)}. Mau top up sekarang?',
            ),
            actions: [
              TextButton(onPressed: () => Get.back(result: false), child: const Text('Nanti')),
              TextButton(onPressed: () => Get.back(result: true), child: const Text('Top Up')),
            ],
          ),
        );

        if (wantsTopUp == true) {
          final topUpDone = await Get.to<bool>(() => const TopUpScreen());
          if (topUpDone == true) await _loadWalletBalance();
        }
      }
    } catch (e) {
      Get.snackbar('Gagal', 'Terjadi kesalahan: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade100);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }
}