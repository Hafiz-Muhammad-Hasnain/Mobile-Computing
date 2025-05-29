import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'teacher_homescreen.dart';
import 'package:animate_do/animate_do.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _navigateBasedOnAuth();
  }

  Future<void> _navigateBasedOnAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // For splash effect

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is logged in, check role from Firestore
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        final data = doc.data();
        final role = data?['role'];
        if (!mounted) return;
        if (role == 'student') {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder:
                  (_, __, ___) => FadeInRight(
                    duration: const Duration(milliseconds: 400),
                    child: const HomeScreen(),
                  ),
              transitionsBuilder: (_, animation, __, child) {
                return child;
              },
            ),
          );
        } else if (role == 'teacher') {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder:
                  (_, __, ___) => FadeInRight(
                    duration: const Duration(milliseconds: 400),
                    child: const TeacherHomeScreen(),
                  ),
              transitionsBuilder: (_, animation, __, child) {
                return child;
              },
            ),
          );
        } else {
          // Unknown role, go to signup
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder:
                  (_, __, ___) => FadeInRight(
                    duration: const Duration(milliseconds: 400),
                    child: const SignupScreen(),
                  ),
              transitionsBuilder: (_, animation, __, child) {
                return child;
              },
            ),
          );
        }
      } catch (e) {
        // Error fetching user data, go to signup
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder:
                  (_, __, ___) => FadeInRight(
                    duration: const Duration(milliseconds: 400),
                    child: const SignupScreen(),
                  ),
              transitionsBuilder: (_, animation, __, child) {
                return child;
              },
            ),
          );
        }
      }
    } else {
      // Not logged in, go to signup
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder:
                (_, __, ___) => FadeInRight(
                  duration: const Duration(milliseconds: 400),
                  child: const SignupScreen(),
                ),
            transitionsBuilder: (_, animation, __, child) {
              return child;
            },
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double logoSize = size.width * 0.45;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E9FF), // Soft lilac background
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo5.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Campus Schedule Hub',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 25),
              const SpinKitFadingCircle(color: Colors.deepPurple, size: 40.0),
            ],
          ),
        ),
      ),
    );
  }
}
