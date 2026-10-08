import 'package:Meetcha/constants/app_colors.dart';
import 'package:Meetcha/features/wellbeing/safety_center_screen.dart';
import 'package:Meetcha/features/wellbeing/wellbeing_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom sheet check-in mood harian
/// Pakai `MoodCheckinSheet.show()` hasilnya `true` kalau mood tersimpan.
class MoodCheckinSheet extends StatefulWidget {
  const MoodCheckinSheet({super.key});

  static Future<bool?> show() {
    return Get.bottomSheet<bool>(
      const MoodCheckinSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<MoodCheckinSheet> createState() => _MoodCheckinSheetState();
}

class _MoodCheckinSheetState extends State<MoodCheckinSheet> {
  final _noteController = TextEditingController();
  int? _selected;
  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final mood = _selected;
    if (mood == null || _saving) return;

    setState(() => _saving = true);
    try {
      await WellbeingService.saveMood(mood, note: _noteController.text);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
    } catch (e) {
      debugPrint('Gagal simpan mood: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      Get.snackbar(
        'Gagal menyimpan',
        'Coba lagi beberapa saat.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        backgroundColor: Colors.white,
        colorText: AppColors.textPrimary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: SafeArea(
          top: false,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: _saved ? _buildResult() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _handle() => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      );

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _handle(),
        const Text(
          'Bagaimana perasaanmu hari ini?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Check-in singkat ini hanya bisa dilihat olehmu.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: MoodOption.all.map(_moodButton).toList(),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _noteController,
          maxLength: 300,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Catatan (opsional)',
            filled: true,
            fillColor: AppColors.surfaceMuted,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _selected == null || _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.matchaDeep,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Simpan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text(
            'Lewati',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _moodButton(MoodOption option) {
    final selected = _selected == option.value;

    return GestureDetector(
      onTap: () => setState(() => _selected = option.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.matchaSoft : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.matcha : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1,
              duration: const Duration(milliseconds: 160),
              child: Text(option.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 4),
            Text(
              option.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10,
                height: 1.15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.matchaDeep : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final low = (_selected ?? 3) <= 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _handle(),
        Text(
          low ? '💚' : '✨',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 42),
        ),
        const SizedBox(height: 12),
        Text(
          low ? 'Terima kasih sudah jujur' : 'Senang mendengarnya!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          low
              ? 'Hari yang berat itu wajar. Tidak apa-apa istirahat dari '
                  'aplikasi dulu. Kalau kamu butuh teman bicara, ada layanan '
                  'bantuan di Safety Center.'
              : 'Check-in tersimpan. Jaga terus energimu, dan jangan lupa '
                  'istirahat dari layar.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        if (low)
          FilledButton.icon(
            onPressed: () {
              Get.back(result: true);
              Get.to(() => const SafetyCenterScreen());
            },
            icon: const Icon(Icons.support_rounded, size: 19),
            label: const Text('Buka Safety Center'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.matchaDeep,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text(
            'Tutup',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}