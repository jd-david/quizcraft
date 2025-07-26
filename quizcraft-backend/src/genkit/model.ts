import googleAI, { gemini20FlashLite } from "@genkit-ai/googleai";
import { genkit } from "genkit";

const  AIModel = genkit({
    plugins: [googleAI()],
    model: gemini20FlashLite,
  });

  export default AIModel;