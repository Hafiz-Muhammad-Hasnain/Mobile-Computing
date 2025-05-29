import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class UpdateEmailScreen extends StatefulWidget {
  const UpdateEmailScreen({super.key});

  @override
  State<UpdateEmailScreen> createState() => _UpdateEmailScreenState();
}

class _UpdateEmailScreenState extends State<UpdateEmailScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  bool showPasswordField = false;

  void _showSnackBar(String message, {Color color = Colors.red}) {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _updateEmail() async {
    final user = _auth.currentUser;
    final newEmail = emailController.text.trim();
    final password = passwordController.text;

    if (newEmail.isEmpty) {
      _showSnackBar('Please enter a new email.');
      return;
    }
    if (user == null) {
      _showSnackBar('No user found.');
      return;
    }

    setState(() => isLoading = true);

    try {
      if (showPasswordField) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      await user.updateEmail(newEmail);
      await user.sendEmailVerification();
      await user.reload();

      _showSnackBar(
        'Email updated successfully. Please verify your new email.',
        color: Colors.green,
      );

      emailController.clear();
      passwordController.clear();
      setState(() => showPasswordField = false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        setState(() => showPasswordField = true);
        _showSnackBar('Please enter your current password to confirm.');
      } else if (e.code == 'email-already-in-use') {
        _showSnackBar('This email is already in use.');
      } else if (e.code == 'invalid-email') {
        _showSnackBar('Invalid email format.');
      } else if (e.code == 'wrong-password') {
        _showSnackBar('Incorrect password.');
      } else {
        _showSnackBar('Error: ${e.message}');
      }
    } catch (e) {
      _showSnackBar('Something went wrong. Try again.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Colors.deepPurple;
    const lightPurple = Color(0xFFF3E8FF);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: lightPurple,
        appBar: AppBar(
          backgroundColor: themeColor,
          title: const Text(
            'Update Email',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'New Email',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.email, color: themeColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: themeColor),
                      ),
                    ),
                  ),
                  if (showPasswordField) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.lock, color: themeColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: themeColor),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: _updateEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          showPasswordField ? 'Confirm Update' : 'Update Email',
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
