import 'package:bumble/models/profile_model.dart';
import 'package:bumble/services/supabase_service.dart';

class MatchChatService {
  const MatchChatService();

  /// Ambil daftar profil user lain yang match sama user yang sedang login
  Future<List<ProfileModel>> getMyMatches() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      final response = await supabase
          .from('matches')
          .select('*, user1:profiles!user1_id(*), user2:profiles!user2_id(*)')
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
          .order('created_at', ascending: false);

      final List<ProfileModel> matchedProfiles = [];
      
      for (final row in response) {
        // Cek apakah posisi kita ada di user1_id atau user2_id
        final isUser1 = row['user1_id'] == currentUserId;
        
        // Ambil map data milik lawan bicara berdasarkan posisi kita
        final otherUserData = isUser1 ? row['user2'] : row['user1'];
        
        if (otherUserData != null) {
          matchedProfiles.add(ProfileModel.fromMap(Map<String, dynamic>.from(otherUserData)));
        }
      }
      return matchedProfiles;
    } catch (e) {
      print('Error fetching matches: $e');
      return [];
    }
  }

  /// Mengambil daftar chat / percakapan terakhir
  Future<List<Map<String, dynamic>>> getConversations() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      // Query untuk mengambil pesan terakhir per match
      final response = await supabase
          .from('messages')
          .select('*, matches(*)')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }
}