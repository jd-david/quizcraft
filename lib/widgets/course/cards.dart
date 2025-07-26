import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quizcraft/widgets/course/home.dart';
import 'package:quizcraft/models/course.dart';
import 'package:quizcraft/models/lecture_materials.dart';
import 'package:quizcraft/models/quiz_generation.dart';


class LectureMaterialCard extends StatefulWidget {
  const LectureMaterialCard({super.key, required this.material});
  final LectureMaterial material;

  @override
  State<LectureMaterialCard> createState() => _LectureMaterialCardState();
}

class _LectureMaterialCardState extends State<LectureMaterialCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: ListTile(
        contentPadding: EdgeInsets.only(),
        leading: Icon(
          Icons.description_outlined,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.material.fileName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              "${DateFormat('EEE, MMM dd').format(widget.material.uploadedAt.toDate())} ${convertFileSize(widget.material.fileSize)}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Course course;
  final Function(Course course) onDelete;
  const CourseCard({super.key, required this.course, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => CourseScreen(course: course)));
      },
      onDoubleTap: () {
        onDelete(course);
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.courseCode != null)
                  TextButton(
                    onPressed: null,
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Colors.grey.shade300,
                      ),
                      padding: WidgetStatePropertyAll(EdgeInsets.all(3)),
                      minimumSize: WidgetStatePropertyAll(Size(10, 20)),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(5),
                        ),
                      ),
                    ),
                    child: Text(course.courseCode!),
                  ),
                Text(
                  ' ${course.courseName}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w200,
                    color: Colors.black,
                  ),
                ),
                Center(
                  child: Row(
                    children: [
                      Row(
                        spacing: 5,
                        children: [
                          Icon(
                            CupertinoIcons.book,
                            color: Theme.of(context).primaryColor,
                          ),
                          Text('${course.numberOfMaterials} Materials'),
                        ],
                      ),
                      Row(
                        spacing: 5,
                        children: [
                          Icon(
                            CupertinoIcons.question_circle,
                            color: Theme.of(context).primaryColor,
                          ),
                          Text('${course.numberOfQuizzes} Quizzes'),
                        ],
                      ),
                    ].map((e) => Expanded(child: e)).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GradientProgressIndicator(
                    borderRadius: BorderRadius.circular(10),
                    value: course.performance ?? 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GradientProgressIndicator extends StatelessWidget {
  final double value; // target value (0.0 to 1.0)
  final double height;
  final BorderRadius borderRadius;
  final Duration duration;

  const GradientProgressIndicator({
    super.key,
    required this.value,
    this.height = 10.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.duration = const Duration(seconds: 1),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            // width: double.infinity,
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200], // Background track
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth * animatedValue,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

String convertFileSize(String bytesStr) {
  final int? bytes = int.tryParse(bytesStr);
  if (bytes == null) {
    return 'Invalid size'; // Handle non-integer input
  }

  if (bytes < 1024) {
    return '$bytes B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(2)} KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    // Corrected: MB calculation
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  } else if (bytes < 1024 * 1024 * 1024 * 1024) {
    // Added GB condition
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  } else {
    // Handle very large sizes (TB or more)
    return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(2)} TB';
  }
}


class QuizCard extends StatelessWidget {
  final QuizGeneration metadata;

  const QuizCard({super.key, required this.metadata});

  // Helper function to determine the color based on quiz status.
  Color _statusColor() {
    switch (metadata.status) {
      case 'completed':
        return Colors.green.shade600;
      case 'processing':
        return Colors.orange.shade600;
      case 'failed':
        return Colors.red.shade600;
      case 'pending':
      default:
        return Colors.grey.shade600;
    }
  }

  // Helper function to determine the icon based on quiz status.
  IconData _statusIcon() {
    switch (metadata.status) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.sync;
      case 'failed':
        return Icons.error_outline;
      case 'pending':
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          spacing: 15,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiz status section (icon and text)
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: Text(
                    metadata.generationNickname,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _statusColor(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    spacing: 5,
                    children: [
                      Icon(_statusIcon(), size: 15, color: Colors.white),
                      Text(
                        metadata.status,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              spacing: 10,
              children: [
                Row(
                  spacing: 5,
                  children: [
                    Icon(Icons.question_answer_outlined),
                    Text('${metadata.questionsCount} Qs'),
                  ],
                ),
                Row(
                  spacing: 5,
                  children: [
                    Icon(Icons.bar_chart_rounded),
                    Text(metadata.difficultyLevel),
                  ],
                ),
                Expanded(child: SizedBox()),
                Text(
                  DateFormat('EEE, MMM yy').format(
                    metadata.completedAt?.toDate() ??
                        metadata.createdAt.toDate(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
