import 'dart:typed_data';

import 'package:bumble/models/profile_model.dart';
import 'package:bumble/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

/// Semua akses tabel `profiles` + bucket `avatars`.
class ProfileService {
  const ProfileService();

  static const String _table = 'profiles';
  static const String _bucket = 'avatars';

  String? get currentUserId => supabase.auth.currentUser?.id;

  /// Ambil profil milik user yang sedang login.
  Future<ProfileModel?> getMyProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return getProfileById(userId);
  }

  Future<ProfileModel?> getProfileById(String userId) async {
    final data =
        await supabase.from(_table).select().eq('id', userId).maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromMap(data);
  }

  /// Simpan data Profile Setup / Edit Profile.
  Future<ProfileModel> saveProfile({
    required String userId,
    String? name,
    int? age,
    String? bio,
    Gender? gender,
    List<String>? interests,
    String? photoUrl,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name.trim();
    if (age != null) payload['age'] = age;
    if (bio != null) payload['bio'] = bio.trim();
    if (gender != null) payload['gender'] = gender.dbValue;
    if (interests != null) payload['interests'] = interests;
    if (photoUrl != null) payload['photo_url'] = photoUrl;

    // upsert: kalau baris profil belum ada (mis. insert saat signup gagal
    // karena sesi belum aktif), baris dibuat di sini alih-alih error.
    payload['id'] = userId;

    final data = await supabase
        .from(_table)
        .upsert(payload)
        .select()
        .single();

    return ProfileModel.fromMap(data);
  }

  /// Simpan filter preferensi (usia, jarak max, gender).
  Future<ProfileModel> savePreferences({
    required String userId,
    required Gender? prefGender,
    required int minAge,
    required int maxAge,
    required int maxDistanceKm,
  }) async {
    final data = await supabase
        .from(_table)
        .upsert({
          'id': userId,
          'pref_gender': prefGender?.dbValue,
          'pref_min_age': minAge,
          'pref_max_age': maxAge,
          'pref_max_distance_km': maxDistanceKm,
        })
        .select()
        .single();

    return ProfileModel.fromMap(data);
  }

  /// Simpan koordinat GPS ke profil.
  Future<ProfileModel> saveLocation({
    required String userId,
    required double latitude,
    required double longitude,
    String? city,
  }) async {
    final data = await supabase
        .from(_table)
        .upsert({
          'id': userId,
          'latitude': latitude,
          'longitude': longitude,
          'city': city,
          'location_updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return ProfileModel.fromMap(data);
  }

  /// Upload foto profil ke bucket `avatars` dan kembalikan public URL-nya.
  /// Pakai `uploadBinary` supaya jalan di Android maupun Flutter Web.
  Future<String> uploadPhoto({
    required String userId,
    required Uint8List bytes,
    String fileExtension = 'jpg',
  }) async {
    final path = '$userId/avatar.$fileExtension';

    await supabase.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeFor(fileExtension),
          ),
        );

    final publicUrl = supabase.storage.from(_bucket).getPublicUrl(path);

    // Cache-buster: tanpa ini foto lama masih muncul setelah diganti.
    final busted = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    await supabase
        .from(_table)
        .update({'photo_url': busted}).eq('id', userId);

    return busted;
  }

  /// Ambil user terdekat sesuai radius + filter preferensi (RPC Haversine).
  Future<List<ProfileModel>> getNearbyProfiles({int limit = 20}) async {
    final result = await supabase.rpc(
      'nearby_profiles',
      params: {'p_limit': limit},
    );
    return (result as List)
        .map((e) => ProfileModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static String _contentTypeFor(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

/// Dipertahankan agar `login_screen.dart` yang sudah ada tidak perlu diubah.
Future<bool> isProfileComplete(String userId) async {
  final profile = await const ProfileService().getProfileById(userId);
  return profile?.isComplete ?? false;
}