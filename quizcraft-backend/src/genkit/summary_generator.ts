import admin from "firebase-admin";
import {
  extractTextFromUrl,
  generateSummaryFromLectureMaterials,
} from "../helpful/text_extractor";
import fs from "fs/promises";
import path from "path";

export async function extractTextFromFile(
  tempUrl: string,
  newPath: string
): Promise<{ summary: string; url: string }> {
  const extractedtext = await extractTextFromUrl(tempUrl);
  const localpath = path.join("/tmp", `extracted_${Date.now()}.txt`);
  await fs.writeFile(localpath, extractedtext, "utf8");
  await admin
    .storage()
    .bucket()
    .upload(localpath, {
      destination: newPath,
      metadata: { contentType: "text/plain" },
    });
  await admin.storage().bucket().file(newPath).makePublic();
  const url = admin.storage().bucket().file(newPath).publicUrl();
  const summary = await generateSummaryFromLectureMaterials(tempUrl);
  return { summary, url };
}
