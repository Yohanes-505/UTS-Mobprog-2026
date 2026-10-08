import 'package:Meetcha/constants/app_colors.dart';
import 'package:Meetcha/models/profile_model.dart';
import 'package:Meetcha/services/match_chat_service.dart';
import 'package:Meetcha/widgets/meetcha_loading.dart';
import 'package:Meetcha/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Kirim gift dari inventori ke salah satu match.
///
/// Alur: pilih match (selalu muncul, walaupun match-nya cuma satu)
/// -> konfirmasi -> pindahkan gift lewat RPC `transfer_gift_to_match`
/// -> gift muncul sebagai kartu di chat match.
///
/// Mengembalikan true kalau gift berhasil dikirim.
Future<bool> sendInventoryGiftToMatch(
  BuildContext context, {
  required String userGiftId,
  required String giftName,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  final target = await showModalBottomSheet<ProfileModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MatchPickerSheet(giftName: giftName),
  );
  if (target == null || !context.mounted) return false;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Kirim Gift'),
      content: Text(
        'Kirim $giftName ke ${target.name}? '
        'Gift akan pindah dari inventorimu dan tidak bisa dibatalkan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Kirim'),
        ),
      ],
    ),
  );
  if (confirm != true) return false;

  try {
    final res = await Supabase.instance.client.rpc(
      'transfer_gift_to_match',
      params: {'p_user_gift_id': userGiftId, 'p_receiver_id': target.id},
    );

    final result = res is Map
        ? Map<String, dynamic>.from(res)
        : <String, dynamic>{'success': true};
    final success = result['success'] == true;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ??
              (success ? 'Gift berhasil dikirim!' : 'Gagal mengirim gift.'),
        ),
      ),
    );
    if (!success) return false;

    // Munculkan gift sebagai pesan di chat match. Gift sudah terkirim,
    // jadi kegagalan di sini tidak membatalkannya.
    try {
      await const MatchChatService().sendGiftMessage(
        otherId: target.id,
        giftName: giftName,
      );
    } catch (e) {
      debugPrint('Gagal mengirim pesan gift ke chat: $e');
    }
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Gagal mengirim gift: $e')),
    );
    return false;
  }
}

/// Bottom sheet daftar match untuk memilih penerima gift.
class _MatchPickerSheet extends StatefulWidget {
  final String giftName;

  const _MatchPickerSheet({required this.giftName});

  @override
  State<_MatchPickerSheet> createState() => _MatchPickerSheetState();
}

class _MatchPickerSheetState extends State<_MatchPickerSheet> {
  late Future<List<ProfileModel>> _matches =
      const MatchChatService().getMyMatches();

  void _reload() {
    setState(() => _matches = const MatchChatService().getMyMatches());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
              child: Text(
                'Kirim ${widget.giftName} ke siapa?',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Pilih salah satu match kamu.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Flexible(
              child: FutureBuilder<List<ProfileModel>>(
                future: _matches,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: MeetchaLoading(size: 90)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Gagal memuat daftar match.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _reload,
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    );
                  }

                  final matches = snapshot.data ?? const <ProfileModel>[];
                  if (matches.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Kamu belum punya match untuk dikirimi gift.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final p = matches[index];
                      final city = (p.city ?? '').trim();
                      return ListTile(
                        leading: UserAvatar(photoUrl: p.photoUrl, radius: 22),
                        title: Text(
                          p.age != null ? '${p.name}, ${p.age}' : p.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: city.isNotEmpty ? Text(city) : null,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}