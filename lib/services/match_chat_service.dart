import 'package:bumble/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchChatService {
  const MatchChatService();

  Future<List<ProfileModel>> getMyMatches() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final response = await Supabase.instance.client
        .from('matches')
        .select('user1_id, user2_id')
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    List<String> matchedUserIds = [];
    for (var row in response) {
      if (row['user1_id'] == currentUserId) {
        matchedUserIds.add(row['user2_id']);
      } else {
        matchedUserIds.add(row['user1_id']);
      }
    }

    if (matchedUserIds.isEmpty) return [];

    final profilesResponse = await Supabase.instance.client
        .from('profiles')
        .select()
        .filter('id', 'in', matchedUserIds);

    return List<Map<String, dynamic>>.from(profilesResponse)
        .map((e) => ProfileModel.fromMap(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final matches = await getMyMatches();
    List<Map<String, dynamic>> conversations = [];

    for (var match in matches) {
      final msgResponse = await Supabase.instance.client
          .from('messages')
          .select()
          .or('and(sender_id.eq.$currentUserId,receiver_id.eq.${match.id}),and(sender_id.eq.${match.id},receiver_id.eq.$currentUserId)')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      conversations.add({
        'profile': match,
        'message': msgResponse != null ? msgResponse['message'] : 'Mulai percakapan baru!',
        'created_at': msgResponse != null ? msgResponse['created_at'] : null,
      });
    }

    conversations.sort((a, b) {
      if (a['created_at'] == null && b['created_at'] == null) return 0;
      if (a['created_at'] == null) return 1;
      if (b['created_at'] == null) return -1;
      return DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']));
    });

    return conversations;
  }
}