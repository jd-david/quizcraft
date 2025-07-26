import dotenv from "dotenv";
dotenv.config();
import express from "express";
const app = express();
import cors from "cors";
import quizrouter from "./router/quiz_router";
import { cert, ServiceAccount, initializeApp } from "firebase-admin/app";
import { authenticateToken } from "./middleware/auth";
import courserouter from "./router/course_router";

const serviceAccount = JSON.parse(
  Buffer.from(process.env.CRED!, "base64").toString("utf-8")
) as ServiceAccount;
initializeApp({
  credential: cert(serviceAccount),
  storageBucket: "gs://slide-6789c.appspot.com",
});
app.use(express.json());
app.use(cors());
app.use("/quiz", authenticateToken, quizrouter);
app.use("/course", authenticateToken, courserouter);
app.get("/test", (_, res) => {
  res.json({ message: "Test endpoint working" });
});
const port = parseInt("8080");
app.listen(port, () => {
  console.log(`listening on port ${port}`);
});
