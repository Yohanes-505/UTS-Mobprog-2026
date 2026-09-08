class SubscriptionTier {
  final String id;  
  final String name;
  final int priceMonthly; 
  final List<String> features;
  final bool isPopular;

  const SubscriptionTier({
    required this.id,
    required this.name,
    required this.priceMonthly,
    required this.features,
    this.isPopular = false,
  });

  String get formattedPrice {
    if (priceMonthly == 0) return 'Gratis';
    final formatted = priceMonthly.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted/bulan';
  }

   static const List<SubscriptionTier> all = [
    SubscriptionTier(
      id: 'free',
      name: 'Free',
      priceMonthly: 0,
      features: [
        'Swipe terbatas (~20 like/hari)',
        'Like & Match',
        'Ganti lokasi manual',
      ],
    ),
    SubscriptionTier(
      id: 'premium',
      name: 'Premium',
      priceMonthly: 29000,
      features: [
        'Unlimited swipe',
        'Lihat siapa yang like kamu',
        'Boost profil',
        'Rewind swipe',
      ],
      isPopular: true,
    ),
    SubscriptionTier(
      id: 'vip',
      name: 'VIP',
      priceMonthly: 59000,
      features: [
        'Semua fitur Premium',
        'Lihat siapa yang view profil kamu',
        'Prioritas di swipe/match',
        'Verifikasi profil (centang biru)',
      ],
    ),
  ];
}