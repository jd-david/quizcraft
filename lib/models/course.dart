import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  String courseName;
  String? courseCode;

  final Timestamp createdAt;
  final Timestamp updatedAt;
  int numberOfMaterials;
  int numberOfQuizzes;
  double? performance;

  Course({
    required this.id,
    required this.courseName,
    this.courseCode,
    this.performance,
    required this.numberOfMaterials,
    required this.numberOfQuizzes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromMap(String id, Map<String, dynamic> data) {
    return Course(
      id: id,
      courseName: data['courseName'],
      courseCode: data['courseCode'],
      numberOfMaterials: data['numberOfMaterials'] ?? 0,
      numberOfQuizzes: data['numberOfQuizzes'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      performance: data['performance'] == null
          ? 0.5
          : double.parse((data['performance']).toString()),
    );
  }
}
