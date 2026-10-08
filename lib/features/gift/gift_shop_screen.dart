import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../services/gift_service.dart';
import '../../services/match_chat_service.dart';

class GiftShopScreen extends StatefulWidget {
<<<<<<< HEAD
  final String? receiverId;
  final String? receiverName;

  const GiftShopScreen({super.key, this.receiverId, this.receiverName});

  bool get _isSendingToOthers => receiverId != null;
=======
  const GiftShopScreen({Key? key}) : super(key: key);
>>>>>>> 53f0b52a579f91635bad06d697da23d55d6dcf64

  @override
  State<GiftShopScreen> createState() => _GiftShopScreenState();
}

class _GiftShopScreenState extends State<GiftShopScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GiftService _giftService = GiftService();
  
  List<dynamic> _gifts = [];
  int _userBalance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

 Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Ambil saldo langsung dari tabel 'wallets'
      final walletRes = await _supabase
          .from('wallets')
          .select('balance')
          .eq('user_id', userId) // Kurung tutup dan titik koma sudah diperbaiki dengan benar
          .maybeSingle();
      
      if (walletRes != null && walletRes['balance'] != null) {
        _userBalance = num.tryParse(walletRes['balance'].toString())?.toInt() ?? 0;
      } else {
        _userBalance = 0;
      }

      final giftsRes = await _supabase.from('gifts').select('*');
      _gifts = giftsRes;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _buyGift(String giftId, dynamic priceDynamic) async {
    // Konversi harga gift ke int secara aman
    int price = num.tryParse(priceDynamic.toString())?.toInt() ?? 0;

    if (_userBalance < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saldo utama tidak cukup!')),
      );
      return;
    }

<<<<<<< HEAD
    // Penerima: match yang dipilih, atau diri sendiri kalau dibuka dari menu biasa
    final receiverId = widget.receiverId ?? user.id;

    final result = await _giftService.sendGiftToUser(giftId, receiverId);

    // User mungkin sudah keluar dari halaman selama proses async
    if (!mounted) return;

=======
    final userId = _supabase.auth.currentUser!.id;
    final result = await _giftService.sendGiftToUser(giftId, userId);
    
>>>>>>> 53f0b52a579f91635bad06d697da23d55d6dcf64
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );

    if (result['success'] == true) {
<<<<<<< HEAD
      // Kalau gift dikirim ke match, munculkan juga sebagai pesan di chat mereka
      final receiverId = widget.receiverId;
      if (receiverId != null) {
        final gift = _gifts.cast<Map>().firstWhere(
              (g) => g['id'].toString() == giftId,
              orElse: () => const {},
            );
        final giftName = gift['name']?.toString() ?? 'Gift';

        try {
          await const MatchChatService().sendGiftMessage(
            otherId: receiverId,
            giftName: giftName,
          );
        } catch (e) {
          // Gift sudah terkirim; kegagalan pesan chat tidak membatalkannya.
          debugPrint('Gagal mengirim pesan gift ke chat: $e');
        }
      }

      // Refresh saldo dan katalog setelah pembelian berhasil
      await _fetchData();
=======
      // refresh saldo dan UI setelah beli
      _fetchData(); 
>>>>>>> 53f0b52a579f91635bad06d697da23d55d6dcf64
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
<<<<<<< HEAD
        title: Text(
          widget._isSendingToOthers
              ? 'Kirim Gift ke ${widget.receiverName ?? 'Match'}'
              : 'Gift Shop',
=======
        centerTitle: false,
        title: const Text(
          'Gift Shop',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.45,
          ),
>>>>>>> 53f0b52a579f91635bad06d697da23d55d6dcf64
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.matchaSoft.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Saldo: Rp $_userBalance',
                  style: const TextStyle(
                    color: AppColors.matchaDeep,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.75,
              ),
              itemCount: _gifts.length,
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSoft),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.025),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.matchaSoft.withValues(alpha: 0.58),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          size: 26,
                          color: AppColors.matchaDeep,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        gift['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Harga: Rp ${gift['price']}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nilai Tukar: Rp ${gift['convert_value']}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
<<<<<<< HEAD
                              _buyGift(gift['id'].toString(), gift['price']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                          ),
                          child: Text(
                            widget._isSendingToOthers ? 'Kirim' : 'Beli',
                            style: const TextStyle(color: Colors.white),
=======
                              _buyGift(gift['id'], gift['price']),
                          child: const Text(
                            'Beli',
                            style: TextStyle(fontWeight: FontWeight.w700),
>>>>>>> 53f0b52a579f91635bad06d697da23d55d6dcf64
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
<<<<<<< HEAD
=======

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 70),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(
              radius: 13,
              color: AppColors.matchaDeep,
            ),
            SizedBox(height: 16),
            Text(
              'Memuat gift...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
>>>>>>> 53f0b52a579f91635bad06d697da23d55d6dcf64
}