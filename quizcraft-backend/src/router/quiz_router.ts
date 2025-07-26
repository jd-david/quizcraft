import express from "express";
import { uploadMaterials } from "../controller/material_upload";
import {
  generateQuestions,
  gradeAndSummarize,
} from "../controller/generate_quiz";
const quizrouter = express.Router();

quizrouter.post("/uploadMaterials", uploadMaterials);
quizrouter.post("/generateQuestions", generateQuestions);
quizrouter.post("/gradeAndSummarize", gradeAndSummarize);

export default quizrouter;
