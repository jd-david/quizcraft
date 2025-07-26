# QuizCraft

QuizCraft is a mobile application built with Flutter for the frontend and a Node.js backend. It's designed as a mini-project for a CS degree, showcasing a full-stack application with Firebase integration.

## 📜 Description

QuizCraft is a mobile application that helps students study by converting lecture materials into interactive quizzes. It uses Natural Language Processing (NLP) to analyze uploaded text and automatically generate questions that test understanding.

Effective learning from lecture materials often extends beyond passive reading and note-taking. Students frequently face challenges in actively engaging with content, identifying key concepts for self-assessment, and efficiently preparing for examinations. Traditional study methods, while valuable, can be time-consuming and may not always facilitate the proven benefits of active recall and self-testing. While digital study tools exist, there's a distinct need for a mobile-first solution that seamlessly transforms personal lecture materials into customized learning aids, empowering students to study smarter, not just harder.

## ✨ Features

*   **User Authentication:** Secure user sign-up and login using Firebase Authentication.
*   **Quiz Management:** Create, read, update, and delete quizzes.
*   **Question Handling:** Add various types of questions to quizzes (multiple choice, true/false, etc.).
*   **Quiz Participation:** Users can take quizzes and view their scores.
*   **File Uploads:** Supports file uploads for quiz content, potentially including images or documents.
*   **AI-Powered Content Generation:** The backend uses Genkit with Google AI, which suggests AI-powered features for quiz and question generation.

## 📸 Screenshots

(Add screenshots of the mobile app here. You can replace these placeholders with your actual screenshots.)

| Light Mode | Dark Mode |
| :---: | :---: |
| ![Light Mode Screenshot 1](https://via.placeholder.com/300x600.png?text=Light+Mode+Screen+1) | ![Dark Mode Screenshot 1](https://via.placeholder.com/300x600.png?text=Dark+Mode+Screen+1) |
| ![Light Mode Screenshot 2](https://via.placeholder.com/300x600.png?text=Light+Mode+Screen+2) | ![Dark Mode Screenshot 2](https://via.placeholder.com/300x600.png?text=Dark+Mode+Screen+2) |

## 🛠️ Tech Stack

### Frontend (Mobile App)

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Language:** [Dart](https://dart.dev/)
*   **State Management:** [Provider](https://pub.dev/packages/provider)
*   **Firebase:**
    *   Firebase Core
    *   Firebase Authentication
    *   Cloud Firestore
    *   Firebase Storage
*   **UI:**
    *   [Google Fonts](https://pub.dev/packages/google_fonts)
    *   [Shimmer](https://pub.dev/packages/shimmer) (for loading effects)
    *   [Confetti](https://pub.dev/packages/confetti) (for animations)
*   **Utilities:**
    *   [http](https://pub.dev/packages/http) (for API requests)
    *   [intl](https://pub.dev/packages/intl) (for internationalization)
    *   [file_picker](https://pub.dev/packages/file_picker)
    *   [image_picker](https://pub.dev/packages/image_picker)
    *   [flutter_dotenv](https://pub.dev/packages/flutter_dotenv)

### Backend

*   **Framework:** [Express.js](https://expressjs.com/)
*   **Language:** [TypeScript](https://www.typescriptlang.org/)
*   **Runtime:** [Node.js](https://nodejs.org/)
*   **Database:** [Cloud Firestore](https://firebase.google.com/docs/firestore) (via `firebase-admin`)
*   **AI:**
    *   [Genkit](https://firebase.google.com/docs/genkit)
    *   [Google AI](https://ai.google/)
*   **API & Middleware:**
    *   [cors](https://pub.dev/packages/cors)
    *   [axios](https://pub.dev/packages/axios)
*   **File Handling:**
    *   [mammoth](https://www.npmjs.com/package/mammoth) (for .docx files)
    *   [pdf-parse](https://www.npmjs.com/package/pdf-parse)
    *   [tesseract.js](https://tesseract.projectnaptha.com/) (for OCR)
*   **Development:**
    *   [nodemon](https://nodemon.io/)
    *   [ts-node](https://www.npmjs.com/package/ts-node)

## 🚀 Getting Started

### Prerequisites

*   Flutter SDK
*   Node.js and npm
*   A Firebase project

### Frontend Setup

1.  **Clone the repository:**
    ```bash
    git clone <your-repo-url>
    cd quizcraft
    ```
2.  **Set up Firebase:**
    *   Complete the FlutterFire setup by following the [official documentation](https://firebase.google.com/docs/flutter/setup).
    *   Place your `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) in the appropriate directories.
3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Create a `.env` file** in the root of the Flutter project and add any necessary environment variables.
5.  **Run the app:**
    ```bash
    flutter run
    ```

### Backend Setup

1.  **Navigate to the backend directory:**
    ```bash
    cd quizcraft-backend
    ```
2.  **Install dependencies:**
    ```bash
    npm install
    ```
3.  **Set up Firebase Admin:**
    *   Go to your Firebase project settings and generate a new private key for the service account.
    *   Save the JSON file and set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to the path of this file.
4.  **Create a `.env` file** in the `quizcraft-backend` directory and add your environment variables (e.g., `PORT`, Firebase configuration).
5.  **Build and run the server:**
    *   **Development:** `npm run dev`
    *   **Production:** `npm run build` followed by `npm run start`
