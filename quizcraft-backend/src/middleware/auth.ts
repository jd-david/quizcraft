import { NextFunction, Response } from "express";
import admin from "firebase-admin";
import { AuthRequest } from "../types/types";

async function authenticateToken(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];
  if (token == null) {
    res.sendStatus(401);
    return;
  }
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    if (!decodedToken) {
      res.status(401).json({ error: "No token" });
      return;
    }
    req.user = decodedToken;
    next();
  } catch (error) {
    res.status(500).json({ error: "An error has occured" });
    return;
  }
}

export { authenticateToken };
