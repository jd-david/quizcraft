class QuizGenerationConfig {
  final int numQuestions;
  final String difficultyLevel;
  final String? prompt;
  final List<String>? targetQuestionTypes;
  final String courseId;
  final List<String> materials;

  QuizGenerationConfig({
    required this.materials,
    required this.numQuestions,
    required this.difficultyLevel,
    this.prompt,
    this.targetQuestionTypes,
    required this.courseId,
  });
}
