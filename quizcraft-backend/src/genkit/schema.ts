import { z } from "genkit";


const baseQuestionProperties = {
  questionText: z.string().min(1, "Question text cannot be empty."),
};

const openEndedAnswerSchema = z.union(
  [
    z.string().min(1, "Correct answer cannot be empty."),
    z
      .array(z.string().min(1, "Each correct answer variant cannot be empty."))
      .min(
        1,
        "Must provide at least one correct answer variant if using an array."
      ),
  ],
  {
    // Custom error message for the union can be helpful
    errorMap: (issue, ctx) => {
      if (issue.code === z.ZodIssueCode.invalid_union) {
        return {
          message:
            "Correct answer must be a non-empty string or a non-empty array of non-empty strings.",
        };
      }
      return { message: ctx.defaultError };
    },
  }
);




const rawMcqObjectSchema = z.object({
  ...baseQuestionProperties,
  questionType: z.literal("multiple-choice"),
  options: z
    .array(z.string().min(1, "Option text cannot be empty."))
    .min(2, "Multiple-choice questions must have at least two options."),
  correctAnswer: z
    .number()
    .int()
    .min(0, "Correct answer index must be a non-negative integer."),
  explanation: z
    .string()
    .optional()
    .describe("A short explanation is required for each question."),
});


const rawTrueFalseObjectSchema = z.object({
  ...baseQuestionProperties,
  questionType: z.literal("true-false"),
  options: z
    .array(z.string()) // For non-MCQs, options should be empty or not present.
    .length(0, "Options should be empty for true/false questions.")
    .optional()
    .default([]),
  correctAnswer: z.boolean(),
  explanation: z
    .string()
    .optional()
    .describe("A short explanation is required for each question."),
});


const rawShortAnswerObjectSchema = z.object({
  ...baseQuestionProperties,
  questionType: z.literal("short-answer"),
  options: z
    .array(z.string())
    .length(0, "Options should be empty for short-answer questions.")
    .optional()
    .default([]),
  correctAnswer: openEndedAnswerSchema,
  explanation: z
    .string()
    .optional()
    .describe("A short explanation is required for each question."),
});


const rawFillInTheBlankObjectSchema = z.object({
  ...baseQuestionProperties,
  questionType: z.literal("fill-in-the-blank"),
  options: z
    .array(z.string())
    .length(0, "Options should be empty for fill-in-the-blank questions.")
    .optional()
    .default([]),
  correctAnswer: openEndedAnswerSchema,
  explanation: z
    .string()
    .optional()
    .describe("A short explanation is required for each question."),
});


const baseQuestionSchemaWithoutRefinement = z.discriminatedUnion(
  "questionType",
  [
    rawMcqObjectSchema,
    rawTrueFalseObjectSchema,
    rawShortAnswerObjectSchema,
    rawFillInTheBlankObjectSchema,
  ]
);


export const questionSchema = baseQuestionSchemaWithoutRefinement.superRefine(
  (data, ctx) => {
    // Refinement for MCQ: Validate correctAnswer index
    if (data.questionType === "multiple-choice") {
      // At this point, TypeScript knows 'data' is the MCQ variant,
      // so 'data.options' and 'data.correctAnswer' are typed correctly.
      if (data.correctAnswer >= data.options.length) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["correctAnswer"], // Path is relative to the object being validated
          message: `Correct answer index (${
            data.correctAnswer
          }) is out of bounds for the provided options (length: ${
            data.options.length
          }). Max allowed index is ${data.options.length - 1}.`,
        });
      }
    }

    // Refinement for Fill-in-the-Blank (example)
    if (data.questionType === "fill-in-the-blank") {
      if (!data.questionText.includes("____")) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["questionText"],
          message:
            "Fill-in-the-blank question text should ideally contain a blank indicator like '____'.",
        });
      }
    }
    if (!data.explanation) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["explanation"],
        message: "A short explanation is required for each question.",
      });
    }
  }
);


export const examQuestionsSchema = z.array(questionSchema);
export const questionsoutputSchema = z.object({
  questions: examQuestionsSchema,
  generationNickname: z.string().min(2).max(100),
});
export type QuestionsOutput = z.infer<typeof questionsoutputSchema>;



export type Question = z.infer<typeof questionSchema>;
export type ExamQuestions = z.infer<typeof examQuestionsSchema>;


export type MultipleChoiceQuestion = Extract<
  Question,
  { questionType: "multiple-choice" }
>;
export type TrueFalseQuestion = Extract<
  Question,
  { questionType: "true-false" }
>;
export type ShortAnswerQuestion = Extract<
  Question,
  { questionType: "short-answer" }
>;
export type FillInTheBlankQuestion = Extract<
  Question,
  { questionType: "fill-in-the-blank" }
>;


