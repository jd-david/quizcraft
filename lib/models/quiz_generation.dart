import 'package:cloud_firestore/cloud_firestore.dart';

class QuizGeneration {
  final String generationNickname;
  final List<String> sourceMaterialIds;
  final String? customPrompt;

  final int numQuestionsRequested;
  final String difficultyLevel;
  final String status;
  final Timestamp createdAt;
  final Timestamp? completedAt;
  final String? errorMessage;
  final int questionsCount;
  final String quizGenerationId;
  final double? grade;
  final String? summary;

  QuizGeneration({
    required this.generationNickname,
    required this.sourceMaterialIds,
    required this.customPrompt,
    required this.numQuestionsRequested,
    required this.difficultyLevel,
    required this.status,
    required this.createdAt,
    required this.quizGenerationId,
    required this.questionsCount,
    this.completedAt,
    this.grade,
    this.summary,
    this.errorMessage,
  });

  // Factory constructor to create a QuizGeneration instance from a Firestore document ID and data map.
  //
  // Parameters:
  //   id: The document ID from Firestore, mapped to quizGenerationId.
  //   data: The map of data (document fields) from Firestore.
  factory QuizGeneration.fromFirestore(
    String id,
    Map<String, dynamic> data, {
    bool time = false,
  }) {
    return QuizGeneration(
      quizGenerationId: id,
      generationNickname: data['generationNickname'] as String,
      sourceMaterialIds: List<String>.from(data['sourceMaterialIds'] as List),
      customPrompt: data['customPrompt'] as String?,
      numQuestionsRequested: data['numQuestionsRequested'] as int,
      difficultyLevel: data['difficultyLevel'] as String,
      status: data['status'] as String,
      createdAt: time ? Timestamp.now() : data['createdAt'] as Timestamp,
      completedAt: data['completedAt'] as Timestamp?,
      errorMessage: data['errorMessage'] as String?,
      questionsCount: data['questionsCount'] as int,
      grade: data['grade'] != null
          ? double.parse(data['grade'].toString())
          : null,
      summary: data['summary'] as String?,
    );
  }

  // Method to convert a QuizGeneration instance to a map suitable for Firestore storage.
  // This is useful when creating or updating documents in Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'quizGenerationId':
          quizGenerationId, 
      'generationNickname': generationNickname,
      'sourceMaterialUrls': sourceMaterialIds,
      'customPrompt': customPrompt,
      'numQuestionsRequested': numQuestionsRequested,
      'difficultyLevel': difficultyLevel,
      'status': status,
      'createdAt': createdAt,
      if (completedAt != null) 'completedAt': completedAt,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'questionsCount': questionsCount,
      if (grade != null) 'grade': grade,
      if (summary != null) 'summary': summary,
    };
  }

  QuizGeneration copyWith({
    String? generationNickname,
    List<String>? sourceMaterialIds,
    String? customPrompt,
    int? numQuestionsRequested,
    String? difficultyLevel,
    String? status,
    Timestamp? createdAt,
    Timestamp? completedAt,
    String? errorMessage,
    int? questionsCount,
    String? quizGenerationId,
    double? grade,
    String? summary,
  }) {
    return QuizGeneration(
      generationNickname: generationNickname ?? this.generationNickname,
      sourceMaterialIds: sourceMaterialIds ?? this.sourceMaterialIds,
      customPrompt: customPrompt ?? this.customPrompt,
      numQuestionsRequested:
          numQuestionsRequested ?? this.numQuestionsRequested,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      questionsCount: questionsCount ?? this.questionsCount,
      quizGenerationId: quizGenerationId ?? this.quizGenerationId,
      grade: grade ?? this.grade,
      summary: summary ?? this.summary,
    );
  }

  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  bool get isGraded => grade != null;
}
