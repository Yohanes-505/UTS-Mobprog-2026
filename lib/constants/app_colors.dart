import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Warna inti
  static const Color lime = Color(0xFF9BF272);
  static const Color green = Color(0xFF7ABF5A);
  static const Color ink = Color(0xFF193940);
  static const Color mist = Color(0xFFBAC8D9);

  /// Latar tombol utama, chip terpilih, slider aktif.
  static const Color primary = lime;

  /// Teks/ikon DI ATAS `primary`.
  static const Color onPrimary = ink;

  /// Hijau tua turunan — untuk ikon, teks, dan border hijau di atas putih.
  static const Color primaryDeep = Color(0xFF3F7A2A);

  /// Latar lembut bernuansa hijau (pengganti purple.shade50, dsb).
  static const Color primarySoft = Color(0xFFEFFBE7);

  /// Border tipis bernuansa hijau (pengganti purple.shade100).
  static const Color primaryBorder = Color(0xFFCFEFBC);

  static const Color background = Colors.white;
  static const Color surfaceMuted = Color(0xFFF2F5F8);

  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF5E7079);

  /// Garis pemisah & border netral.
  static const Color border = mist;

  // Warna semantik
  static const Color success = primaryDeep;
  static const Color successSoft = primarySoft;

  static const Color warning = Color(0xFFB7791F);
  static const Color warningSoft = Color(0xFFFFF4E0);
  static const Color warningBorder = Color(0xFFF5D9A8);

  static const Color error = Color(0xFFC62828);
  static const Color errorSoft = Color(0xFFFDECEC);
}