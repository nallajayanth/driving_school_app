# Powerdrive Learning — Static Demo Handoff Guide

## 1. Executive Summary

This document provides a comprehensive overview and testing guide for the **Powerdrive Learning** Flutter mobile application offline demonstration. The application replicates the learning and exam simulation experience of the Powerdrive driving school portal ([lernen.powerdrive.at](https://lernen.powerdrive.at/dashboard)), faithfully adopting its brand identity, typography, navigation hierarchy, Leitner study box mechanics, and examination simulations.

The current version operates entirely offline using cleanly abstracted in-memory mock repositories. It requires no network connection, makes no backend API calls, and is fully ready for testing on Android physical devices and presentation to stakeholders.

---

## 2. Complete Screen Inventory

| Screen Name | Route Path | Primary Purpose & Key Features |
| :--- | :--- | :--- |
| **Dashboard** | `/dashboard` | Main hub featuring the student welcome greeting, quick exam shortcuts, Leitner box summary cards (Box 0, Subject 1–3), progress counters, and pedagogical study tips. |
| **Learning Overview** | `/learning` | Curated curriculum view grouped by driving class (GW - General Knowledge, B - Car). Displays topic cards, question counters, exam readiness indicators, and Leitner status distribution. |
| **Question Lookup & Detail** | `/learning/question/:id` | Dedicated study screen for individual questions (e.g. #1278). Features question text, Austrian traffic diagram illustration, multiple choice options, immediate feedback, and Leitner box promotion/demotion. |
| **Preliminary Check Selection** | `/preliminary` | Exam setup screen allowing candidates to select their driving licence class (GW 40 questions, B 40 questions, or Combined 80 questions) with dynamic total calculation and rules summary. |
| **Mock Examination Runner** | `/exam/runner` | Timed, distraction-free examination interface. Includes question index navigation bar, answer selection, bookmarking, and bounded completion confirmation modal. |
| **Mock Exam Result** | `/exam/result` | Post-exam score breakdown showing pass/fail status, percentage score, points achieved vs required, detailed answer review list, and retry/history shortcuts. |
| **Preliminary Exam History** | `/exam/history` | Historical audit screen displaying previous exam attempts, chronological performance trend chart (`fl_chart`), score cards, and in-memory test persistence. |
| **Progress & Analytics** | `/progress` | Comprehensive learning analytics dashboard featuring overall questions studied (`6`), milestone rank (`Beginner 🐣`), interactive Leitner box distribution chart, and topic-level mastery cards. |

---

## 3. End-to-End User Journey Walkthrough (Demonstration Script)

Follow these sequential steps to demonstrate the complete student workflow on an Android device:

### Step 1: Launch & Dashboard Inspection
1. Launch **Powerdrive Learning** from the device launcher.
2. Confirm the top header displays the Powerdrive logo, student greeting (`Max Mustermann`), language selector (`DE / EN`), and logout action.
3. Observe the **Practice exam questions** quick action card, **Start preliminary check** button, and **Preliminary audit statistics** link.
4. Review the 4 Leitner system cards:
   - **Box 0**: Unseen / incorrectly answered questions.
   - **Subject 1 (Fach 1)**: First repetition stage.
   - **Subject 2 (Fach 2)**: Consolidation stage.
   - **Subject 3 (Fach 3)**: Exam-ready mastered questions.
5. Tap **View Exam History** or the statistics shortcut to view the audit graph.

### Step 2: Exploring Curriculum & Question Search
6. Tap the **Learning** item in the bottom navigation bar (`/learning`).
7. Switch between the **GW (Grundwissen)** and **B (PKW)** tabs.
8. Locate the question search bar at the top: enter `1278` and tap **Call** or submit keyboard.
9. Observe navigation to the Question Detail screen for Question #1278 (*Vorrang beim Einbiegen*).
10. Examine the question diagram illustration and answer choices.
11. Select an answer choice to observe the feedback mechanism and Leitner status update.
12. Use the back arrow to return to the Learning overview.

### Step 3: Configuring & Starting a Preliminary Check
13. Tap **Preliminary Check** in the bottom navigation bar (`/preliminary`).
14. Observe the default selection (GW: 40 questions).
15. Tap the **Class B (PKW)** tile to toggle it ON. Confirm the dynamic calculation updates to 80 questions and 60 minutes.
16. Tap **Start Preliminary Examination** to initiate the mock exam session.

### Step 4: Taking the Mock Examination
17. In the Mock Examination Runner (`/exam/runner`), note the countdown timer and question navigator pill bar.
18. Answer Question 1 by tapping an answer option.
19. Tap **Next** to advance through subsequent questions.
20. Tap **Submit Exam**; confirm the confirmation dialog warns of any unanswered questions before submitting.

### Step 5: Reviewing Exam Results & History
21. Upon submission, view the **Mock Exam Result** screen (`/exam/result`).
22. Review the score badge (e.g. 92% Passed / 68% Failed depending on answers chosen).
23. Tap **View Audit Statistics** to navigate directly to the **Preliminary Exam History** (`/exam/history`).
24. Verify the newly submitted exam attempt appears in the attempt list and is plotted on the performance trend line.

### Step 6: Learning Analytics & Language Switch
25. Tap **Progress** in the bottom navigation bar (`/progress`).
26. View the total questions studied counter (`6`), current milestone badge (`Beginner 🐣`), and touch the Leitner bar chart rods to view interactive question count tooltips.
27. Tap the language selector in the top header and switch from **DE** to **EN**; observe localized interface text.
28. Tap the logout icon in the header to confirm the session logout confirmation modal.

---

## 4. Mock Data Assumptions & Current Limitations

| Component | Current Static / Mock Implementation | Production Backend Expectation |
| :--- | :--- | :--- |
| **Authentication & Profile** | Hardcoded mock student (`Max Mustermann`, ID `usr_demo_01`) via `MockAuthRepository`. | OAuth2 / JWT bearer token exchange with driving school CMS (`lernen.powerdrive.at/api/v1/auth`). |
| **Persistence Scope** | In-memory session persistence. Any new exam attempts or answered questions persist while the app is running, but reset upon cold app restart. | Persistent cloud storage via REST API and local SQLite / Hive offline sync engine. |
| **Question Catalog** | Curated sample question set representing Austrian BMK categories (GW, B) with traffic diagrams. | Complete official Austrian Ministry catalogue (~3,000 active questions, multi-lingual, categorized by license classes A, B, C, D, E, F). |
| **Media Assets** | High-contrast vector placeholders and local asset diagrams representing typical Austrian traffic situations. | CDN-hosted high-resolution SVGs, animations, and situational video clips. |
| **Scoring Algorithm** | 80% passing threshold with point weightings per question category. | Official Austrian driving test algorithm including sub-question validation, dual-checkbox penalties, and category-weighted scores. |

---

## 5. Build, Run, and Test Instructions

### Prerequisites
- Flutter SDK 3.38+ / Dart 3.10+
- Android Studio / Android SDK Platform-Tools (`adb`)
- Connected Android device (e.g., Realme `RMX3998`) or Android Emulator

### Running Static Analysis & Test Suite
From the project root (`driving_school_mobile_app`):

```bash
# Verify formatting
dart format lib test

# Run static analysis
flutter analyze

# Execute all unit and widget tests
flutter test
```

### Running on a Connected Android Phone
```bash
# List connected devices
flutter devices

# Run in debug mode on connected device
flutter run -d RMX3998
```

### Building the Debug APK
```bash
flutter build apk --debug
```
**Output binary:**
`build/app/outputs/flutter-apk/app-debug.apk`

To install directly via ADB:
```bash
adb -s CA4T8DTCKFYH6TV4 install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## 6. Backend Integration Readiness

The application has been engineered following clean architecture and the repository pattern:
- UI widgets depend exclusively on Riverpod providers (`authProviders`, `learningProviders`, `examProviders`, `progressProviders`).
- All providers interface with pure abstract contracts (`AuthRepository`, `LearningRepository`, `ExamRepository`, `ProgressRepository`).
- Switching to live backend APIs requires only implementing the production repositories (`HttpAuthRepository`, `HttpLearningRepository`, etc.) and updating provider overrides in `lib/core/providers/api_providers.dart`. No UI widgets or route configurations require modification.
- For complete payload schemas, endpoint specifications, and migration checklists, refer to [`docs/BACKEND_INTEGRATION_READINESS.md`](file:///d:/Projects/Arshina_IoT_solutions/driving_school_app/driving_school_mobile_app/docs/BACKEND_INTEGRATION_READINESS.md).
