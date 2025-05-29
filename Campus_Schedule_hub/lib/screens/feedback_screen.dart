import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController feedbackController = TextEditingController();
  bool isLoading = false;
  String? error;

  Future<void> submitFeedback() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => error = 'User not logged in.');
      return;
    }

    final message = feedbackController.text.trim();

    if (message.isEmpty) {
      setState(() => error = 'Feedback cannot be empty.');
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'email': user.email,
        'message': message,
        'timestamp': DateTime.now(),
      });

      setState(() {
        isLoading = false;
        feedbackController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Feedback submitted successfully',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Animate back navigation with FadeInLeft on previous screen if possible
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Failed to submit feedback. Try again.';
      });
    }
  }

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback', style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
            // If you want to animate the previous screen, wrap it in FadeInLeft.
          },
        ),
      ),
      body: FadeInUp(
        duration: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextField(
                controller: feedbackController,
                maxLines: 6,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Enter your feedback here...',
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: themeColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: themeColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: themeColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                    onPressed: submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text('Submit'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
