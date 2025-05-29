import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/teacher_homescreen.dart';
import 'package:animate_do/animate_do.dart'; // <-- Add this

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CampusScheduleHub());
}

class CampusScheduleHub extends StatelessWidget {
  const CampusScheduleHub({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Schedule Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: FadeIn(
        // <-- Animate splash screen entry
        duration: const Duration(milliseconds: 500),
        child: const SplashScreen(),
      ),
      routes: {
        '/home':
            (context) => FadeInRight(
              duration: const Duration(milliseconds: 400),
              child: const HomeScreen(),
            ),
        '/teacher_home':
            (context) => FadeInRight(
              duration: const Duration(milliseconds: 400),
              child: const TeacherHomeScreen(),
            ),
      },
    );
  }
}
