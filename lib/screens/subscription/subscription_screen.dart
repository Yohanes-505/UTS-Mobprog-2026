import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/subscription_tier.dart';
import '../../services/subscription_service.dart';
import 'payment_webview_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  String _selectedTierId = 'plus';
  bool _isProcessing = false;
  bool _isLoadingStatus = true;
  Map<String, dynamic>? _activeSubscription; // null = belum ada / basic

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    setState(() => _isLoadingStatus = true);
    try {
      final sub = await _subscriptionService.getMySubscription();
      // Anggap aktif hanya kalau status 'active' DAN belum lewat expires_at
      final isStillActive = sub != null &&
          sub['status'] == 'active' &&
          sub['expires_at'] != null &&
          DateTime.parse(sub['expires_at']).isAfter(DateTime.now());

      setState(() {
        _activeSubscription = isStillActive ? sub : null;
        if (isStillActive) _selectedTierId = sub['tier'];
      });
    } catch (_) {
      // Kalau gagal load status, biarkan saja tanpa banner (bukan fatal)
    } finally {
      if (mounted) setState(() => _isLoadingStatus = false);
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
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Pilih Paket',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
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
                  final isCurrentActiveTier =
                      hasActiveSub && _activeSubscription!['tier'] == tier.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: isFree
                          ? null
                          : () => setState(() => _selectedTierId = tier.id),
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
                                Text(
                                  tier.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isCurrentActiveTier) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'AKTIF',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ] else if (tier.isPopular) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'POPULER',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Icon(
                                  isFree
                                      ? Icons.check_circle
                                      : (isSelected ? Icons.check_circle : Icons.circle_outlined),
                                  color: isFree
                                      ? Colors.grey
                                      : (isSelected ? Colors.purple : Colors.grey),
                                  size: 22,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tier.formattedPrice,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isFree ? Colors.grey : Colors.black87,
                              ),
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
                                    Expanded(
                                      child: Text(
                                        f,
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      ),
                                    ),
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
                  onPressed: (_selectedTierId == 'basic' ||
                          _isProcessing ||
                          (hasActiveSub && _activeSubscription!['tier'] == _selectedTierId))
                      ? null
                      : _onSubscribePressed,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _buttonLabel(hasActiveSub),
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buttonLabel(bool hasActiveSub) {
    if (_selectedTierId == 'basic') return 'Pilih Plus atau Premium';
    if (hasActiveSub && _activeSubscription!['tier'] == _selectedTierId) {
      return 'Paket Ini Sudah Aktif';
    }
    return 'Lanjut ke Pembayaran';
  }

  Widget _buildActiveSubscriptionBanner() {
    final tier = _activeSubscription!['tier'] as String;
    final expiresAt = DateTime.parse(_activeSubscription!['expires_at']);
    final tierName = SubscriptionTier.all.firstWhere((t) => t.id == tier).name;
    final formattedDate = "${expiresAt.day}/${expiresAt.month}/${expiresAt.year}";

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Row(
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
    );
  }

  Future<void> _onSubscribePressed() async {
    setState(() => _isProcessing = true);

    try {
      final result = await _subscriptionService.createTransaction(_selectedTierId);
      if (!mounted) return;

      final paymentFinished = await Get.to<bool>(
        () => PaymentWebviewScreen(redirectUrl: result.redirectUrl, orderId: result.orderId),
      );

      if (!mounted) return;

      if (paymentFinished == true) {
        await _pollForSubscriptionUpdate();
      }
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pollForSubscriptionUpdate() async {
    Get.snackbar(
      'Memeriksa Status',
      'Menunggu konfirmasi pembayaran...',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );

    const maxAttempts = 6;
    const delay = Duration(seconds: 3);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(delay);
      if (!mounted) return;

      final sub = await _subscriptionService.getMySubscription();
      final isNowActive = sub != null &&
          sub['status'] == 'active' &&
          sub['tier'] == _selectedTierId &&
          sub['expires_at'] != null &&
          DateTime.parse(sub['expires_at']).isAfter(DateTime.now());

      if (isNowActive) {
        setState(() => _activeSubscription = sub);
        Get.snackbar(
          'Berhasil!',
          'Paket ${sub['tier']} sekarang aktif.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
        return;
      }
    }

    Get.snackbar(
      'Belum Terkonfirmasi',
      'Status pembayaran belum berubah. Coba cek lagi beberapa saat lagi.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade100,
    );
  }
}