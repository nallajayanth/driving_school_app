# Phase 6 — Progress Dashboard and Learning Analytics

This document details the architecture, design components, mock data definitions, and backend integration requirements for the Progress Dashboard implemented in Phase 6 of the Powerdrive Learning mobile app.

---

## 1. Implemented Screens and Components

### A. Progress Screen (`ProgressScreen`)
- **Route:** `/progress` (accessible via the primary bottom navigation tab).
- **Header:** Powerdrive brand app bar with language selection dropdown.
- **Top Notice Banner:** Development mode badge indicating local mock analytics.
- **Title & Description:** 
  - Headline: `Learning progress`.
  - Subtitle: Clear summary of the screen's purpose to track overall questions, milestone level, Leitner distribution, and topic mastery.
- **Pull-to-Refresh:** Wrapped in `RefreshIndicator`, invoking `ProgressNotifier.refresh()` via `learningProgressProvider`.
- **Loading, Error & Retry States:** Comprehensive async handling with retry button on failure.

### B. Overall Learning Statistics Block
- Two responsive metric cards with adaptive breakpoint (`LayoutBuilder` switching between row and column at $280\text{px}$):
  1. **Questions Answered Card:**
     - Metric: `6` questions studied.
     - Tag: `STUDIED` with notebook icon.
     - Subtitle: `Questions answered`.
  2. **Learning Level Card:**
     - Milestone rank: `Beginner 🐣`.
     - Tag: `LEVEL`.
     - Subtitle: `Milestone rank`.
- **Empty State Tip:** If `totalQuestionsAnswered == 0`, provides an encouraging onboarding hint to practice questions in the Learning tab.

### C. Distribution by Subject Level (`SubjectDistributionChart`)
- **Headline:** `Distribution by subject level` (*Verteilung nach Fachstufe*).
- **Subtitle:** `Leitner distribution across study boxes (Fach 0 – 3)`.
- **`fl_chart` BarChart:**
  - 4 colored vertical rods:
    - **Fach 0:** `#0284C7` (Cyan) $\rightarrow 60\%$
    - **Fach 1:** `#F59E0B` (Amber) $\rightarrow 40\%$
    - **Fach 2:** `#EA580C` (Warm Orange) $\rightarrow 0\%$
    - **Fach 3:** `#10B981` (Emerald) $\rightarrow 0\%$
  - Left axis: $0\%$, $25\%$, $50\%$, $75\%$, $100\%$.
  - Bottom axis: `Fach 0`, `Fach 1`, `Fach 2`, `Fach 3`.
  - Interactive tooltip on bar tap.
- **Adaptive 4-Item Legend Grid:**
  - Responsive layout (stacks into 1-column on narrow widths $< 280\text{px}$, 2x2 grid on standard phone widths).
  - Displays percentage, question counts (e.g. `1426 questions` in Box 0, `2 questions` in Subject 1), and status descriptions (`New / not correct`, `1x correct`, `2x in a row`, `Ready for exam`).
- **Footnote:** Explains that telemetry values reflect mock data and production formulas will be mapped once confirmed.

### D. Progress per Topic (`TopicProgressCard`)
- **Headline:** `Progress per topic`.
- **Topic Cards:**
  - `General rules of the road, tunnel`: `1.0%` exam ready, `2 / 92` answered, `0` exam ready.
  - `Special traffic areas`: `0.0%`, `0 / 56` answered, `0` exam ready.
  - `Moving through traffic`: `0.0%`, `0 / 46` answered, `0` exam ready.
- **Tapping a topic:** Navigates directly to the `/learning` module.
- **Empty State:** Clean placeholder if no topics exist.

---

## 2. Mock Data Definitions & Verified vs. Unverified Rules

| Metric | Source Value | Status | Description |
| :--- | :--- | :--- | :--- |
| `totalQuestionsAnswered` | 6 | **Verified from screenshot** | Questions answered by Krishna Patel on web dashboard. |
| `currentLearningLevel` | Beginner 🐣 | **Verified from screenshot** | User milestone rank. Progression thresholds to higher levels (e.g. Advanced, Expert) require backend confirmation. |
| `box0QuestionsCount` | 1426 | **Verified from screenshot** | Questions currently in Box 0 ("New or not correct 🔄"). |
| `subject1QuestionsCount` | 2 | **Verified from screenshot** | Questions in Subject 1 ("1x correct 👍"). |
| `subject2QuestionsCount` | 0 | **Verified from screenshot** | Questions in Subject 2 ("Correct twice in a row 💪"). |
| `subject3QuestionsCount` | 0 | **Verified from screenshot** | Questions in Subject 3 ("Ready for the exam ✅"). |
| `fach0Value` / `fach1Value` | 60% / 40% | **Mock Telemetry** | Derived from visible chart distribution. Transition mechanics require backend confirmation. |
| `progressPercentage` | 1.0% | **Mock Telemetry** | Ratio of exam-ready questions to total questions per topic. |

---

## 3. Consistency with Dashboard and Learning Module

- **Box 0 vs. Subject 1–3 Distinction:** The Progress screen strictly respects the separation established in Phase 2 and 3. Box 0 represents new or missed questions; Subjects 1–3 represent successive correct answer levels.
- **Numeric Alignment:** Both the Dashboard and Progress screen read from the unified `learningProgressProvider` and `progressRepositoryProvider`. A change in repository state simultaneously updates both screens.

---

## 4. Future Backend Integration Requirements

When connecting to the live Powerdrive API:
1. **Endpoint `GET /api/user/learning-progress`:**
   - Must return total answered count, current rank/level title and icon.
   - Must return question distribution across Box 0, Subject 1, Subject 2, and Subject 3.
   - Must return percentage distribution across Fach 0 through 3.
2. **Endpoint `GET /api/user/topic-progress`:**
   - Must return an array of topics with `totalQuestions`, `answeredQuestions`, `examReadyQuestions`, and `progressPercentage`.
3. **Leitner Engine Documentation:**
   - Detailed specification of question transitions (e.g., does answering incorrectly in Subject 2 return a question to Box 0 or Subject 1?).
