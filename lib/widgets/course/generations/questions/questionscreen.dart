import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart'; 
import 'package:quizcraft/models/question.dart';
import 'package:quizcraft/services/provider_model.dart';

const kPrimaryColor = Color(0xFF6A5AF9);
const kSuccessColor = Color(0xFF28A745);
const kSuccessLightColor = Color(0xFFEAF6EC);
const kDangerColor = Color(0xFFDC3545);
const kDangerLightColor = Color(0xFFFBE9EB);
const kBackgroundColor = Color(0xFFF4F7FE);
const kTextColor = Color(0xFF1E293B);
const kTextLightColor = Color(0xFF64748B);
const kBorderColor = Color(0xFFE2E8F0);

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.questions,
    required this.courseId,
    required this.generationId,
    required this.status,
  });
  final List<Question> questions;
  final String generationId;
  final String courseId;
  final String status;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _pageController = PageController();
  late List<Question> _questions;
  late List<bool> _isAnswered;
  late List<dynamic> _userAnswers;
  int _currentPage = 0;
  bool _isFinishing = false;
  late bool iscompleted;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _questions = widget.questions;
    _isAnswered = List<bool>.generate(
      _questions.length,
      (index) => _questions[index].userAnswer != null,
    );
    _userAnswers = List<dynamic>.generate(
      _questions.length,
      (index) => _questions[index].userAnswer,
    );
    iscompleted = widget.status=='completed';
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    final firstUnanswered = _isAnswered.indexWhere((answered) => !answered);
    if (firstUnanswered != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pageController.jumpToPage(firstUnanswered);
          setState(() {
            _currentPage = firstUnanswered;
          });
        }
      });
    }
  }
  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _goToNextPage() async {
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else if (iscompleted) {
      Navigator.pop(context);
    } else {
      setState(() => _isFinishing = true);
      try {
        await context.read<AppProvider>().finishQuiz(
          widget.courseId,
          widget.generationId,
        );
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to finish quiz. Please try again. Error: $e',
              ),
              backgroundColor: kDangerColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isFinishing = false);
      }
    }
  }

  void _submitAnswer() async {
    final question = _questions[_currentPage];
    final userAnswer = _userAnswers[_currentPage];
    bool isCorrect = false;

    switch (question.questionType) {
      case QuestionType.multipleChoice:
        isCorrect = userAnswer == question.correctAnswer;
        break;
      case QuestionType.trueFalse:
        isCorrect = userAnswer == question.correctAnswer;
        break;
      case QuestionType.shortAnswer:
      case QuestionType.fillInTheBlank:
        isCorrect =
            (question.correctAnswer is String &&
                question.correctAnswer.toLowerCase() ==
                    userAnswer.toString().toLowerCase()) ||
            (question.correctAnswer is List &&
                question.correctAnswer.any(
                  (ans) =>
                      ans.toLowerCase() == userAnswer.toString().toLowerCase(),
                ));
        break;
    }

    setState(() {
      _isAnswered[_currentPage] = true;
    });

    if (isCorrect) {
      _confettiController.play();
    }

    Provider.of<AppProvider>(context, listen: false).submitAnswer(
      widget.courseId,
      widget.generationId,
      question.id,
      userAnswer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_currentPage + 1) / _questions.length;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1.0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: kTextColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Question ${_currentPage + 1} of ${_questions.length}',
              style: const TextStyle(
                color: kTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4.0),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: kBorderColor,
                valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            ),
          ),
          body: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              return _QuestionCard(
                question: _questions[index],
                isAnswered: _isAnswered[index],
                userAnswer: _userAnswers[index],
                onAnswerSelected: (answer) {
                  setState(() {
                    _userAnswers[index] = answer;
                  });
                },
              );
            },
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),

        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 20,
          gravity: 0.1,
          emissionFrequency: 0.05,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple,
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    bool canSubmit = _userAnswers[_currentPage] != null;
    bool isCurrentPageAnswered = _isAnswered[_currentPage];
    bool isLastQuestion = _currentPage == _questions.length - 1;

    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: kBorderColor,
      disabledForegroundColor: kTextLightColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      minimumSize: const Size.fromHeight(54), // Good for touch targets
      elevation: 2,
      shadowColor: kPrimaryColor.withOpacity(0.2),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isCurrentPageAnswered
            ? // --- NEXT / FINISH BUTTON ---
              ElevatedButton(
                key: const ValueKey('next_button'),
                onPressed: _isFinishing ? null : _goToNextPage,
                style: buttonStyle,
                child: isLastQuestion
                    ? _isFinishing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(!iscompleted ? 'Finish Quiz' : 'Go back')
                    : const Text('Next'),
              )
            : // --- SUBMIT BUTTON ---
              ElevatedButton(
                key: const ValueKey('submit_button'),
                onPressed: canSubmit ? _submitAnswer : null,
                style: buttonStyle,
                child: const Text('Submit'),
              ),
      ),
    );
  }
}


class _QuestionCard extends StatefulWidget {
  const _QuestionCard({
    required this.question,
    required this.isAnswered,
    required this.userAnswer,
    required this.onAnswerSelected,
  });

  final Question question;
  final bool isAnswered;
  final dynamic userAnswer;
  final ValueChanged<dynamic> onAnswerSelected;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.userAnswer is String) {
      _textController.text = widget.userAnswer;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuestionText(widget.question),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              _buildAnswerArea(),
              const SizedBox(height: 20),
              _buildExplanationBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionText(Question question) {
    if (question.questionType == QuestionType.fillInTheBlank) {
      final parts = question.questionText.split('____');
      return RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kTextColor,
            height: 1.5,
          ),
          children: [
            TextSpan(text: parts[0]),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: IntrinsicWidth(
                child: TextField(
                  controller: _textController,
                  onChanged: widget.onAnswerSelected,
                  readOnly: widget.isAnswered,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    hintText: 'your answer',
                    border: UnderlineInputBorder(),
                  ),
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      );
    }
    return Text(
      widget.question.questionText,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kTextColor,
      ),
    );
  }

  Widget _buildAnswerArea() {
    switch (widget.question.questionType) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return _buildOptionsList();
      case QuestionType.shortAnswer:
        return TextField(
          controller: _textController,
          onChanged: widget.onAnswerSelected,
          readOnly: widget.isAnswered,
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      case QuestionType.fillInTheBlank:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOptionsList() {
    return Column(
      children: List.generate(
        widget.question.questionType == QuestionType.trueFalse
            ? 2
            : widget.question.options!.length,
        (index) {
          bool isSelected =
              widget.userAnswer ==
              (widget.question.questionType == QuestionType.multipleChoice
                  ? index
                  : (index == 0));

          bool isCorrect =
              widget.question.questionType == QuestionType.multipleChoice
              ? index == widget.question.correctAnswer
              : (index == 0) == widget.question.correctAnswer;

          Color borderColor = kBorderColor;
          IconData? trailingIcon;

          if (widget.isAnswered) {
            if (isCorrect) {
              borderColor = kSuccessColor;
              trailingIcon = Icons.check_circle;
            } else if (isSelected && !isCorrect) {
              borderColor = kDangerColor;
              trailingIcon = Icons.cancel;
            }
          } else if (isSelected) {
            borderColor = kPrimaryColor;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: InkWell(
              onTap: widget.isAnswered
                  ? null
                  : () {
                      widget.onAnswerSelected(
                        widget.question.questionType ==
                                QuestionType.multipleChoice
                            ? index
                            : (index == 0),
                      );
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (widget.question.questionType == QuestionType.trueFalse
                            ? ['True', 'False']
                            : widget.question.options!)[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (trailingIcon != null)
                      Icon(trailingIcon, color: borderColor),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExplanationBox() {
    if (!widget.isAnswered) {
      return const SizedBox.shrink();
    }

    bool isCorrect;
    switch (widget.question.questionType) {
      case QuestionType.multipleChoice:
        isCorrect = widget.userAnswer == widget.question.correctAnswer;
        break;
      case QuestionType.trueFalse:
        isCorrect = widget.userAnswer == widget.question.correctAnswer;
        break;
      case QuestionType.shortAnswer:
      case QuestionType.fillInTheBlank:
        isCorrect =
            (widget.question.correctAnswer is String &&
                widget.question.correctAnswer.toLowerCase() ==
                    widget.userAnswer.toString().toLowerCase()) ||
            (widget.question.correctAnswer is List &&
                widget.question.correctAnswer.any(
                  (ans) =>
                      ans.toLowerCase() ==
                      widget.userAnswer.toString().toLowerCase(),
                ));
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Container(
        key: ValueKey(widget.isAnswered),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCorrect ? kSuccessLightColor : kDangerLightColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isCorrect ? kSuccessColor : kDangerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCorrect ? 'Correct!' : 'Incorrect',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCorrect ? kSuccessColor : kDangerColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.question.explanation,
              style: const TextStyle(color: kTextColor, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
