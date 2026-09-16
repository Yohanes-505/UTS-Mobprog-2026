import 'package:bumble/constants/app_colors.dart';
import 'package:bumble/home/home_screen.dart';
import 'package:bumble/profile/profile_tab_screen.dart';
import 'package:flutter/material.dart';

/// Node flowchart: "Home (Bottom Navigation)".
///
/// CATATAN TIM: node ini milik Kenzie. File ini sengaja dibuat minimal
/// supaya tab Profile punya tempat untuk menempel. Kalau Kenzie sudah
/// punya shell sendiri, cukup tambahkan `ProfileTabScreen()` sebagai
/// tab ketiga di shell miliknya dan file ini boleh dihapus.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // Tab 2 (Match & Chat) masih placeholder — dikerjakan anggota tim lain.
  final List<Widget> _tabs = const [
    HomeScreen(),
    _ComingSoonTab(label: 'Match & Chat'),
    ProfileTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: AppColors.primary.withValues(alpha: 0.35),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Swipe',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Match',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  final String label;
  const _ComingSoonTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(
          '$label sedang dikerjakan.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}