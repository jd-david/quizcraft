import { QuestionsOutput, questionsoutputSchema } from "./schema"; // Assuming your Zod schemas are here
import { z } from "genkit";
import AIModel from "./model";

// Define the input schema for our flow
const examGenerationInputSchema = z.object({
  lectureMaterialsLinks: z.array(z.string()).min(1).max(10),
  numQuestions: z.number().int().min(1).max(50),
  difficultyLevel: z.enum(["easy", "medium", "hard"]),
  customPromptSegment: z.string().optional(),
  targetQuestionTypes: z
    .array(
      z.enum([
        "multiple-choice",
        "true-false",
        "short-answer",
        "fill-in-the-blank",
      ])
    )
    .optional(),
});
export type ExamGenerationInput = z.infer<typeof examGenerationInputSchema>;

// Define the flow
export const generateExamQuestionsFlow = AIModel.defineFlow(
  {
    name: "generateExamQuestions",
    inputSchema: examGenerationInputSchema,
    outputSchema: questionsoutputSchema,
  },
  async (input: ExamGenerationInput): Promise<QuestionsOutput> => {
    const {
      lectureMaterialsLinks,
      numQuestions,
      difficultyLevel,
      customPromptSegment,
      targetQuestionTypes,
    } = input;
    let prompt = `Based on the attached lecture materials, generate ${numQuestions} exam questions. The overall difficulty level should be: ${difficultyLevel}`;

    if (targetQuestionTypes && targetQuestionTypes.length > 0) {
      prompt += `Focus on generating the following types of questions: ${targetQuestionTypes.join(
        ", "
      )}.\n`;
    } else {
      prompt += `Generate a mix of question types including multiple-choice, true-false, short-answer, and fill-in-the-blank.\n`;
    }
    prompt += `
For each question, provide:
1.  "questionText": The text of the question.
    - For "fill-in-the-blank" questions, use "____" to indicate the blank.
2.  "questionType": One of "multiple-choice", "true-false", "short-answer", "fill-in-the-blank".
3.  "options" (ONLY for "multiple-choice"): An array of strings representing the answer choices. There should be at least 2 options.
4.  "correctAnswer":
    - For "multiple-choice": The 0-based integer index of the correct option in the "options" array.
    - For "true-false": A boolean value (true or false).
    - For "short-answer" or "fill-in-the-blank": A string representing the correct answer, or an array of acceptable string answers. The expected aswer must not be more than 3 words long.
5.  "explanation": Add short explanation for the answer. Do NOT quote page references (Number or lines) in your explanation. But you can quote the text in the lecture materials itself.

${
  customPromptSegment
    ? `Additional instructions from student: ${customPromptSegment}\n`
    : ""
}

Please provide your response as a JSON object.
Output schema should be:
{questions: (array) an Array of the questions, generationNickname: (Required string) a nickname at most 90 characters long for the generation based on the ${
      customPromptSegment ? "users prompt and" : ""
    } the context or lecture materials}.

adhering strictly to this structure.
Do NOT include any introductory text, explanations, or summaries outside of the JSON structure itself.`;

    const llmResponse = await AIModel.generate({
      prompt: [
        ...(lectureMaterialsLinks
          ? lectureMaterialsLinks.map((e) => ({
              media: {
                url: e,
              },
            }))
          : []),
        { text: prompt },
      ],
      system: "You are an expert exam question creator for university students",
    });
    try {
      const validatedQuestions = questionsoutputSchema.parse(
        llmResponse.output
      );
      return validatedQuestions;
    } catch (e: any) {
      console.error("Failed to parse or validate LLM JSON output:", e.message);
      throw e;
    }
  }
);
