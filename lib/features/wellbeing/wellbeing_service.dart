import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pilihan mood untuk check-in harian (1 = paling buruk, 5 = paling baik).
class MoodOption {
  final int value;
  final String emoji;
  final String label;

  const MoodOption(this.value, this.emoji, this.label);

  static const List<MoodOption> all = [
    MoodOption(1, '😞', 'Berat'),
    MoodOption(2, '😕', 'Kurang baik'),
    MoodOption(3, '😐', 'Biasa'),
    MoodOption(4, '🙂', 'Baik'),
    MoodOption(5, '😄', 'Sangat baik'),
  ];

  static MoodOption of(int value) =>
      all.firstWhere((m) => m.value == value, orElse: () => all[2]);
}

class MoodCheckin {
  final int mood;
  final String? note;
  final DateTime createdAt;

  const MoodCheckin({required this.mood, this.note, required this.createdAt});

  factory MoodCheckin.fromMap(Map<String, dynamic> map) {
    return MoodCheckin(
      mood: (map['mood'] as num).toInt(),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}

/// Fitur SDG 3: check-in mood, pelacakan waktu layar, dan pengingat
/// istirahat. Mood disimpan di Supabase (tabel `mood_checkins`), waktu
/// layar disimpan lokal di perangkat (shared_preferences).
class WellbeingService {
  WellbeingService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static String _userKey(String key) =>
      '${key}_${_client.auth.currentUser?.id ?? 'guest'}';

  // Mood check-in

  static Future<void> saveMood(int mood, {String? note}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Sesi berakhir. Silakan login ulang.');

    final cleanNote = note?.trim();
    await _client.from('mood_checkins').insert({
      'user_id': uid,
      'mood': mood,
      if (cleanNote != null && cleanNote.isNotEmpty) 'note': cleanNote,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey('mood_checkin_date'), _today);
  }

  static Future<List<MoodCheckin>> recentMoods({int days = 7}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];

    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await _client
        .from('mood_checkins')
        .select('mood, note, created_at')
        .eq('user_id', uid)
        .gte('created_at', since.toUtc().toIso8601String())
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => MoodCheckin.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<bool> hasCheckedInToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey('mood_checkin_date')) == _today;
  }

  /// `true` kalau hari ini belum pernah ditawari check-in. Sekaligus
  /// menandai sudah ditawari, supaya pop-up hanya muncul sekali sehari.
  static Future<bool> shouldPromptMoodToday() async {
    if (await hasCheckedInToday()) return false;

    final prefs = await SharedPreferences.getInstance();
    final key = _userKey('mood_prompt_date');
    if (prefs.getString(key) == _today) return false;

    await prefs.setString(key, _today);
    return true;
  }

  // Waktu layar
  static const _usageKey = 'screen_time_seconds';
  static const _usageDateKey = 'screen_time_date';
  static const _nextReminderKey = 'screen_time_next_reminder';
  static const _limitKey = 'screen_time_limit_minutes';
  static const _enabledKey = 'screen_time_reminder_enabled';

  static const int defaultLimitMinutes = 60;
  static const int snoozeMinutes = 15;

  /// Reset hitungan kalau tanggal sudah berganti.
  static Future<SharedPreferences> _usagePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_usageDateKey) != _today) {
      await prefs.setString(_usageDateKey, _today);
      await prefs.setInt(_usageKey, 0);
      await prefs.remove(_nextReminderKey);
    }
    return prefs;
  }

  static Future<int> todaySeconds() async {
    final prefs = await _usagePrefs();
    return prefs.getInt(_usageKey) ?? 0;
  }

  static Future<int> addSeconds(int seconds) async {
    final prefs = await _usagePrefs();
    final total = (prefs.getInt(_usageKey) ?? 0) + seconds;
    await prefs.setInt(_usageKey, total);
    return total;
  }

  static Future<int> limitMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_limitKey) ?? defaultLimitMinutes;
  }

  static Future<void> setLimitMinutes(int minutes) async {
    final prefs = await _usagePrefs();
    await prefs.setInt(_limitKey, minutes);
    await prefs.remove(_nextReminderKey); // pakai batas baru
  }

  static Future<bool> reminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// `true` kalau pengingat istirahat perlu ditampilkan sekarang.
  static Future<bool> shouldRemind(int totalSeconds) async {
    if (!await reminderEnabled()) return false;

    final prefs = await _usagePrefs();
    final limit = (prefs.getInt(_limitKey) ?? defaultLimitMinutes) * 60;
    final next = prefs.getInt(_nextReminderKey) ?? limit;
    return totalSeconds >= next;
  }

  /// Tunda pengingat berikutnya snoozeMinutes menit dari sekarang.
  static Future<void> snoozeReminder(int totalSeconds) async {
    final prefs = await _usagePrefs();
    await prefs.setInt(_nextReminderKey, totalSeconds + snoozeMinutes * 60);
  }
}