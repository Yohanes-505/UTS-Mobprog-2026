import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/subscription_service.dart';

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  final SubscriptionService _service = SubscriptionService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getWalletHistory();
      setState(() => _history = data);
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Tidak bisa memuat riwayat saldo: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Riwayat Saldo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      body: RefreshIndicator(
        color: Colors.purple,
        onRefresh: _loadHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.purple))
            : _history.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text('Belum ada riwayat perubahan saldo', style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildHistoryCard(_history[index]),
                  ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> entry) {
    final type = entry['type'] as String;
    final amount = entry['amount'] as int;
    final description = entry['description'] as String? ?? '';
    final createdAt = DateTime.parse(entry['created_at']);
    final formattedDate =
        "${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";
    final isPositive = amount >= 0;
    final formattedAmount = amount.abs().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );

    late IconData icon;
    late Color color;
    late String label;

    switch (type) {
      case 'topup_credit':
        icon = Icons.add_card;
        color = Colors.green;
        label = 'Top Up';
        break;
      case 'subscription_debit':
        icon = Icons.workspace_premium_outlined;
        color = Colors.purple;
        label = 'Pembelian Subscription';
        break;
      case 'cancel_refund':
        icon = Icons.replay_circle_filled_outlined;
        color = Colors.orange;
        label = 'Refund Pembatalan';
        break;
      default:
        icon = Icons.swap_horiz;
        color = Colors.grey;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                if (description.isNotEmpty)
                  Text(description, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'}Rp $formattedAmount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}