import { Response } from "express";
import { AuthRequest } from "../types/types";
import admin from "firebase-admin";
export async function createCourse(req: AuthRequest, res: Response) {
  const { courseName, courseCode } = req.body as {
    courseName: string;
    courseCode?: string | undefined;
  };
  const { uid } = req.user!;
  const courseId = admin.firestore().collection("courses").doc().id;
  const coursePath = `users/${uid}/courses/${courseId}`;

  const data: {
    id: string;
    courseName: string;
    numberOfMaterials: number;
    numberOfQuizzes: number;
    createdAt: admin.firestore.FieldValue;
    updatedAt: admin.firestore.FieldValue;
    performance: number;
    courseCode?: string;
  } = {
    id: courseId,
    courseName,
    numberOfMaterials: 0,
    numberOfQuizzes: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    performance: 0,
  };
  if (courseCode !== undefined && courseCode !== null) {
    data.courseCode = courseCode;
  }

  await admin.firestore().doc(coursePath).set(data);
  res.status(201).json(data);
}

export async function deleteCourse(req: AuthRequest, res: Response) {
  const { courseId } = req.params as { courseId: string };

  try {
    const { uid } = req.user!;
    const coursePath = `users/${uid}/courses/${courseId}`;
    const courseRef = admin.firestore().doc(coursePath);
    const batch = admin.firestore().batch();

    const materialsSnapshot = await courseRef
      .collection("lectureMaterials")
      .get();
    for (const doc of materialsSnapshot.docs) {
      batch.delete(doc.ref);
    }

    const [files] = await admin
      .storage()
      .bucket()
      .getFiles({ prefix: `${coursePath}/lectureMaterials` });

    if (files.length !== 0) {
      const deletePromises = files.map((file) => file.delete());
      await Promise.all(deletePromises);
    }
    const quizzesSnapshot = await courseRef.collection("quizGenerations").get();
    for (const quizDoc of quizzesSnapshot.docs) {
      const questionsSnapshot = await quizDoc.ref.collection("questions").get();
      for (const questionDoc of questionsSnapshot.docs) {
        batch.delete(questionDoc.ref);
      }
      batch.delete(quizDoc.ref);
    }

    // Commit batch deletes
    await batch.commit();

    // Delete the course document itself
    await courseRef.delete();

    res.status(200).json({ message: "Course deleted successfully." });
  } catch (error) {
    console.error("Error deleting course:", error);
    res.status(500).json({ error: "Failed to delete course." });
  }
}
