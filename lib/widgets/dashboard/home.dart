// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizcraft/models/course.dart';
import 'package:quizcraft/services/provider_model.dart';
import 'package:quizcraft/widgets/course/home.dart';
import 'package:quizcraft/widgets/dashboard/addcourse.dart';
import 'package:quizcraft/widgets/profile/profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- Local UI State Variables ---
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isAddingCourse = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  void _startSearch() {
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchQuery = '';
    });
  }


  Future<void> _addCourse(name, code) async {
    setState(() => _isAddingCourse = true);
    try {
      await context.read<AppProvider>().addCourse(name, code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" added successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add course: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingCourse = false);
      }
    }
  }

  String? get dp => FirebaseAuth.instance.currentUser!.photoURL;

  Future<void> _deleteCourse(Course course) async {
    try {
      await context.read<AppProvider>().deleteCourse(course.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${course.courseName}" deleted successfully.')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete course: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(Course course) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Course'),
          content: Text(
            'Are you sure you want to delete "${course.courseName}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteCourse(course);
              },
            ),
          ],
        );
      },
    );
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildCourseListBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search courses...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: kTextLightColor),
              ),
              style: const TextStyle(color: kTextColor, fontSize: 18),
            )
          : const Text(
              'My Courses',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
      actions: _isSearching
          ? [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _stopSearch,
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _startSearch,
              ),
              Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  child: CircleAvatar(
                    backgroundColor: kBackgroundColor,
                    backgroundImage: dp != null ? NetworkImage(dp!) : null,
                    child: dp != null
                        ? null
                        : Icon(Icons.person, size: 25, color: kTextLightColor),
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                ),
              ),
            ],
    );
  }

  Widget _buildCourseListBody() {
    return FutureBuilder<List<Course>>(
      future: Provider.of<AppProvider>(context, listen: false).getCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No courses found.\nTap "Add Course" to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: kTextLightColor),
            ),
          );
        }

        final courses = snapshot.data!;
        final filteredCourses = courses.where((course) {
          final query = _searchQuery.toLowerCase();
          final nameMatch = course.courseName.toLowerCase().contains(query);
          final codeMatch =
              course.courseCode?.toLowerCase().contains(query) ?? false;
          return nameMatch || codeMatch;
        }).toList();

        if (filteredCourses.isEmpty && _searchQuery.isNotEmpty) {
          return Center(
            child: Text(
              'No courses match "$_searchQuery".',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: kTextLightColor),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredCourses.length,
          itemBuilder: (context, index) {
            final course = filteredCourses[index];
            return _CourseCard(
              course: course,
              onDelete: () => _showDeleteConfirmation(course),
            );
          },
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _isAddingCourse
          ? null
          : () => showAddCourseModal(context: context, onSubmit: _addCourse),
      label: Text(_isAddingCourse ? 'Adding...' : 'Add Course'),
      icon: _isAddingCourse
          ? Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: 8),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : const Icon(Icons.add),
    );
  }
}

// --- NEW REUSABLE COURSE CARD WIDGET ---

class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onDelete;

  const _CourseCard({required this.course, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseScreen(course: course),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Main content area ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (course.courseCode != null)
                          Chip(
                            label: Text(course.courseCode!),
                            backgroundColor: kPrimaryColor.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            labelStyle: const TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          course.courseName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- Popup Menu Button for Actions ---
                  SizedBox(
                    width: 40,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // --- Stats area ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.article_outlined,
                    '${course.numberOfMaterials} Materials',
                  ),
                  _buildStatItem(
                    Icons.quiz_outlined,
                    '${course.numberOfQuizzes} Quizzes',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Color(0xFF78249d)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
