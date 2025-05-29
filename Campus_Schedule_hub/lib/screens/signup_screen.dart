import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'teacher_homescreen.dart';
import 'package:animate_do/animate_do.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final themeColor = Colors.deepPurple;
  final backgroundColor = const Color(0xFFF3E9FF);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please enter your full name, email, and password.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('authorized_users')
              .where('email', isEqualTo: email)
              .get();

      if (snapshot.docs.isEmpty) {
        _showErrorSnackBar(
          'Not an authorized user. Please contact IT support.',
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
        email,
      );
      if (methods.isNotEmpty) {
        _showErrorSnackBar('Email already registered. Please login.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final uid = userCredential.user!.uid;

      final userDoc = snapshot.docs.first;
      final role = userDoc['role'];

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'createdAt': Timestamp.now(),
      });

      if (context.mounted) {
        if (role == 'student') {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder:
                  (_, __, ___) => FadeInRight(
                    duration: const Duration(milliseconds: 400),
                    child: const HomeScreen(),
                  ),
              transitionsBuilder: (_, animation, __, child) => child,
              settings: const RouteSettings(name: '/home'),
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
              transitionsBuilder: (_, animation, __, child) => child,
              settings: const RouteSettings(name: '/teacher_home'),
            ),
          );
        } else {
          _showErrorSnackBar('Unknown role. Please contact IT support.');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already in use.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operation not allowed. Contact IT support.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Use a stronger password.';
          break;
        case 'network-request-failed':
          errorMessage = 'No internet connection.';
          break;
        default:
          errorMessage = e.message ?? 'Signup failed. Please try again.';
      }
      _showErrorSnackBar(errorMessage);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Something went wrong. Please try again.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder:
            (_, __, ___) => FadeInRight(
              duration: const Duration(milliseconds: 400),
              child: const LoginScreen(),
            ),
        transitionsBuilder: (_, animation, __, child) => child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
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
                        width: 110,
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeIn(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  'Create Your Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 80),
                child: TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  decoration: _buildInputDecoration('Full Name', Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 160),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  decoration: _buildInputDecoration(
                    'Email Address',
                    Icons.email,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 240),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  decoration: _buildInputDecoration(
                    'Password',
                    Icons.lock,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: themeColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Signup Button
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 320),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    splashFactory: NoSplash.splashFactory,
                    shadowColor: Colors.transparent,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                ),
              ),
              const SizedBox(height: 16),

              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 400),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: _navigateToLogin,
                      child: Text('Login', style: TextStyle(color: themeColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: themeColor),
      labelText: label,
      labelStyle: TextStyle(color: themeColor),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: themeColor),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: themeColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
