import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quizcraft/models/course.dart';
import 'package:quizcraft/models/lecture_materials.dart';
import 'package:quizcraft/models/question.dart';
import 'package:quizcraft/models/quiz_generation_config.dart';
import 'package:quizcraft/models/quiz_generation.dart';
import 'package:quizcraft/config.dart';

class AppProvider extends ChangeNotifier {
  List<Course>? _courses;
  final Map<String, List<LectureMaterial>?> _lecturematerials = {};
  final Map<String, List<QuizGeneration>?> _quizzes = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Course>> getCourses() async {
    if (_courses != null) {
      return _courses!;
    }
    try {
      final coursedata = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('courses')
          .get();
      final courses = coursedata.docs
          .map((e) => Course.fromMap(e.id, e.data()))
          .toList();
      _courses = courses;
      return courses;
    } catch (e) {
      return []; 
    }
  }

  Future<List<LectureMaterial>> getMaterials(String courseid) async {
    if (_lecturematerials[courseid] != null) {
      return _lecturematerials[courseid]!;
    }
    try {
      final datadocs = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('courses')
          .doc(courseid)
          .collection('lectureMaterials')
          .orderBy('uploadedAt')
          .get();
      final lectureMaterials = datadocs.docs
          .map((e) => LectureMaterial.fromFirestore(e.id, e.data()))
          .toList();
      _lecturematerials.addAll({courseid: lectureMaterials});
      return lectureMaterials;
    } catch (e) {
      return []; 
    }
  }


  List<LectureMaterial>? getCourseMaterials(String courseId) {
    return _lecturematerials[courseId];
  }


  Future<List<QuizGeneration>> getQuizzes(String courseid) async {
    if (_quizzes[courseid] != null) {
      return _quizzes[courseid]!;
    }
    try {
      final datadocs = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('courses')
          .doc(courseid)
          .collection('quizGenerations')
          .orderBy('createdAt')
          .get();
      final quizzes = datadocs.docs
          .map((e) => QuizGeneration.fromFirestore(e.id, e.data()))
          .toList();
      _quizzes.addAll({courseid: quizzes});
      return quizzes;
    } catch (e) {
      return [];
    }
  }

  Future<QuizGeneration> getQuiz(
    String courseid,
    String quizGenerationId,
  ) async {
    final cachedQuizList = _quizzes[courseid];
    if (cachedQuizList != null) {
      final cachedQuiz = cachedQuizList.where(
        (e) => e.quizGenerationId == quizGenerationId,
      );
      if (cachedQuiz.isNotEmpty) {
        return cachedQuiz.first;
      }
    }
    try {
      final datadocs = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('courses')
          .doc(courseid)
          .collection('quizGenerations')
          .doc(quizGenerationId)
          .get();
      if (!datadocs.exists) {
        throw Error();
      }
      final quiz = QuizGeneration.fromFirestore(datadocs.id, datadocs.data()!);
      _quizzes[courseid]?.add(quiz);
      return quiz;
    } catch (e) {
      throw Exception();
    }
  }

  void _addMaterial(String courseid, LectureMaterial material) {
    _lecturematerials[courseid] ??= []; 
    _lecturematerials[courseid]!.add(material);
    notifyListeners();
  }

  Future<void> deleteSlide(String courseid, LectureMaterial mat) async {
    try {
      await FirebaseStorage.instance
          .refFromURL(mat.processedTextContentUrl)
          .delete();
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('courses')
          .doc(courseid)
          .collection('lectureMaterials')
          .doc(mat.materialId)
          .delete();
      _lecturematerials[courseid]?.removeWhere(
        (item) => item.materialId == mat.materialId,
      );
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('courses')
          .doc(courseid)
          .update({'numberOfMaterials': FieldValue.increment(-1)});
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete material: $e');
    }
  }

  Future<void> handlePickMaterials(
    BuildContext context,
    String courseid,
  ) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    for (var file in result.files) {
      final id = _firestore.collection('temp_ids').doc().id;
      Reference storageRef = FirebaseStorage.instance.ref('Temp').child(id);

      try {
        final task = await storageRef.putFile(File(file.path!));
        final url = await task.ref.getDownloadURL();

        final response = await http.post(
          Uri.parse('$API_BASE_URL/quiz/uploadMaterials'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization':
                'Bearer ${(await _auth.currentUser!.getIdToken())!}',
          },
          body: jsonEncode({
            'path': task.ref.fullPath,
            'name': file.name,
            'tempUrl': url,
            'courseId': courseid,
          }),
        );

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          _addMaterial(
            courseid,
            LectureMaterial.fromFirestore(data['id'], {
              ...data,
              'uploadedAt': Timestamp.now(),
            }),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${file.name} uploaded successfully.')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to upload ${file.name} (server error: ${response.statusCode})',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } on FirebaseException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Storage error for ${file.name}: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on SocketException {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Network error for ${file.name}: Please check your connection.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on TimeoutException {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Upload for ${file.name} timed out. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'An unexpected error occurred for ${file.name}: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }


  Future<QuizGeneration> generateQuiz(QuizGenerationConfig config) async {
    try {
      final response = await http
          .post(
            Uri.parse('$API_BASE_URL/quiz/generateQuestions'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization':
                  'Bearer ${(await _auth.currentUser!.getIdToken())!}',
            },
            body: jsonEncode({
              'materials': config.materials,
              'numQuestions': config.numQuestions,
              'difficultyLevel': config.difficultyLevel,
              'prompt': config.prompt,
              'targetQuestionTypes': config.targetQuestionTypes,
              'courseid': config.courseId,
            }),
          )
          .timeout(const Duration(seconds: 120));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Failed to start quiz generation (server error: ${response.statusCode}) - ${response.body}',
        );
      }
      final data = jsonDecode(response.body);
      final quiz = QuizGeneration.fromFirestore(data['id'], data, time: true);

      _quizzes[config.courseId] ??= [];
      _quizzes[config.courseId]!.add(quiz);
      notifyListeners();
      return quiz;
    } on SocketException {
      throw Exception('Network error: Please check your connection.');
    } on TimeoutException {
      throw Exception('Quiz generation request timed out. Please try again.');
    } catch (e) {
      throw Exception('An unexpected error occurred while generating quiz: $e');
    }
  }

  Future<void> deleteCourse(String courseId) async {
    final response = await http
        .delete(
          Uri.parse('$API_BASE_URL/course/$courseId'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization':
                'Bearer ${(await _auth.currentUser!.getIdToken())!}',
          },
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      _courses?.removeWhere((course) => course.id == courseId);
      notifyListeners();
    }
  }

  Future<Course> addCourse(String name, String? courseCode) async {
    Map body = {'courseName': name};
    if (courseCode != null) {
      body.addAll({'courseCode': courseCode});
    }
    final response = await http
        .post(
          Uri.parse('$API_BASE_URL/course'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization':
                'Bearer ${(await _auth.currentUser!.getIdToken())!}',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final course = Course.fromMap(data['id'], {
        ...data,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      _courses?.add(course);
      return course;
    } else {
      throw Error();
    }
  }

  Future<List<Question>> getQuestions(
    QuizGeneration config,
    String courseCode,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('courses')
          .doc(courseCode)
          .collection('quizGenerations')
          .doc(config.quizGenerationId)
          .collection('questions')
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs
          .map((doc) => Question.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future submitAnswer(String courseId, genid, questid, dynamic ans) async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('courses')
        .doc(courseId)
        .collection('quizGenerations')
        .doc(genid)
        .collection('questions')
        .doc(questid)
        .update({'userAnswer': ans});
  }

  Future finishQuiz(String courseId, genid) async {
    final response = await http
        .post(
          Uri.parse('$API_BASE_URL/quiz/gradeAndSummarize'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization':
                'Bearer ${(await _auth.currentUser!.getIdToken())!}',
          },
          body: jsonEncode({'generationId': genid, 'courseId': courseId}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final quizList = _quizzes[courseId];
      if (quizList != null) {
        final index = quizList.indexWhere((e) => e.quizGenerationId == genid);
        if (index != -1) {
          quizList[index] = quizList[index].copyWith(
            grade: double.tryParse(data['grade'].toString()),
            summary: data['summary'],
            status: 'completed',
          );
          _quizzes[courseId] = quizList;
          notifyListeners();
          return true;
        }
      }
    }
  }
}
