import { questionSchema } from "./schema"; // Assuming your Zod schemas are here
import { z } from "genkit";
import AIModel from "./model";

// Define the input schema for our flow
const gradeInputSchema = z.object({
  lectureMaterialsLinks: z.array(z.string()).min(1).max(50),
  questions: z.array(
    z.object({ question: questionSchema, userAnswer: z.any() })
  ),
});

const gradeOutputSchema = z.object({
  grade: z.number(),
  summary: z.string(),
});

export type GradingOutput = z.infer<typeof gradeOutputSchema>;
export type GradingInput = z.infer<typeof gradeInputSchema>;

// Define the flow
export const gradeAnswers = AIModel.defineFlow(
  {
    name: "gradeAnswers",
    inputSchema: gradeInputSchema,
    outputSchema: gradeOutputSchema,
  },
  async (input: GradingInput): Promise<GradingOutput> => {
    const { lectureMaterialsLinks, questions } = input;

    let prompt = `You are an expert AI teaching assistant and grader. Your task is to evaluate a user's answers to a quiz using the attached lecture materials as the source of truth. Each question includes the correct answer (as determined by the AI) and the user's submitted answer. You must score each question according to a strict rubric and provide the total grade (not a percentage).

---

**Quiz Questions with User Answers:**
${JSON.stringify(questions, null, 2)}

---

**Grading Rules (Strictly Follow These):**

- **Each question is worth a maximum of 1.0 point**
- **Score each answer from 0.0 to 1.0 in 0.1 increments**

**Full Points (1.0):**
- **Multiple Choice:** userAnswer === correctAnswer (index)
- **True/False:** userAnswer === correctAnswer (boolean)
- **Short-Answer / Fill-in-the-Blank:** userAnswer matches correctAnswer or any acceptable variant in correctAnswer (if an array), meaningfully correct even with minor spelling errors

**Partial Credit (0.1–0.9):**
- Only allowed for Short-Answer and Fill-in-the-Blank
- Evaluate based on:
  - Partial understanding or inclusion of key ideas
  - Use of relevant terms
  - Grasp of the concept but with missing context or clarity
- Scoring Suggestions:
  - 0.7–0.9: Mostly correct, minor issues
  - 0.4–0.6: Some correct info, some key errors or omissions
  - 0.1–0.3: Slightly relevant or minimally correct

**Zero Points (0.0):**
- Completely incorrect, irrelevant, or too vague
- For MCQ or T/F: userAnswer does not match correctAnswer

---

**Output Format (Strictly Use JSON):**
\`\`\`json
{
  "grade": <decimal>,  // Total score (e.g. 7.2). This value must not exceed the total number of questions since each question is valued a maximun of 1 point.
  "summary": "<string>" // A short, constructive feedback paragraph
}
\`\`\`

**Summary Guidelines:**
- Acknowledge the user's effort
- Highlight general strengths (e.g., "Clear understanding of concepts like X")
- Suggest areas for improvement (e.g., "Review the explanation of Y")
- Be encouraging and never list individual question scores
`;
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
      system:
        "You are an expert AI teaching assistant and grader. Your task is to evaluate a user's answers to a quiz based on provided lecture materials and a defined grading scheme. You must then provide an overall grade and a performance summary.",
    });
    try {
      const validatedSummary = gradeOutputSchema.parse(llmResponse.output);

      if (
        validatedSummary.grade < 0 ||
        validatedSummary.grade > questions.length
      ) {
        throw Error();
      }
      return validatedSummary;
    } catch (e: any) {
      console.error("Failed to parse or validate LLM JSON output:", e.message);
      throw e;
    }
  }
);
