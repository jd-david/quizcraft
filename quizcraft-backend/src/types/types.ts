import { Request } from "express";
import { auth } from "firebase-admin";
export interface AuthRequest extends Request {
  user?: auth.DecodedIdToken;
}
export interface LectureMaterial {
  id?: string;
  fileName: string;
  storagePath: string;
  fileType: string;
  fileSize: string | number;
  uploadedAt: any;
  status: "uploaded" | "processing" | "processed" | "error_processing";
  processedTextContentUrl?: string;
  summary?: string;
}


export type QuestionType = "multiple-choice" | "true-false" | "short-answer" | "fill-in-the-blank";

export interface QuizQuestion {
  questionText: string;
  questionType: QuestionType;
  options?: string[]; // Only for "multiple-choice"
  correctAnswer:
    | number // For "multiple-choice" (0-based index)
    | "True" | "False" // For "true-false"
    | string // For "short-answer" or "fill-in-the-blank"
    | string[]; // For "short-answer" or "fill-in-the-blank" (multiple acceptable answers)
  explanation?: string;
  difficultyScore?: number;
}


export interface QuizGenerationRequest {
  generationNickname: string;
  sourceMaterialIds: string[];
  customPrompt?: string;
  numQuestionsRequested: number;
  difficultyLevel: "easy" | "medium" | "hard";
  status: "pending" | "processing" | "completed" | "failed";
  createdAt: any;
  completedAt?: any;
  errorMessage?: string;
  questionsCount?: number;
}