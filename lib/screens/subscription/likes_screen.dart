import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/subscription_service.dart';
import 'subscription_screen.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  final SubscriptionService _service = SubscriptionService();
  LikersResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getMyLikers();
      setState(() => _result = result);
    } catch (e) {
      Get.snackbar('Gagal', 'Tidak bisa memuat data: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
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
        title: const Text('Menyukaimu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : (_result == null
              ? const SizedBox()
              : (_result!.eligible ? _buildEligibleView() : _buildUpsellView())),
    );
  }

  Widget _buildEligibleView() {
    if (_result!.likerIds.isEmpty) {
      return RefreshIndicator(
        color: Colors.purple,
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.favorite_border, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Center(child: Text('Belum ada yang like kamu', style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.purple,
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _result!.likerIds.length,
        itemBuilder: (context, index) => _buildLikerTile(_result!.likerIds[index]),
      ),
    );
  }

  Widget _buildLikerTile(String likerId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 48, color: Colors.purple),
          SizedBox(height: 8),
          Text('Menyukaimu', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildUpsellView() {
    final count = _result!.totalCount;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Stack kartu blur sebagai teaser visual
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(3, (i) {
                return Positioned(
                  top: i * 10.0,
                  child: Transform.rotate(
                    angle: (i - 1) * 0.08,
                    child: Container(
                      width: 140,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 40),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            count > 0 ? '$count orang menyukaimu!' : 'Lihat siapa yang menyukaimu',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Upgrade ke Premium atau VIP untuk melihat semua orang yang sudah menyukaimu.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Get.to(() => const SubscriptionScreen()),
              child: const Text('Upgrade Sekarang', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}