// --- UI Color Constants for Theming ---
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quizcraft/models/lecture_materials.dart';
import 'package:quizcraft/models/quiz_generation.dart';
import 'package:quizcraft/services/provider_model.dart';
import 'package:quizcraft/widgets/course/generations/questions/questionscreen.dart';


const kWarningColor = Color(0xFFFFC107);
const kWarningLightColor = Color(0xFFFFF8E1);


class GenerationsPage extends StatefulWidget {
  const GenerationsPage({
    super.key,
    required this.generationDetails,
    required this.courseid, // courseId is available if needed
  });

  final QuizGeneration generationDetails;
  final String courseid;

  @override
  State<GenerationsPage> createState() => _GenerationsPageState();
}

class _GenerationsPageState extends State<GenerationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late QuizGeneration quiz;

  @override
  void initState() {
    super.initState();
    quiz = widget.generationDetails;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  onPop() async {
    final updatedquiz = await context.read<AppProvider>().getQuiz(
      widget.courseid,
      widget.generationDetails.quizGenerationId,
    );
    setState(() {
      quiz = updatedquiz;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          quiz.generationNickname,
          style: const TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Hero Card (Changes based on status) ---
            _buildHeroCard(quiz),
            const SizedBox(height: 20),

            // --- Performance Summary (Conditional) ---
            if (quiz.summary != null)
              _InfoCard(
                icon: Icons.bar_chart,
                title: 'Performance Summary',
                child: Text(
                  quiz.summary!,
                  style: const TextStyle(color: kTextLightColor, height: 1.6),
                ),
              ),
            if (quiz.summary != null) const SizedBox(height: 20),

            // --- Error Details (Conditional) ---
            if (quiz.isFailed && quiz.errorMessage != null)
              _InfoCard(
                icon: Icons.error_outline,
                title: 'Error Details',
                titleColor: kDangerColor,
                child: Text(
                  quiz.errorMessage!,
                  style: const TextStyle(color: kTextLightColor, height: 1.6),
                ),
              ),
            if (quiz.isFailed) const SizedBox(height: 20),

            // --- Generation Details ---
            _InfoCard(
              icon: Icons.file_present_rounded,
              title: 'Generation Details',
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.quiz_outlined,
                    label: 'Questions',
                    value:
                        '${quiz.questionsCount} / ${quiz.numQuestionsRequested}',
                  ),
                  _DetailRow(
                    icon: Icons.speed_outlined,
                    label: 'Difficulty',
                    valueWidget: Text(
                      quiz.difficultyLevel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: quiz.difficultyLevel == 'Easy'
                            ? kSuccessColor
                            : quiz.difficultyLevel == 'Medium'
                            ? kWarningColor
                            : kDangerColor,
                      ),
                    ),
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Created On',
                    value: DateFormat.yMMMd().format(quiz.createdAt.toDate()),
                  ),
                  if (quiz.customPrompt != null)
                    _DetailRow(
                      icon: Icons.edit_note,
                      label: 'Custom Prompt',
                      value: 'Yes',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Source Materials ---
            _InfoCard(
              icon: Icons.folder_zip_outlined,
              title: 'Source Materials',
              child: FutureBuilder(
                future: context.read<AppProvider>().getMaterials(
                  widget.courseid,
                ),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return SizedBox();
                  }
                  return Column(
                    children: quiz.sourceMaterialIds
                        .map(
                          (id) => ListTile(
                            leading: const Icon(
                              Icons.description_outlined,
                              color: kPrimaryColor,
                            ),
                            title: Text(
                              snap.requireData
                                  .firstWhere(
                                    (e) => e.processedTextContentUrl == id,
                                    orElse: () {
                                      return LectureMaterial.deletedDummy;
                                    },
                                  )
                                  .fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            onTap: () {},
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main card at the top which changes based on the quiz status.
  Widget _buildHeroCard(QuizGeneration quiz) {
    Widget content;
    Widget button;
    Color gradientStartColor;

    switch (quiz.status) {
      case 'completed':
        gradientStartColor = kSuccessLightColor;
        content = Column(
          children: [
            Text(
              '${((quiz.grade ?? 0) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: kSuccessColor,
              ),
            ),
            const Text(
              'Final Grade',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: kSuccessColor,
              ),
            ),
          ],
        );
        button = ElevatedButton(
          onPressed: () async {
            final questions = await context.read<AppProvider>().getQuestions(
              quiz,
              widget.courseid,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizScreen(
                  status: widget.generationDetails.status,
                  questions: questions,
                  courseId: widget.courseid,
                  generationId: quiz.quizGenerationId,
                ),
              ),
            ).then((e) => onPop());
          },
          style: ElevatedButton.styleFrom(backgroundColor: kSuccessColor),
          child: const Text('Review Questions'),
        );
        break;
      case 'pending':
        gradientStartColor = kPrimaryColor.withOpacity(0.1);
        content = Column(
          children: [
            const Text(
              'Ready to Start',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${quiz.questionsCount} questions await you!',
              style: const TextStyle(fontSize: 14, color: kTextLightColor),
            ),
          ],
        );
        button = ElevatedButton(
          onPressed: () async {
            final questions = await context.read<AppProvider>().getQuestions(
              quiz,
              widget.courseid,
            );
            if (!mounted) {
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizScreen(
                  status: widget.generationDetails.status,
                  questions: questions,
                  courseId: widget.courseid,
                  generationId: quiz.quizGenerationId,
                ),
              ),
            ).then((e) => onPop());
          },
          child: const Text('Start Quiz'),
        );
        break;
      case 'processing':
        gradientStartColor = kWarningLightColor;
        content = FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: const [
              Text(
                'Generating Quiz...',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This may take a moment.',
                style: TextStyle(fontSize: 14, color: kTextLightColor),
              ),
            ],
          ),
        );
        button = ElevatedButton(
          onPressed: null, // Disabled button
          child: const Text('Processing...'),
        );
        break;
      case 'failed':
      default:
        gradientStartColor = kDangerLightColor;
        content = Column(
          children: const [
            Text(
              'Generation Failed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kDangerColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'An error occurred. See details below.',
              style: TextStyle(fontSize: 14, color: kTextLightColor),
            ),
          ],
        );
        button = ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: kDangerColor),
          child: const Text('Retry Generation'),
        );
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStartColor, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            content,
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: button),
          ],
        ),
      ),
    );
  }
}

/// A reusable card widget for displaying sections of information.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
    this.titleColor = kTextColor,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: titleColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

/// A reusable row widget for the "Details" card.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  }) : assert(value != null || valueWidget != null);

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: kTextLightColor, size: 20),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: kTextLightColor)),
            ],
          ),
          valueWidget ??
              Text(
                value!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
        ],
      ),
    );
  }
}
