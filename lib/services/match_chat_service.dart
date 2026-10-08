import 'dart:async';

import 'package:Meetcha/models/chat_message.dart';
import 'package:Meetcha/models/match_preview.dart';
import 'package:Meetcha/models/profile_model.dart';
import 'package:Meetcha/services/block_service.dart';
import 'package:Meetcha/utils/network_error.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

///
/// Tabel `messages` hanya punya `match_id` (tidak ada receiver_id), jadi
/// sebelum membaca/mengirim pesan kita perlu tahu id baris `matches`-nya.
class ChatRoom {
  final String primaryMatchId;
  final List<String> matchIds;

  // Ini buat nunjukin kapan match terjadi, fungsinya biar bisa dihitung kadaluarsanya
  final DateTime? matchedAt;

  const ChatRoom({
    required this.primaryMatchId,
    required this.matchIds,
    this.matchedAt,
  });
}

class _MatchRef {
  final List<String> ids = [];
  DateTime? matchedAt;
}

class MatchChatService {
  const MatchChatService();

  static const String _imageBucket = 'avatars';

  static final ValueNotifier<int> unreadTotal = ValueNotifier<int>(0);

  /// (tab Match dibuka, atau ada match baru dari Home/Likes).
  /// Layar Match mendengarkan ini lalu memuat ulang datanya.
  static final ValueNotifier<int> matchesChanged = ValueNotifier<int>(0);
  static void notifyMatchesChanged() => matchesChanged.value++;

  SupabaseClient get _client => Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<ProfileModel>> getMyMatches() async {
    final myId = currentUserId;
    if (myId == null) return [];

    final refs = _groupByCounterpart(await _fetchMatchRows(myId), myId);
    final hidden = await BlockService.getHiddenUserIds(myId);
    refs.removeWhere((id, _) => hidden.contains(id));

    final profiles = await _fetchProfiles(refs.keys);
    return profiles.values.toList();
  }

  Future<List<MatchPreview>> getMatchPreviews() async {
    final myId = currentUserId;
    if (myId == null) return [];

    final refs = _groupByCounterpart(await _fetchMatchRows(myId), myId);
    final hidden = await BlockService.getHiddenUserIds(myId);
    refs.removeWhere((id, _) => hidden.contains(id));
    if (refs.isEmpty) {
      unreadTotal.value = 0;
      return [];
    }

    final profiles = await _fetchProfiles(refs.keys);

    final unreadFuture = _fetchUnreadCounts(
      refs.values.expand((ref) => ref.ids).toList(),
      myId,
    );

    final previews = await Future.wait(
      refs.entries.where((e) => profiles.containsKey(e.key)).map((e) async {
        final res = await _getLastMessage(e.value.ids);
        final last = res.message;
        final counts = await unreadFuture;
        return MatchPreview(
          profile: profiles[e.key]!,
          matchedAt: e.value.matchedAt,
          matchIds: List<String>.unmodifiable(e.value.ids),
          lastMessage: last?.previewText,
          lastMessageAt: last?.createdAt,
          lastMessageIsMine: last?.senderId == myId,
          activityKnown: res.ok,
          unreadCount: e.value.ids.fold<int>(
            0,
            (sum, id) => sum + (counts?[id] ?? 0),
          ),
        );
      }),
    );

    final unread = await unreadFuture;

    final list = previews.toList();

    if (list.any((p) => p.isExpired)) {
      list.removeWhere((p) => p.isExpired);
      unawaited(purgeExpiredMatches());
    }

    if (unread != null) {
      unreadTotal.value = list.fold<int>(0, (sum, p) => sum + p.unreadCount);
    }

    list.sort((a, b) {
      final ta = a.lastMessageAt ?? a.matchedAt;
      final tb = b.lastMessageAt ?? b.matchedAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return list;
  }

  Future<List<Map<String, dynamic>>> _fetchMatchRows(String myId) async {
    final rows = await withRetry(
      () async => await _client
          .from('matches')
          .select()
          .or('user1_id.eq.$myId,user2_id.eq.$myId')
          .order('created_at', ascending: true)
          .order('id', ascending: true),
    );
    return List<Map<String, dynamic>>.from(rows);
  }

  Map<String, _MatchRef> _groupByCounterpart(
    List<Map<String, dynamic>> rows,
    String myId,
  ) {
    final result = <String, _MatchRef>{};
    for (final row in rows) {
      final a = row['user1_id'].toString();
      final b = row['user2_id'].toString();
      final other = a == myId ? b : a;
      if (other == myId) continue;
      final ref = result.putIfAbsent(other, () => _MatchRef());
      ref.ids.add(row['id'].toString());

      final at = DateTime.tryParse('${row['created_at']}')?.toLocal();
      if (at != null && (ref.matchedAt == null || at.isAfter(ref.matchedAt!))) {
        ref.matchedAt = at;
      }
    }
    return result;
  }

  Future<Map<String, ProfileModel>> _fetchProfiles(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return {};

    final rows = await withRetry(
      () async => await _client.from('profiles').select().inFilter('id', list),
    );
    return {
      for (final row in rows) row['id'].toString(): ProfileModel.fromMap(row),
    };
  }

  Future<({ChatMessage? message, bool ok})> _getLastMessage(
    List<String> matchIds,
  ) async {
    if (matchIds.isEmpty) return (message: null, ok: true);
    try {
      final row = await withRetry(
        () async => await _client
            .from('messages')
            .select()
            .inFilter('match_id', matchIds)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle(),
        attempts: 2,
      );
      return (
        message: row == null ? null : ChatMessage.fromMap(row),
        ok: true,
      );
    } catch (e) {
      debugPrint('Gagal memuat pesan terakhir: $e');
      return (message: null, ok: false);
    }
  }

  Future<Map<String, int>?> _fetchUnreadCounts(
    List<String> matchIds,
    String myId,
  ) async {
    if (matchIds.isEmpty) return {};
    try {
      final rows = await withRetry(
        () async => await _client
            .from('messages')
            .select('match_id')
            .inFilter('match_id', matchIds)
            .neq('sender_id', myId)
            .or('is_read.eq.false,is_read.is.null'),
        attempts: 2,
      );
      final counts = <String, int>{};
      for (final row in rows) {
        final id = row['match_id'].toString();
        counts[id] = (counts[id] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugPrint('Gagal memuat jumlah pesan belum dibaca: $e');
      return null;
    }
  }

  Future<void> purgeExpiredMatches() async {
    try {
      await _client.rpc('expire_my_idle_matches');
    } catch (e) {
      debugPrint('Gagal menghapus match kadaluarsa: $e');
    }
  }

  /// cari profil lawan chat dari sebuah match id 
  /// dipakai saat notifikasi "prsan baru" / "it's a match!"
  Future<ProfileModel?> getProfileForMatchId(String matchId) async {
    final myId = currentUserId;
    if (myId == null) return null;

    try {
      final row = await _client
          .from('matches')
          .select('user1_id, user2_id')
          .eq('id', matchId)
          .maybeSingle();
      if (row == null) return null;

      final a = row['user1_id'].toString();
      final b = row['user2_id'].toString();
      final otherId = a == myId ? b : a;
      if (otherId == myId) return null;

      final hidden = await BlockService.getHiddenUserIds(myId);
      if (hidden.contains(otherId)) return null;

      final profiles = await _fetchProfiles([otherId]);
      return profiles[otherId];
    } catch (e) {
      debugPrint('Gagal ambil profil dari match_id: $e');
      return null;
    }
  }

  Future<ChatRoom> openRoom(String otherId) async {
    final myId = currentUserId;
    if (myId == null) {
      throw StateError('Sesi berakhir. Silakan login ulang.');
    }

    final rows = await withRetry(
      () async => await _client
          .from('matches')
          .select('id, created_at')
          .or(
            'and(user1_id.eq.$myId,user2_id.eq.$otherId),'
            'and(user1_id.eq.$otherId,user2_id.eq.$myId)',
          )
          .order('created_at', ascending: true)
          .order('id', ascending: true),
    );

    final ids = rows.map((r) => r['id'].toString()).toList();
    if (ids.isEmpty) {
      throw StateError(
        'Match dengan pengguna ini tidak ditemukan. Mungkin sudah dihapus.',
      );
    }
    DateTime? matchedAt;
    for (final r in rows) {
      final at = DateTime.tryParse('${r['created_at']}')?.toLocal();
      if (at != null && (matchedAt == null || at.isAfter(matchedAt))) {
        matchedAt = at;
      }
    }

    return ChatRoom(
      primaryMatchId: ids.first,
      matchIds: ids,
      matchedAt: matchedAt,
    );
  }

  Future<List<ChatMessage>> getMessages(ChatRoom room, {int limit = 200}) async {
    final rows = await withRetry(
      () async => await _client
          .from('messages')
          .select()
          .inFilter('match_id', room.matchIds)
          .order('created_at', ascending: false)
          .limit(limit),
    );
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<ChatMessage> sendMessage({
    required ChatRoom room,
    required String text,
  }) async {
    final myId = currentUserId;
    if (myId == null) {
      throw StateError('Sesi berakhir. Silakan login ulang.');
    }

    final row = await _client
        .from('messages')
        .insert({
          'match_id': room.primaryMatchId,
          'sender_id': myId,
          'content': text,
        })
        .select()
        .single()
        .timeout(const Duration(seconds: 15));
    return ChatMessage.fromMap(row);
  }

  /// Kirim pesan gift ke match [otherId]. Di chat tampil sebagai kartu gift.
  Future<void> sendGiftMessage({
    required String otherId,
    required String giftName,
  }) async {
    final room = await openRoom(otherId);
    await sendMessage(room: room, text: ChatMessage.giftText(giftName));
  }

  Future<String> uploadChatImage({
    required Uint8List bytes,
    required String extension,
  }) async {
    final myId = currentUserId;
    if (myId == null) {
      throw StateError('Sesi berakhir. Silakan login ulang.');
    }

    final ext = _normalizeImageExtension(extension);
    final path = '$myId/chat/${DateTime.now().microsecondsSinceEpoch}.$ext';

    await _client.storage
        .from(_imageBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _imageContentType(ext),
          ),
        )
        .timeout(const Duration(seconds: 60));

    return _client.storage.from(_imageBucket).getPublicUrl(path);
  }

  static String _normalizeImageExtension(String extension) {
    final ext = extension.toLowerCase();
    const allowed = {'jpg', 'jpeg', 'png', 'webp', 'gif'};
    return allowed.contains(ext) ? ext : 'jpg';
  }

  static String _imageContentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> markMessagesRead(ChatRoom room) async {
    await _client
        .rpc('mark_messages_read', params: {'p_match_ids': room.matchIds})
        .timeout(const Duration(seconds: 10));
  }

  RealtimeChannel subscribeToRoom({
    required ChatRoom room,
    required void Function(ChatMessage message) onMessage,
    void Function(ChatMessage message)? onMessageUpdated,
    void Function(RealtimeSubscribeStatus status, Object? error)? onStatus,
  }) {
    final topic =
        'chat-${room.primaryMatchId}-${DateTime.now().microsecondsSinceEpoch}';

    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'match_id',
      value: room.primaryMatchId,
    );

    return _client
        .channel(topic)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: filter,
          callback: (payload) =>
              onMessage(ChatMessage.fromMap(payload.newRecord)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: filter,
          callback: (payload) =>
              onMessageUpdated?.call(ChatMessage.fromMap(payload.newRecord)),
        )
        .subscribe(onStatus);
  }

  RealtimeChannel subscribeToAnyIncomingMessage({
    required bool Function(String matchId) isMyMatch,
    required VoidCallback onChange,
  }) {
    final topic = 'inbox-$currentUserId-${DateTime.now().microsecondsSinceEpoch}';

    return _client
        .channel(topic)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final matchId = payload.newRecord['match_id']?.toString();
            if (matchId != null && isMyMatch(matchId)) onChange();
          },
        )
        .subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}