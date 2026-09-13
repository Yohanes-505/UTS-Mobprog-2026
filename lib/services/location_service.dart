import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Hasil pengambilan lokasi: selalu mengembalikan objek, tidak melempar
/// exception, supaya UI gampang menampilkan pesan yang tepat.
class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? errorMessage;

  const LocationResult._({
    this.latitude,
    this.longitude,
    this.city,
    this.errorMessage,
  });

  const LocationResult.success({
    required double lat,
    required double lng,
    String? city,
  }) : this._(latitude: lat, longitude: lng, city: city);

  const LocationResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => errorMessage == null;
}

/// Semua urusan GPS ada di sini (node "Lokasi GPS" & "radius GPS").
class LocationService {
  const LocationService();

  /// Minta izin lokasi + ambil koordinat saat ini + reverse geocode ke nama kota.
  Future<LocationResult> getCurrentLocation({bool resolveCity = true}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult.failure(
          'Layanan lokasi mati. Nyalakan GPS di pengaturan perangkat.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(
          'Izin lokasi ditolak. Kami butuh lokasi untuk mencari orang di sekitarmu.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(
          'Izin lokasi diblokir permanen. Buka pengaturan aplikasi untuk mengizinkannya.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      String? city;
      if (resolveCity) {
        city = await _resolveCity(position.latitude, position.longitude);
      }

      return LocationResult.success(
        lat: position.latitude,
        lng: position.longitude,
        city: city,
      );
    } catch (e) {
      debugPrint('LocationService error: $e');
      return const LocationResult.failure(
        'Gagal mengambil lokasi. Coba lagi beberapa saat.',
      );
    }
  }

  /// Buka halaman pengaturan aplikasi (untuk kasus deniedForever).
  Future<void> openSettings() => Geolocator.openAppSettings();

  /// Jarak dua titik dalam kilometer. Dipakai kalau mau hitung di sisi client.
  double distanceInKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    final meters = Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    return meters / 1000;
  }

  Future<String?> _resolveCity(double lat, double lng) async {
    // Reverse geocoding tidak tersedia di Flutter Web.
    if (kIsWeb) return null;
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final candidates = [
        p.subAdministrativeArea,
        p.locality,
        p.administrativeArea,
      ];
      for (final c in candidates) {
        if (c != null && c.trim().isNotEmpty) return c.trim();
      }
      return null;
    } catch (e) {
      debugPrint('Reverse geocode gagal: $e');
      return null;
    }
  }
}