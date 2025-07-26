import express from "express";
import { createCourse, deleteCourse } from "../controller/course";

const router = express.Router();

router.post("/", createCourse);
router.delete("/:courseId", deleteCourse);

export default router;
