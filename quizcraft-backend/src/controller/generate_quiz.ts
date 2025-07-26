import { Response } from "express";
import { AuthRequest, QuizGenerationRequest } from "../types/types";
import {
  ExamGenerationInput,
  generateExamQuestionsFlow,
} from "../genkit/quizgenerator";
import admin from "firebase-admin";
import { gradeAnswers, GradingInput } from "../genkit/grade";

export async function generateQuestions(req: AuthRequest, res: Response) {
  const {
    materials,
    numQuestions,
    difficultyLevel,
    prompt,
    targetQuestionTypes,
    courseid,
  } = req.body as {
    materials: ExamGenerationInput["lectureMaterialsLinks"];
    numQuestions: ExamGenerationInput["numQuestions"];
    difficultyLevel: ExamGenerationInput["difficultyLevel"];
    prompt?: ExamGenerationInput["customPromptSegment"];
    targetQuestionTypes?: ExamGenerationInput["targetQuestionTypes"];
    courseid: string;
  };
  const { uid } = req.user;
  const generationId = admin.firestore().collection("quizGenerations").doc().id;
  const generationRef = admin
    .firestore()
    .collection("users")
    .doc(uid)
    .collection("courses")
    .doc(courseid)
    .collection("quizGenerations")
    .doc(generationId);

  const input: ExamGenerationInput = {
    lectureMaterialsLinks: materials,
    numQuestions,
    difficultyLevel,
    targetQuestionTypes: targetQuestionTypes ? targetQuestionTypes : undefined,
    customPromptSegment: prompt ? prompt : undefined,
  };

  const flowresult = await generateExamQuestionsFlow.run(input);
  const questions = flowresult.result;
  const firestoreData: QuizGenerationRequest = {
    sourceMaterialIds: materials,
    customPrompt: prompt,
    numQuestionsRequested: numQuestions,
    difficultyLevel: difficultyLevel,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    questionsCount: questions.questions.length,
    generationNickname: questions.generationNickname,
  };

  await generationRef.set(firestoreData);
  await Promise.all(
    questions.questions.map(async (question) => {
      await generationRef.collection("questions").add(question);
    })
  );
  await admin
    .firestore()
    .collection("users")
    .doc(uid)
    .collection("courses")
    .doc(courseid)
    .update({ numberOfQuizzes: admin.firestore.FieldValue.increment(1) });
  res
    .status(200)
    .json({
      ...firestoreData,
      createdAt: admin.firestore.Timestamp.now(),
      id: generationId,
    });
  return;
}

export async function gradeAndSummarize(req: AuthRequest, res: Response) {
  const { generationId, courseId } = req.body as {
    generationId: string;
    courseId: string;
  };
  const { uid } = req.user;
  const generationRef = admin
    .firestore()
    .collection("users")
    .doc(uid)
    .collection("courses")
    .doc(courseId)
    .collection("quizGenerations")
    .doc(generationId);
  const materials = (await generationRef.get()).data().sourceMaterialIds;
  const docs = (await generationRef.collection("questions").get()).docs.map(
    (e) => e.data()
  );
  const input: GradingInput = {
    lectureMaterialsLinks: materials,
    questions: docs.map((e) => {
      return {
        question: {
          questionType: e.questionType,
          questionText: e.questionText,
          options: e.options,
          correctAnswer: e.correctAnswer,
          explanation: e.explanation,
        },
        userAnswer: e.userAnswer,
      };
    }),
  };
  const gradeResult = await gradeAnswers.run(input);
  const { grade: actualGrade, summary } = gradeResult.result;
  const grade = actualGrade / docs.length;
  await generationRef.update({
    status: "completed",
    grade,
    summary: summary,
  });

  res.status(200).json({ grade, summary });
}
