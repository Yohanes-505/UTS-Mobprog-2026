import 'package:Meetcha/constants/app_colors.dart';
import 'package:Meetcha/features/wellbeing/mood_checkin_sheet.dart';
import 'package:Meetcha/features/wellbeing/wellbeing_service.dart';
import 'package:Meetcha/profile/blocked_users_screen.dart';
import 'package:Meetcha/profile/safe_dating_tips_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Safety Center: satu tempat untuk fitur kesehatan dan keamanan (SDG 3).
class SafetyCenterScreen extends StatefulWidget {
  const SafetyCenterScreen({super.key});

  @override
  State<SafetyCenterScreen> createState() => _SafetyCenterScreenState();
}

class _SafetyCenterScreenState extends State<SafetyCenterScreen> {
  bool _loading = true;
  List<MoodCheckin> _moods = const [];
  int _todaySeconds = 0;
  int _limitMinutes = WellbeingService.defaultLimitMinutes;
  bool _reminderOn = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        WellbeingService.recentMoods(),
        WellbeingService.todaySeconds(),
        WellbeingService.limitMinutes(),
        WellbeingService.reminderEnabled(),
      ]);
      if (!mounted) return;
      setState(() {
        _moods = results[0] as List<MoodCheckin>;
        _todaySeconds = results[1] as int;
        _limitMinutes = results[2] as int;
        _reminderOn = results[3] as bool;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat Safety Center: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCheckin() async {
    final saved = await MoodCheckinSheet.show();
    if (saved == true) _load();
  }

  void _copyNumber(String number) {
    Clipboard.setData(ClipboardData(text: number));
    Get.snackbar(
      'Nomor disalin',
      '$number siap ditempel di aplikasi telepon.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      backgroundColor: Colors.white,
      colorText: AppColors.textPrimary,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Safety Center',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.matchaDeep),
            )
          : RefreshIndicator(
              color: AppColors.matchaDeep,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  const Text(
                    'Kesehatan dan keamananmu lebih penting dari match mana pun.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Check-in mood'),
                  _moodCard(),
                  const SizedBox(height: 22),
                  _sectionTitle('Waktu layar'),
                  _screenTimeCard(),
                  const SizedBox(height: 22),
                  _sectionTitle('Keamanan saat berkencan'),
                  _linkTile(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Safe Dating Tips',
                    subtitle: 'Panduan aman sebelum bertemu orang baru',
                    onTap: () => Get.to(() => const SafeDatingTipsScreen()),
                  ),
                  _linkTile(
                    icon: Icons.block,
                    title: 'Akun yang Diblokir',
                    subtitle: 'Kelola orang yang tidak ingin kamu temui lagi',
                    onTap: () => Get.to(() => const BlockedUsersScreen()),
                  ),
                  _infoCard(
                    icon: Icons.flag_outlined,
                    title: 'Cara melaporkan',
                    body: 'Tekan ikon ⋯ di kartu profil atau di dalam chat, '
                        'lalu pilih Laporkan. Laporanmu bersifat rahasia dan '
                        'orang yang dilaporkan tidak akan tahu siapa pelapornya.',
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Bantuan darurat'),
                  _hotlineTile(
                    'Layanan darurat nasional',
                    '112',
                    'Kecelakaan, kebakaran, atau keadaan darurat lain',
                  ),
                  _hotlineTile(
                    'Polisi',
                    '110',
                    'Jika kamu merasa terancam saat bertemu seseorang',
                  ),
                  _hotlineTile(
                    'Layanan kesehatan jiwa (Kemenkes)',
                    '119 ext 8',
                    'Butuh teman bicara atau dukungan psikologis',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kalau kamu atau seseorang dalam bahaya langsung, segera '
                    'hubungi 112.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      );

  Widget _moodCard() {
    final latest = _moods.isNotEmpty ? _moods.first : null;
    final now = DateTime.now();
    final checkedToday = latest != null &&
        latest.createdAt.year == now.year &&
        latest.createdAt.month == now.month &&
        latest.createdAt.day == now.day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            checkedToday
                ? 'Hari ini: ${MoodOption.of(latest!.mood).emoji} '
                    '${MoodOption.of(latest!.mood).label}'
                : 'Kamu belum check-in hari ini.',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_moods.isEmpty)
            const Text(
              'Riwayat 7 hari terakhir akan muncul di sini.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _moods.reversed.map((m) {
                  final option = MoodOption.of(m.mood);
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Tooltip(
                      message: m.note?.isNotEmpty == true
                          ? m.note!
                          : option.label,
                      child: Column(
                        children: [
                          Text(option.emoji,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 2),
                          Text(
                            '${m.createdAt.day}/${m.createdAt.month}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openCheckin,
              icon: const Icon(Icons.favorite_border_rounded, size: 18),
              label: Text(checkedToday ? 'Check-in lagi' : 'Check-in sekarang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.matchaDeep,
                side: const BorderSide(color: AppColors.primaryBorder),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _screenTimeCard() {
    final usedMinutes = (_todaySeconds / 60).floor();
    final progress = (_todaySeconds / (_limitMinutes * 60)).clamp(0.0, 1.0);
    final over = usedMinutes >= _limitMinutes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hari ini: $usedMinutes menit',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              color: over ? AppColors.warning : AppColors.matcha,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            over
                ? 'Sudah melewati batas $_limitMinutes menit.'
                : 'Batas harian $_limitMinutes menit.',
            style: TextStyle(
              color: over ? AppColors.warning : AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
          const Divider(height: 26, color: AppColors.borderSoft),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pengingat istirahat',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch.adaptive(
                value: _reminderOn,
                activeColor: AppColors.matchaDeep,
                onChanged: (v) {
                  setState(() => _reminderOn = v);
                  WellbeingService.setReminderEnabled(v);
                },
              ),
            ],
          ),
          if (_reminderOn) ...[
            Text(
              'Ingatkan aku setelah $_limitMinutes menit per hari',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            Slider(
              value: _limitMinutes.toDouble(),
              min: 15,
              max: 180,
              divisions: 11,
              label: '$_limitMinutes menit',
              activeColor: AppColors.matchaDeep,
              onChanged: (v) => setState(() => _limitMinutes = v.round()),
              onChangeEnd: (v) =>
                  WellbeingService.setLimitMinutes(v.round()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linkTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.matchaSoft,
          child: Icon(icon, color: AppColors.matchaDeep, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.matchaDeep, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hotlineTile(String title, String number, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.errorSoft,
          child: Icon(Icons.phone_in_talk_rounded,
              color: AppColors.error, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: TextButton(
          onPressed: () => _copyNumber(number),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}