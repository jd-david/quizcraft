import { Response } from "express";
import { AuthRequest, LectureMaterial } from "../types/types";
import admin from "firebase-admin";
import { getStorage } from "firebase-admin/storage";
import { extractTextFromFile } from "../genkit/summary_generator";

export async function uploadMaterials(req: AuthRequest, res: Response) {
  const { path, name, courseId, tempUrl } = req.body as {
    path: string;
    name: string;
    tempUrl: string;
    courseId: string;
  };
  const { uid } = req.user;
  const newMaterialId = admin.firestore().collection("lectureMaterials").doc().id;
  const coursePath = `users/${uid}/courses/${courseId}`;
  const newpath = `${coursePath}/lectureMaterials/${newMaterialId}`;
  try {
    const { summary, url } = await extractTextFromFile(tempUrl, newpath);
    const fileInfo = await admin.storage().bucket().file(path).getMetadata();
    
    const fileData: LectureMaterial = {
      id: newMaterialId,
      fileName: name || fileInfo[0].name,
      fileType: fileInfo[0].contentType,
      fileSize: fileInfo[0].size,
      processedTextContentUrl: url,
      summary: summary,
      storagePath: "",
      status: "processed",
      uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await admin.firestore().doc(newpath).set(fileData);
    await admin
      .firestore()
      .doc(coursePath)
      .update({ numberOfMaterials: admin.firestore.FieldValue.increment(1) });
    await admin.storage().bucket().file(path).delete();
    res.status(201).json(fileData);
  } catch (error) {
    console.error("Error uploading materials:", error);
    res.status(500).json({ error: "Failed to upload materials" });
  }
}
