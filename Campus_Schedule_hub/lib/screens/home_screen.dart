import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:campus_schedule_hub/screens/student_timetable_screen.dart';
import 'package:campus_schedule_hub/screens/change_password_screen.dart';
import 'package:campus_schedule_hub/screens/feedback_screen.dart';
import 'package:campus_schedule_hub/screens/signup_screen.dart';
import 'package:animate_do/animate_do.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final themeColor = Colors.deepPurple;
  final backgroundColor = const Color(0xFFF3E9FF);

  String? selectedSemester;
  String? selectedProgram;
  String? selectedSection;

  List<String> semesters = [];
  List<String> programs = [];
  List<String> sections = [];

  Map<String, dynamic>? userData;

  static const Duration animDuration = Duration(milliseconds: 350);

  // For caching all timetable_data locally
  List<Map<String, dynamic>> allTimetableData = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([fetchUserData(), fetchAllTimetableData()]);
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (mounted) {
        setState(() {
          userData = snapshot.data();
        });
      }
    }
  }

  Future<void> fetchAllTimetableData() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('timetable_data').get();
    allTimetableData =
        snapshot.docs
            .map((doc) => Map<String, dynamic>.from(doc.data()))
            .toList();

    // Populate unique semesters
    semesters =
        allTimetableData.map((e) => e['semester'].toString()).toSet().toList()
          ..sort();

    setState(() {
      // Reset dropdowns
      selectedSemester = null;
      selectedProgram = null;
      selectedSection = null;
      programs = [];
      sections = [];
    });
  }

  void fetchPrograms(String semester) {
    setState(() {
      selectedProgram = null;
      selectedSection = null;
      programs = [];
      sections = [];
    });

    final filtered =
        allTimetableData
            .where((e) => e['semester'].toString() == semester)
            .map((e) => e['program'].toString())
            .toSet()
            .toList()
          ..sort();

    setState(() {
      programs = filtered;
    });
  }

  void fetchSections(String semester, String program) {
    setState(() {
      selectedSection = null;
      sections = [];
    });

    final filtered =
        allTimetableData
            .where(
              (e) =>
                  e['semester'].toString() == semester &&
                  e['program'].toString() == program,
            )
            .map((e) => e['sec'].toString())
            .toSet()
            .toList()
          ..sort();

    setState(() {
      sections = filtered;
    });
  }

  Future<void> handleFinalSelection(String? section) async {
    if (selectedSemester != null &&
        selectedProgram != null &&
        section != null) {
      setState(() {
        selectedSection = section;
      });

      if (mounted) {
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => FadeInRight(
                  duration: animDuration,
                  child: StudentTimetableScreen(
                    semester: selectedSemester!,
                    program: selectedProgram!,
                    section: selectedSection!,
                  ),
                ),
            transitionDuration: animDuration,
            transitionsBuilder: (_, __, ___, child) => child,
          ),
        );

        // Reset all dropdowns when returning
        setState(() {
          selectedSemester = null;
          selectedProgram = null;
          selectedSection = null;
          programs = [];
          sections = [];
        });
      }
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Widget screen,
    required int index,
  }) {
    return FadeInLeft(
      duration: animDuration,
      delay: Duration(milliseconds: 60 * index),
      child: ListTile(
        leading: Icon(icon, color: themeColor),
        title: Text(title),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      FadeInRight(duration: animDuration, child: screen),
              transitionDuration: animDuration,
              transitionsBuilder: (_, __, ___, child) => child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text(
          'CAMPUS SCHEDULE HUB',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userData?['name'] ?? 'Loading...'),
              accountEmail: Text(userData?['email'] ?? 'Loading...'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: themeColor),
              ),
              decoration: BoxDecoration(color: themeColor),
            ),
            _buildDrawerItem(
              icon: Icons.lock,
              title: 'Change Password',
              screen: const ChangePasswordScreen(),
              index: 0,
            ),
            _buildDrawerItem(
              icon: Icons.feedback,
              title: 'Feedback',
              screen: const FeedbackScreen(),
              index: 1,
            ),
            FadeInLeft(
              duration: animDuration,
              delay: const Duration(milliseconds: 180),
              child: ListTile(
                leading: Icon(Icons.logout, color: themeColor),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  bool? confirmLogout = await showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          content: const Text(
                            'Are you sure you want to log out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                  );

                  if (confirmLogout == true) {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  FadeInRight(
                                    duration: animDuration,
                                    child: const SignupScreen(),
                                  ),
                          transitionDuration: animDuration,
                          transitionsBuilder: (_, __, ___, child) => child,
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(duration: animDuration, child: _buildLogo()),
              const SizedBox(height: 16),
              FadeIn(duration: animDuration, child: _buildTitle()),
              const SizedBox(height: 24),
              FadeInUp(duration: animDuration, child: _buildSelectionCard()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
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
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.calendar_today, color: themeColor, size: 28),
        const SizedBox(width: 10),
        Text(
          'Timetable Selection',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        border: Border.all(color: themeColor, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Column(
        children: [
          _buildDropdown(
            hint: 'Select Semester',
            value: selectedSemester,
            items: semesters,
            icon: Icons.calendar_today,
            onChanged: (value) {
              setState(() {
                selectedSemester = value;
                selectedProgram = null;
                selectedSection = null;
              });
              if (value != null) fetchPrograms(value);
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            hint: 'Select Program',
            value: selectedProgram,
            items: programs,
            icon: Icons.school,
            onChanged: (value) {
              setState(() {
                selectedProgram = value;
                selectedSection = null;
              });
              if (value != null && selectedSemester != null) {
                fetchSections(selectedSemester!, value);
              }
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            hint: 'Select Section',
            value: selectedSection,
            items: sections,
            icon: Icons.group,
            onChanged: (value) {
              if (value != null) handleFinalSelection(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withOpacity(0.5), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: themeColor),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
                items:
                    items
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              item,
                              style: TextStyle(color: themeColor),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
