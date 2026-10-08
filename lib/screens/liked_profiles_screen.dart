import 'package:Meetcha/constants/app_colors.dart';
import 'package:Meetcha/models/profile_model.dart';
import 'package:Meetcha/services/block_service.dart';
import 'package:Meetcha/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Daftar profil yang pernah kamu like (dari tabel `swipes`).
/// User yang saling block tidak ditampilkan.
Future<List<ProfileModel>> fetchLikedProfiles() async {
  final client = Supabase.instance.client;
  final myId = client.auth.currentUser?.id;
  if (myId == null) return [];

  final rows = await client
      .from('swipes')
      .select('swiped_id')
      .eq('swiper_id', myId)
      .eq('action', 'like'); // sesuaikan kalau nama kolom aksi berbeda

  final likedIds = rows.map((e) => e['swiped_id'].toString()).toSet();
  if (likedIds.isEmpty) return [];

  final hiddenIds = await BlockService.getHiddenUserIds(myId);
  final ids = likedIds.where((id) => !hiddenIds.contains(id)).toList();
  if (ids.isEmpty) return [];

  final profiles =
      await client.from('profiles').select().inFilter('id', ids);
  return profiles.map(ProfileModel.fromMap).toList();
}

class LikedProfilesScreen extends StatefulWidget {
  const LikedProfilesScreen({super.key});

  @override
  State<LikedProfilesScreen> createState() => _LikedProfilesScreenState();
}

class _LikedProfilesScreenState extends State<LikedProfilesScreen> {
  List<ProfileModel> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _isLoading = true);
    try {
      final result = await fetchLikedProfiles();
      if (!mounted) return;
      setState(() => _profiles = result);
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Tidak bisa memuat daftar yang kamu sukai.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        title: const Text(
          'Yang Kamu Sukai',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryDeep),
            )
          : RefreshIndicator(
              color: AppColors.primaryDeep,
              onRefresh: () => _load(showSpinner: false),
              child: _profiles.isEmpty ? _buildEmpty() : _buildList(),
            ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(Icons.favorite_border, size: 48, color: AppColors.mist),
        SizedBox(height: 12),
        Center(
          child: Text(
            'Kamu belum menyukai siapa pun',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _profiles.length,
      itemBuilder: (context, index) => _LikedProfileTile(
        profile: _profiles[index],
      ),
    );
  }
}

class _LikedProfileTile extends StatelessWidget {
  final ProfileModel profile;

  const _LikedProfileTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    final title =
        profile.age != null ? '${profile.name}, ${profile.age}' : profile.name;
    final subtitle = (profile.city != null && profile.city!.isNotEmpty)
        ? profile.city!
        : null;
    final interests = profile.interests.take(3).join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          UserAvatar(photoUrl: profile.photoUrl, radius: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (profile.isFaceVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: AppColors.matchaDeep,
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (interests.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    interests,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.favorite, size: 20, color: AppColors.matchaDeep),
        ],
      ),
    );
  }
}