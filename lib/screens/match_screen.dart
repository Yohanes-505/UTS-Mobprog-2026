import 'package:bumble/constants/app_colors.dart';
import 'package:bumble/models/profile_model.dart';
import 'package:bumble/services/match_chat_service.dart';
import 'package:bumble/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MatchChatScreen extends StatefulWidget {
  const MatchChatScreen({super.key});

  @override
  State<MatchChatScreen> createState() => _MatchChatScreenState();
}

class _MatchChatScreenState extends State<MatchChatScreen> {
  final MatchChatService _service = const MatchChatService();

  late Future<List<ProfileModel>> _matchesFuture;
  late Future<List<Map<String, dynamic>>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _matchesFuture = _service.getMyMatches();
    _conversationsFuture = _service.getConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match & Chat', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadData();
          });
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // 1. bagian dari new matches
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Match Baru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryDeep),
              ),
            ),
            SizedBox(
              height: 100,
              child: FutureBuilder<List<ProfileModel>>(
                future: _matchesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Belum ada match baru.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    );
                  }

                  final matches = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final profile = matches[index];
                      return GestureDetector(
                        onTap: () => Get.to(() => ChatScreen(matchProfile: profile)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundImage: profile.photoUrl != null
                                    ? NetworkImage(profile.photoUrl!)
                                    : null,
                                child: profile.photoUrl == null ? const Icon(Icons.person) : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(thickness: 1, color: Colors.black12),

            // bagian chatnya
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Pesan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _conversationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('Belum ada percakapan aktif.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                }

                final chats = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final ProfileModel profile = chat['profile'];
                    
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 28, 
                        backgroundImage: profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
                        child: profile.photoUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(profile.name),
                      subtitle: Text(
                        chat['message'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: chat['message'] == 'Mulai percakapan baru!' ? AppColors.primaryDeep : AppColors.textSecondary,
                        ),
                      ),
                      onTap: () {
                        // Navigasi ke ruang chat personal
                        Get.to(() => ChatScreen(matchProfile: profile))?.then((_) {
                           // Refresh data ketika kembali dari chat room
                           setState(() => _loadData());
                        });
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}