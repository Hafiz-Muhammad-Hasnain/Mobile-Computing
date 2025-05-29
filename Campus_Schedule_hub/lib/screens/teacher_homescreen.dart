import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_schedule_hub/screens/teachers_timetablescreen.dart';
import 'package:campus_schedule_hub/screens/change_password_screen.dart';
import 'package:campus_schedule_hub/screens/feedback_screen.dart';
import 'package:campus_schedule_hub/screens/signup_screen.dart';
import 'package:animate_do/animate_do.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> allTeachers = [];
  List<String> filteredTeachers = [];
  String? selectedTeacher;
  Map<String, dynamic>? userData;

  final Color lightPurple = const Color(0xFFF3E9FF);
  final Color deepPurple = Colors.deepPurple;

  bool firstLoadAnimated = false;
  bool isFiltering = false;
  String lastQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    fetchTeachers();
    fetchUserData();
    // Animation trigger only once after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          firstLoadAnimated = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {}

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final newFiltered =
        allTeachers
            .where((name) => name.toLowerCase().contains(query))
            .toList();

    setState(() {
      filteredTeachers = newFiltered;
      selectedTeacher = null;
      isFiltering = query.isNotEmpty;
      lastQuery = query;
    });
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      setState(() {
        userData = snapshot.data();
      });
    }
  }

  // Fetch unique teacher names from timetable_data
  Future<void> fetchTeachers() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('timetable_data').get();

      // Get all unique instructor names (ignore null/empty)
      final Set<String> fetchedTeachers =
          querySnapshot.docs
              .map((doc) => (doc['instructor'] ?? '').toString().trim())
              .where((name) => name.isNotEmpty)
              .toSet();

      final List<String> teacherList = fetchedTeachers.toList()..sort();

      if (mounted) {
        setState(() {
          allTeachers = teacherList;
          filteredTeachers = teacherList;
          // Animation only on first load, not on every fetch
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teachers: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _navigateToTeacherTimetable(String teacherName) async {
    setState(() {
      selectedTeacher = teacherName;
    });

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => FadeInRight(
              duration: const Duration(milliseconds: 400),
              child: TeachersTimetableScreen(teacherName: teacherName),
            ),
        transitionsBuilder: (_, __, ___, child) => child,
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Widget screen,
    required int index,
  }) {
    // Animate each drawer item with a little delay for a nice effect
    return FadeInLeft(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: 60 * index),
      child: ListTile(
        leading: Icon(icon, color: deepPurple),
        title: Text(title),
        onTap: () {
          Navigator.pop(context); // Close drawer first
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) => FadeInRight(
                    duration: const Duration(milliseconds: 400),
                    child: screen,
                  ),
              transitionsBuilder: (_, __, ___, child) => child,
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => FadeInLeft(
              duration: const Duration(milliseconds: 400),
              child: const SignupScreen(),
            ),
        transitionsBuilder: (_, __, ___, child) => child,
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: deepPurple,
        title: const Text(
          'CAMPUS SCHEDULE HUB',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: false,
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
                child: Icon(Icons.person, color: deepPurple),
              ),
              decoration: BoxDecoration(color: deepPurple),
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
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 120),
              child: ListTile(
                leading: Icon(Icons.logout, color: deepPurple),
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
                    await _logout();
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightPurple.withOpacity(0.8),
              lightPurple.withOpacity(0.4),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: deepPurple, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TEACHERS',
                            style: TextStyle(
                              fontSize: 14,
                              color: deepPurple.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Timetable',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search teacher name',
                      prefixIcon: Icon(Icons.search_rounded, color: deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Teachers List
                if (allTeachers.isEmpty)
                  const SizedBox.shrink()
                else if (filteredTeachers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No teachers found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    key: const ValueKey('teacher-list'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTeachers.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final teacher = filteredTeachers[index];
                      final isSelected = teacher == selectedTeacher;

                      if (isFiltering) {
                        // Fade-in + zoom-in animation for filter
                        return _FadeZoomTeacherCard(
                          key: ValueKey('filter-$teacher'),
                          index: index,
                          teacher: teacher,
                          isSelected: isSelected,
                          deepPurple: deepPurple,
                          onTap: () => _navigateToTeacherTimetable(teacher),
                          onTapDown: () {
                            setState(() {
                              selectedTeacher = teacher;
                            });
                          },
                        );
                      } else {
                        // Slide from left animation for first load (only once)
                        return firstLoadAnimated
                            ? _SlideFromLeftTeacherCard(
                              key: ValueKey('firstload-$teacher'),
                              index: index,
                              teacher: teacher,
                              isSelected: isSelected,
                              deepPurple: deepPurple,
                              onTap: () => _navigateToTeacherTimetable(teacher),
                              onTapDown: () {
                                setState(() {
                                  selectedTeacher = teacher;
                                });
                              },
                              animate: true,
                            )
                            : _SlideFromLeftTeacherCard(
                              key: ValueKey('firstload-$teacher'),
                              index: index,
                              teacher: teacher,
                              isSelected: isSelected,
                              deepPurple: deepPurple,
                              onTap: () => _navigateToTeacherTimetable(teacher),
                              onTapDown: () {
                                setState(() {
                                  selectedTeacher = teacher;
                                });
                              },
                              animate: false,
                            );
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Slide from left animated card widget for teacher list (first load)
class _SlideFromLeftTeacherCard extends StatefulWidget {
  final int index;
  final String teacher;
  final bool isSelected;
  final Color deepPurple;
  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final bool animate;

  const _SlideFromLeftTeacherCard({
    super.key,
    required this.index,
    required this.teacher,
    required this.isSelected,
    required this.deepPurple,
    required this.onTap,
    required this.onTapDown,
    required this.animate,
  });

  @override
  State<_SlideFromLeftTeacherCard> createState() =>
      _SlideFromLeftTeacherCardState();
}

class _SlideFromLeftTeacherCardState extends State<_SlideFromLeftTeacherCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(-0.7, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.animate) {
      Future.delayed(Duration(milliseconds: 10 * widget.index), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side:
                widget.isSelected
                    ? BorderSide(color: widget.deepPurple, width: 2)
                    : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onTap,
            onTapDown: (_) => widget.onTapDown(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: widget.deepPurple.withOpacity(0.1),
                  child: Icon(Icons.person, color: widget.deepPurple),
                ),
                title: Text(
                  widget.teacher,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color:
                        widget.isSelected ? widget.deepPurple : Colors.black87,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: widget.isSelected ? widget.deepPurple : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Fade-in + zoom-in animated card widget for filter/search
class _FadeZoomTeacherCard extends StatefulWidget {
  final int index;
  final String teacher;
  final bool isSelected;
  final Color deepPurple;
  final VoidCallback onTap;
  final VoidCallback onTapDown;

  const _FadeZoomTeacherCard({
    super.key,
    required this.index,
    required this.teacher,
    required this.isSelected,
    required this.deepPurple,
    required this.onTap,
    required this.onTapDown,
  });

  @override
  State<_FadeZoomTeacherCard> createState() => _FadeZoomTeacherCardState();
}

class _FadeZoomTeacherCardState extends State<_FadeZoomTeacherCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = Tween<double>(
      begin: 0.95,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    Future.delayed(Duration(milliseconds: 10 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side:
                widget.isSelected
                    ? BorderSide(color: widget.deepPurple, width: 2)
                    : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onTap,
            onTapDown: (_) => widget.onTapDown(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: widget.deepPurple.withOpacity(0.1),
                  child: Icon(Icons.person, color: widget.deepPurple),
                ),
                title: Text(
                  widget.teacher,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color:
                        widget.isSelected ? widget.deepPurple : Colors.black87,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: widget.isSelected ? widget.deepPurple : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
