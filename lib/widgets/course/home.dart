// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quizcraft/models/lecture_materials.dart';
import 'package:quizcraft/models/quiz_generation.dart';
import 'package:quizcraft/widgets/course/cards.dart';
import 'package:quizcraft/widgets/course/generation_modal.dart';
import 'package:quizcraft/widgets/course/generations/generations_page.dart';
import 'package:quizcraft/widgets/course/lecture_materials.dart';
import 'package:quizcraft/models/course.dart';
import 'package:quizcraft/services/provider_model.dart';

// Helper function to convert file size (if not available elsewhere)
String convertFileSize(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  var i = (bytes / 1024).floor(); // Using floor to ensure i is an int for index
  if (i == 0) return "$bytes ${suffixes[i]}"; // if less than 1KB
  i =
      (BigInt.from(bytes).bitLength - 1) ~/
      10; // More robust way to get correct magnitude
  return '${(bytes / (1 << (i * 10))).toStringAsFixed(decimals)} ${suffixes[i]}';
}

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key, required this.course});
  final Course course;

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  bool _isFabLoading = false; // For FAB loading state

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          // AppBar displaying the course name and lecture materials preview
          appBar: PreferredSize(
            preferredSize: Size(
              double.infinity,
              (kToolbarHeight * 2.3) +
                  kToolbarHeight, // Standard AppBar + Materials section
            ),
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    widget.course.courseName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  elevation: 0, // Remove shadow if container below has it
                ),
                // Lecture Materials Section
                Container(
                  width: double.infinity,
                  height: kToolbarHeight * 2.3, // Fixed height for this section
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                  ), // Padding for the ListView
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: FutureBuilder<List<LectureMaterial>>(
                    future: appProvider.getMaterials(widget.course.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              'Error loading materials: ${snapshot.error}',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      } else if (snapshot.hasData) {
                        final materials = snapshot.data!;

                        final displayCount = materials.length > 3
                            ? 3
                            : materials.length;
                        // Total items: displayed materials + "View All" card
                        final itemCount = displayCount + 1;

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            if (index == displayCount) {
                              // Last item is "View All"
                              return SizedBox(
                                width: 120, // Consistent width for cards
                                child: _ViewAllMaterialsCard(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LectureMaerialscreen(
                                          courseid: widget.course.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                            return SizedBox(
                              width: 120, // Consistent width for cards
                              child: FileCard(material: materials[index]),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              SizedBox(width: 10),
                        );
                      } else {
                        // Fallback for unexpected state
                        return Center(
                          child: Text(
                            'No materials available.',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generated Quizzes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                FutureBuilder<List<QuizGeneration>>(
                  future: appProvider.getQuizzes(widget.course.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            // More structured error display
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade300,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Failed to Load Quizzes',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: Colors.red.shade700),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      final quizzes = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: quizzes.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            // Add padding around QuizCard if needed
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => GenerationsPage(
                                      courseid: widget.course.id,
                                      generationDetails: quizzes[index],
                                    ),
                                  ),
                                );
                              },
                              child: QuizCard(metadata: quizzes[index]),
                            ),
                          );
                        },
                      );
                    } else {
                      // Empty state for quizzes
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 40.0,
                            horizontal: 16.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No Quizzes Yet!',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(color: Colors.grey.shade700),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Tap the '+' button below to generate your first quiz from the course materials.",
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _isFabLoading
                ? null
                : () async {
                    List<LectureMaterial> courseMaterials;
                    try {
                      courseMaterials = await Provider.of<AppProvider>(
                        context,
                        listen: false,
                      ).getMaterials(widget.course.id);
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isFabLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error fetching materials: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    if (!mounted) return;
                    showQuizGenerationModal(
                      context: context,
                      courseId: widget.course.id,
                      onSubmit: (config) async {
                        if (mounted) {
                          setState(() {
                            _isFabLoading = true;
                          });
                        }

                        try {
                          final generationResult =
                              await Provider.of<AppProvider>(
                                context,
                                listen: false,
                              ).generateQuiz(config);

                          if (!mounted) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GenerationsPage(
                                courseid: widget.course.id,
                                generationDetails: generationResult,
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to start quiz generation: $error',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isFabLoading = false;
                            });
                          }
                        }
                      },
                      coursematerials: courseMaterials,
                    );
                  },
            icon: _isFabLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.add),
            label: _isFabLoading
                ? const Text("PROCESSING...")
                : const Text("New Quiz"),
            backgroundColor: _isFabLoading
                ? Colors.grey.shade400
                : Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }
}

// Card for displaying a single lecture material file
class FileCard extends StatelessWidget {
  const FileCard({super.key, required this.material});
  final LectureMaterial material;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 32,
              color: Colors.black,
            ), // Icon color relative to card
            const SizedBox(height: 8),
            Text(
              material.fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${DateFormat('MMM dd, yy').format(material.uploadedAt.toDate())}\n${convertFileSize(int.parse(material.fileSize))}",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Card for "View All" navigation for lecture materials
class _ViewAllMaterialsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewAllMaterialsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2.0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.collections_bookmark_outlined,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 8),
              Text(
                'View All',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Materials",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
