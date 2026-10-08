import 'dart:async';

import 'package:Meetcha/constants/app_colors.dart';
import 'package:Meetcha/features/wellbeing/mood_checkin_sheet.dart';
import 'package:Meetcha/features/wellbeing/wellbeing_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 1. Menawarkan check-in mood sekali sehari saat app dibuka.
/// 2. Menghitung waktu layar dan menampilkan pengingat istirahat
///    setelah melewati batas yang diatur di Safety Center.
class WellbeingGuard extends StatefulWidget {
  final Widget child;

  const WellbeingGuard({super.key, required this.child});

  @override
  State<WellbeingGuard> createState() => _WellbeingGuardState();
}

class _WellbeingGuardState extends State<WellbeingGuard>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _activeSince;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTracking();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      if (await WellbeingService.shouldPromptMoodToday() && mounted) {
        MoodCheckinSheet.show();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTracking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTracking();
    } else {
      _stopTracking();
    }
  }

  void _startTracking() {
    _activeSince ??= DateTime.now();
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  void _stopTracking() {
    _timer?.cancel();
    _timer = null;
    _flush();
    _activeSince = null;
  }

  /// Simpan durasi sejak [_activeSince], kembalikan total hari ini.
  Future<int?> _flush() async {
    final since = _activeSince;
    if (since == null) return null;

    final now = DateTime.now();
    _activeSince = now;
    final seconds = now.difference(since).inSeconds;
    if (seconds <= 0) return null;
    return WellbeingService.addSeconds(seconds);
  }

  Future<void> _tick() async {
    final total = await _flush();
    if (total == null || _dialogOpen || !mounted) return;
    if (!await WellbeingService.shouldRemind(total)) return;

    await WellbeingService.snoozeReminder(total);
    _showReminder(total);
  }

  void _showReminder(int totalSeconds) {
    _dialogOpen = true;
    final minutes = (totalSeconds / 60).round();

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Waktunya istirahat sejenak ☕',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        content: Text(
          'Kamu sudah memakai Meetcha sekitar $minutes menit hari ini. '
          'Coba regangkan badan, minum air, atau ngobrol dengan orang '
          'terdekatmu dulu.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Lanjut ${WellbeingService.snoozeMinutes} menit',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Get.back(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.matchaDeep,
            ),
            child: const Text('Oke, istirahat'),
          ),
        ],
      ),
      barrierDismissible: true,
    ).whenComplete(() => _dialogOpen = false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}



