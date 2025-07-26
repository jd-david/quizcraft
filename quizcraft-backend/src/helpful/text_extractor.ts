import axios from "axios";
import fs from "fs/promises";
import path from "path";
import os from "os";
import crypto from "crypto";
import pdfParse from "pdf-parse";
import mammoth from "mammoth";
import { createWorker } from "tesseract.js";
import removeMd from "remove-markdown";
import AIModel from "../genkit/model";
import { z } from "genkit";

export async function extractTextFromUrl(fileUrl: string): Promise<string> {
  const response = await axios.get(fileUrl, { responseType: "arraybuffer" });

  const mimeType = response.headers["content-type"];
  const ext = mimeTypeToExtension(mimeType);

  if (!ext) {
    throw new Error(`Unsupported MIME type: ${mimeType}`);
  }

  const tempPath = path.join(os.tmpdir(), `file_${crypto.randomUUID()}.${ext}`);
  await fs.writeFile(tempPath, response.data);

  let text: string;
  try {
    switch (ext) {
      case "pdf":
        text = await extractFromPDF(tempPath);
        break;
      case "docx":
        text = await extractFromDocx(tempPath);
        break;
      case "txt":
      case "md":
        text = await extractFromText(tempPath, ext);
        break;
      case "png":
      case "jpg":
        text = await extractFromImage(tempPath);
        break;
      default:
        throw new Error(`Unsupported file extension: ${ext}`);
    }
  } finally {
    await fs.unlink(tempPath);
  }

  return text;
}

// Maps common MIME types to file extensions
function mimeTypeToExtension(mime: string): string | null {
  const map: Record<string, string> = {
    "application/pdf": "pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
      "docx",
    "text/plain": "txt",
    "text/markdown": "md",
    "image/png": "png",
    "image/jpeg": "jpg",
    // Add more mappings if needed
  };
  return map[mime] || null;
}

// Extractors

async function extractFromPDF(filePath: string): Promise<string> {
  const data = await fs.readFile(filePath);
  const pdf = await pdfParse(data);
  return pdf.text;
}

async function extractFromDocx(filePath: string): Promise<string> {
  const buffer = await fs.readFile(filePath);
  const result = await mammoth.extractRawText({ buffer });
  return result.value;
}

async function extractFromText(
  filePath: string,
  ext: "txt" | "md"
): Promise<string> {
  const content = await fs.readFile(filePath, "utf8");
  return ext === "md" ? removeMd(content) : content;
}

async function extractFromImage(filePath: string): Promise<string> {
  const worker = await createWorker("eng");
  const {
    data: { text },
  } = await worker.recognize(filePath);
  await worker.terminate();
  return text;
}

export async function generateSummaryFromLectureMaterials(
  url: string
): Promise<string> {
  if (!url) {
    throw new Error("No lecture material URL provided.");
  }
  const response = await AIModel.generate({
    prompt: [
      {
        text: "Generate a 5-10 lines summary/description of the attached lecture Material",
      },
      { media: { url } },
    ],
    output: { schema: z.object({ summary: z.string() }) },
  });
  return response.output.summary!;
}
