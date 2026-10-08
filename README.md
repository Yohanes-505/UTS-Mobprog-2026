# Meetcha — [Mobile Programming - Project UTS]

Meetcha adalah aplikasi dating mobile yang dikembangkan untuk memenuhi proyek Mobile Programming. Meetcha membantu pengguna bertemu orang baru lewat profil, minat bersama, dan fitur swipe, dengan perhatian khusus pada keamanan dan kesejahteraan pengguna.

Project terdiri dari tiga bagian utama:

- **Aplikasi Pengguna** (Flutter) untuk menemukan, mencocokkan, dan mengobrol dengan pengguna lain
- **Backend & Database** (Supabase) untuk autentikasi, data profil, match, chat, dan dompet
- **Notifikasi & Pembayaran** (Firebase Cloud Messaging dan Midtrans Snap) untuk push notification serta langganan dan top up

Aplikasi dikembangkan secara kolaboratif menggunakan Git dan GitHub.

## Anggota Kelompok

| NIM | Nama |
|---|---|
| 535250054 | Yohanes Phandry |
| 535250071 | Khresnanda Putra Wirawan |
| 535250079 | Kenzie Agustin |
| 535250092 | Elfrandt Goldjer |
| 535250095 | Nicho Louis Salim |

## Fitur Utama

### Aplikasi Pengguna

- Welcome screen, Sign Up, Login, dan Lupa Password
- Auto logout setelah 7 hari tidak aktif
- Setup profil (foto, bio, minat 3–8 pilihan dari 20 kategori)
- Verifikasi wajah (face verification) dan badge terverifikasi
- Tab **Brew** (daftar rekomendasi harian) dan **Suggested** (satu profil per tampilan)
- Like dan Match dengan dialog match
- Tab **Likes** untuk melihat siapa yang menyukai kamu
- Chat antar-match (emoji, kirim gambar, status terbaca)
- Match kedaluwarsa jika belum ada pesan
- Filter preferensi (usia, jarak maksimum, gender)
- Lokasi otomatis dan ganti lokasi manual
- Edit profil dan manajemen akun yang diblokir
- Push notification dan riwayat notifikasi
- Gift Shop, inventori hadiah, dan kirim hadiah antar-pengguna
- Dompet (wallet), Top Up, dan riwayat transaksi
- Langganan Free, Premium, dan VIP
- Loading animation khas Meetcha

### Keamanan & Kesejahteraan (SDG 3)

- Mood check-in harian
- Pelacakan waktu layar dan pengingat istirahat
- Safety Center (panduan pelaporan dan nomor hotline)
- Safe Dating Tips
- Blokir dan laporkan pengguna

### Subscription

| Paket | Harga | Fitur |
|---|---|---|
| Free | Gratis | Swipe terbatas (~20 like/hari), Like & Match, ganti lokasi manual |
| Premium | Rp 29.000/bulan | Unlimited swipe, lihat siapa yang like kamu, boost profil, rewind swipe |
| VIP | Rp 59.000/bulan | Semua fitur Premium, lihat siapa yang melihat profil kamu, prioritas di swipe/match, verifikasi profil (centang biru) |

---

## Tools

- **Framework:** Flutter (Dart)
- **State Management:** GetX
- **Backend:** Supabase
- **Notifikasi:** Firebase Cloud Messaging dan Flutter Local Notifications
- **Pembayaran:** Midtrans Snap (WebView)
- **Lokasi:** Geolocator dan Geocoding
- **Verifikasi Wajah:** Google ML Kit Face Detection dan TensorFlow Lite (MobileFaceNet)
- **Penyimpanan Lokal:** Shared Preferences

## Struktur Folder

```
lib/
├── authentication/   # Welcome, login, sign up, lupa password, auth gate
├── constants/        # Warna dan opsi minat
├── controllers/      # Profile controller (GetX)
├── features/         # Gift dan wellbeing
├── home/             # Home, main shell, tampilan profil
├── models/           # Model data
├── profile/          # Setup, edit, filter, blokir, tips
├── screens/          # Chat, match, likes, notifikasi, langganan, top up
├── services/         # Layanan Supabase, notifikasi, lokasi, swipe, dll.
├── utils/            # Helper
├── verification/     # Face verification (mobile dan web)
└── widgets/          # Komponen UI reusable
```

---

## Cara Menjalankan

1. Pastikan Flutter SDK sudah terpasang.
2. Clone repository ini.
3. Jalankan `flutter pub get`.
4. Pastikan file `assets/models/mobile_face_net.tflite` tersedia.
5. Jalankan aplikasi dengan `flutter run`.

> Push notification dan verifikasi wajah hanya berjalan penuh di Android/iOS. Versi web (Chrome) hanya untuk development dan preview UI.