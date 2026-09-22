import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bumble/models/profile_model.dart';
import 'package:bumble/widgets/profile_card_widget.dart';

class HomeSwipeScreen extends StatefulWidget {
  const HomeSwipeScreen({super.key});

  @override
  State<HomeSwipeScreen> createState() => _HomeSwipeScreenState();
}

class _HomeSwipeScreenState extends State<HomeSwipeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  List<ProfileModel> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfiles() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final swipedResponse = await Supabase.instance.client
          .from('swipes')
          .select('swiped_id')
          .eq('swiper_id', currentUserId);

      final List<String> swipedIds = (swipedResponse as List)
          .map((e) => e['swiped_id'].toString())
          .toList();

      swipedIds.add(currentUserId);

      var query = Supabase.instance.client.from('profiles').select();
      
      if (swipedIds.isNotEmpty) {
        query = query.not('id', 'in', swipedIds);
      }

      final response = await query.limit(10);

      final data = List<Map<String, dynamic>>.from(response)
          .map((e) => ProfileModel.fromMap(e))
          .toList();

      if (mounted) {
        setState(() {
          _profiles = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Gagal memuat profil: $e');
    }
  }

  Future<void> _recordSwipe(String targetId, String action) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;
      
      await Supabase.instance.client.from('swipes').insert({
        'swiper_id': currentUserId,
        'swiped_id': targetId,
        'action': action,
      });
    } catch (e) {
      debugPrint('Gagal mencatat swipe: $e');
    }
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (previousIndex >= _profiles.length) return false;

    final swipedProfile = _profiles[previousIndex];

    if (direction == CardSwiperDirection.right) {
      debugPrint('Kamu menyukai: ${swipedProfile.name}');
      _recordSwipe(swipedProfile.id, 'like');
    } else if (direction == CardSwiperDirection.left) {
      debugPrint('Kamu melewati: ${swipedProfile.name}');
      _recordSwipe(swipedProfile.id, 'pass');
    }

    setState(() {
      _profiles.removeAt(previousIndex);
    });

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Matcha',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? const Center(
                  child: Text(
                    'No more Daily Brew today \nCome back tomorrow!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: CardSwiper(
                      controller: _swiperController,
                      cardsCount: _profiles.length,
                      onSwipe: _onSwipe,
                      numberOfCardsDisplayed: _profiles.length < 2
                          ? _profiles.length
                          : 2,
                      padding: const EdgeInsets.all(10),
                      cardBuilder: (context, index, percentX, percentY) {
                        return ProfileCardWidget(
                          profile: _profiles[index],
                          onLike: () {
                            _swiperController.swipeRight();
                          },
                          onPass: () {
                            _swiperController.swipeLeft();
                          },
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}