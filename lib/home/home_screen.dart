import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bumble/services/supabase_service.dart';
import 'package:bumble/models/profile_model.dart';
import 'package:bumble/widgets/profile_card_widget.dart';

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
      final myId = supabase.auth.currentUser!.id;

      final swiped = await supabase
          .from('swipes')
          .select('swiped_id')
          .eq('swiper_id', myId);
      final swipedIds = (swiped as List).map((e) => e['swiped_id'] as String).toList();

      var query = supabase.from('profiles').select().neq('id', myId);

      if (swipedIds.isNotEmpty) {
        query = query.not('id', 'in', '(${swipedIds.join(',')})');
      }

      final result = await query.limit(dailyLimit);

      setState(() {
        dailyBrew = (result as List).map((e) => ProfileModel.fromMap(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('Error', 'Failed to load matches', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> handleSwipe(ProfileModel profile, String action) async {
    try {
      final myId = supabase.auth.currentUser!.id;
      await supabase.from('swipes').insert({
        'swiper_id': myId,
        'swiped_id': profile.id,
        'action': action,
      });

      setState(() => dailyBrew.removeWhere((p) => p.id == profile.id));

      if (action == 'like') {
        Get.snackbar('Liked', '${profile.name}', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Matcha", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
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
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: dailyBrew.length,
                            itemBuilder: (context, index) {
                              final profile = dailyBrew[index];
                              return ProfileCardWidget(
                                profile: profile,
                                onLike: () => handleSwipe(profile, 'like'),
                                onPass: () => handleSwipe(profile, 'pass'),
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