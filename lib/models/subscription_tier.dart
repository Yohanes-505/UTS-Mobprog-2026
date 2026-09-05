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
      id: 'basic',
      name: 'Basic',
      priceMonthly: 0,
      features: [
        'Swipe terbatas per hari',
        'Chat dengan match',
        'Profil dasar',
      ],
    ),
    SubscriptionTier(
      id: 'plus',
      name: 'Plus',
      priceMonthly: 29000,
      features: [
        'Unlimited swipe',
        'Lihat siapa yang like kamu',
        'Chat dengan match',
      ],
      isPopular: true,
    ),
    SubscriptionTier(
      id: 'premium',
      name: 'Premium',
      priceMonthly: 59000,
      features: [
        'Semua fitur Plus',
        'Boost profil (lebih sering muncul)',
        'Rewind swipe (batalkan swipe terakhir)',
      ],
    ),
  ];
}