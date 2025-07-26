enum QuestionType { multipleChoice, trueFalse, shortAnswer, fillInTheBlank }

class Question {
  final String questionText;
  final QuestionType questionType;
  final String explanation;
  final List<String>? options;
  final dynamic correctAnswer;
  final dynamic userAnswer;
  final String id;

  Question({
    required this.questionText,
    required this.questionType,
    required this.explanation,
    required this.id,
    this.options,
    this.correctAnswer,
    this.userAnswer,
  });

  factory Question.fromMap(Map<String, dynamic> map, String id) {
    return Question(
      questionText: map['questionText'] as String,
      questionType: _questionTypeFromString(map['questionType'] as String),
      explanation: map['explanation'] as String,
      options:
          map['options'] != null || List<String>.from(map['options']).isNotEmpty
          ? List<String>.from(map['options'])
          : null,
      correctAnswer: map['correctAnswer'],
      userAnswer: map['userAnswer'],
      id: id,
    );
  }

  static QuestionType _questionTypeFromString(String type) {
    switch (type) {
      case 'multiple-choice':
        return QuestionType.multipleChoice;
      case 'true-false':
        return QuestionType.trueFalse;
      case 'short-answer':
        return QuestionType.shortAnswer;
      case 'fill-in-the-blank':
        return QuestionType.fillInTheBlank;
      default:
        throw ArgumentError('Unknown question type: $type');
    }
  }
}
