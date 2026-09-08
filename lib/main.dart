import 'package:bumble/authentication/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/notification_service.dart';
// import 'package:bumble/profile/profile_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xwhglyvwosyptwylskmt.supabase.co',
    publishableKey: 'sb_publishable_IJ5sQ0p_YZrmMzSKS__o_Q_U61cdrQT',
  );

  await initLocalNotifications();
  
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Bumble',
      theme: ThemeData().copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}