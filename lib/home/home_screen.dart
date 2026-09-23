import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bumble/models/profile_model.dart';
import 'package:bumble/widgets/profile_card_widget.dart';

// Fallback jika instansiasi 'supabase' dari service belum ada
final _supabaseClient = Supabase.instance.client;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProfileModel> dailyBrew = [];
  bool isLoading = true;
  final int dailyLimit = 5;

  @override
  void initState() {
    super.initState();
    fetchDailyBrew();
  }

  Future<void> fetchDailyBrew() async {
    setState(() => isLoading = true);
    try {
      final myId = _supabaseClient.auth.currentUser!.id;

      final swiped = await _supabaseClient
          .from('swipes')
          .select('swiped_id')
          .eq('swiper_id', myId);

      // Perbaikan tipe data untuk mencegah casting error
      final swipedIds = (swiped as List)
          .map((e) => e['swiped_id'].toString())
          .toList();

      var query = _supabaseClient.from('profiles').select().neq('id', myId);

      if (swipedIds.isNotEmpty) {
        query = query.not('id', 'in', swipedIds);
      }

      final result = await query.limit(dailyLimit);

      if (mounted) {
        setState(() {
          dailyBrew = (result as List)
              .map((e) => ProfileModel.fromMap(e))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      Get.snackbar(
        'Error',
        'Failed to load matches',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> handleSwipe(ProfileModel profile, String action) async {
    try {
      final myId = _supabaseClient.auth.currentUser!.id;

      await _supabaseClient.from('swipes').upsert({
        'swiper_id': myId,
        'swiped_id': profile.id,
        'action': action,
      });

      // 2. Jika aksi adalah 'like', cek apakah ada Mutual Like
      if (action == 'like') {
        final checkMatchList = await _supabaseClient
            .from('swipes')
            .select()
            .eq('swiper_id', profile.id)
            .eq('swiped_id', myId)
            .eq('action', 'like')
            .limit(1);

        if (checkMatchList.isNotEmpty) {
          try {
            await _supabaseClient.from('matches').insert({
              'user1_id': myId,
              'user2_id': profile.id,
            });
          } catch (insertError) {
            debugPrint('Match mungkin sudah dibuat oleh Trigger: $insertError');
          }

          Get.snackbar(
            'It\'s a Match!',
            'Kamu dan ${profile.name} saling menyukai!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.greenAccent,
            colorText: Colors.black87,
          );
        } else {
          Get.snackbar(
            'Liked',
            profile.name,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
      
      if (mounted) {
        setState(() {
          dailyBrew.removeWhere((p) => p.id == profile.id);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Matcha",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDailyBrew,
              child: dailyBrew.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 150),
                        Center(
                          child: Text(
                            "No more Daily Brew today \nCome back tomorrow!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Today's Daily Brew  (${dailyBrew.length} left)",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: dailyBrew.length,
                            itemBuilder: (context, index) {
                              final profile = dailyBrew[index];
                              return Container(
                                height: 450,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ProfileCardWidget(
                                  profile: profile,
                                  onLike: () => handleSwipe(profile, 'like'),
                                  onPass: () => handleSwipe(profile, 'pass'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}
