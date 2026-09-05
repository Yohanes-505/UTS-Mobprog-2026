import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/subscription_tier.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedTierId = 'plus';

  @override
  Widget build(BuildContext context) {
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
                                if (tier.isPopular) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'POPULER',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _selectedTierId == 'basic'
                      ? null
                      : () => _onSubscribePressed(context),
                  child: Text(
                    _selectedTierId == 'basic'
                        ? 'Pilih Plus atau Premium'
                        : 'Lanjut ke Pembayaran',
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

  void _onSubscribePressed(BuildContext context) {
    final tier = SubscriptionTier.all.firstWhere((t) => t.id == _selectedTierId);
    Get.snackbar(
      'Checkout',
      '${tier.name} (${tier.formattedPrice}) — pembayaran belum aktif',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}