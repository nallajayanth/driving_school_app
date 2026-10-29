# Powerdrive Learning — Architecture & Data Documentation

This document records the system architecture, domain models, confirmed platform requirements, verified mock datasets, and pending backend integration gaps.

---

## 1. Confirmed Platform Requirements (Observed from Platform & PRD)

- **Platform Navigation:**
  - 4 primary destinations: **Dashboard**, **Learning**, **Preliminary Check**, **Progress**.
  - Top header: Brand banner ("FAHRSCHULE Powerdrive www.powerdrive.at"), language selector (`DE` / `EN`), and `Log out` action.
  - Secondary screens: **Preliminary Audit Statistics** (accessible from Dashboard quick actions and history navigation).

- **Dashboard:**
  - Personalized welcome message: *"Welcome, [User Name] ! It's great to have you here! Choose how you would like to continue:"*.
  - 3 primary action shortcuts: `Practice exam questions`, `Start preliminary check`, `Preliminary audit statistics`.
  - Learning progress section with distinct status cards:
    - **Box 0:** "1426 questions", "New or not correct 🔄".
    - **Subject 1:** "2 questions", "1x correct 👍".
    - **Subject 2:** "0 questions", "Correct twice in a row 💪".
    - **Subject 3:** "0 questions", "Ready for the exam ✅".
  - Hint: *"Tip: You can switch to the pre-test at any time to test your progress!"*.

- **Learning Module:**
  - Top search field: *"Question number: [ e.g. 1278 ] [ 🔍 Call ]"*.
  - Driving class grouping (e.g. `🧠 GW`).
  - Unit / Topic cards displaying:
    - Title & category (e.g. "General rules of the road, tunnel" in "General traffic regulations, tunnels").
    - Readiness fraction (e.g. "0 / 92 Exam-ready").
    - Progress bar.
    - Status counters: `🔄 90`, `👍 2`, `💪 0`, `✅ 0`.
    - Phase badge: `1% · Start-up phase 🚦`.

- **Preliminary Check:**
  - Selection interface with checkboxes for eligible driving classes:
    - `[ ] GW (40 questions)`
    - `[ ] B (40 questions)`
  - Total question count indicator: *"👁 Total: [N] questions (including bonus questions)"*.
  - Action button: `🚀 Start preliminary check` (enabled only when one or more classes are selected).

- **Progress Module:**
  - Summary: Total questions answered (e.g. 6 questions), Learning level badge (e.g. `Beginner 🐣`).
  - Distribution chart: "Distribution by subject level" ("Verteilung nach Fachstufe") for Fach 0, Fach 1, Fach 2, Fach 3.
  - Topic progress list: Completion percentage per topic.

---

## 2. Explicit Distinctions Maintained

1. **Box 0 vs. Subject Cards (Fach 0..3):**
   - The platform separates **Box 0** ("New or not correct") from **Subject 1** ("1x correct"), **Subject 2** ("Correct twice in a row"), and **Subject 3** ("Ready for the exam").
   - These are not conflated into arbitrary custom categories. The domain models reflect both the dashboard card counters and the progress chart metrics.

2. **Driving Classes:**
   - Currently confirmed classes are `GW` (Grundwissen) and `B` (Klasse B). The data layer supports dynamic catalogs rather than hardcoded enums, allowing future classes (e.g. A, C) without breaking changes.

---

## 3. Mock Data vs. Production Integration Gaps

| Area | Current Mock Implementation | Production Backend Gaps / Questions to Discover |
| :--- | :--- | :--- |
| **Authentication** | `MockAuthRepository` with local session for Krishan Patel. | Auth protocol (OAuth2, JWT bearer tokens, cookie sessions), token refresh endpoints, password management. |
| **Curriculum Catalog** | `MockLearningRepository` with GW sample units matching screenshots. | Full question bank API, media delivery CDN / asset URLs, question categorization taxonomy. |
| **Question Flow** | Question model supports multiple-choice options with lookup by number. | Exact question submission API, immediate vs. deferred answer feedback, negative scoring rules, bonus question triggering rules. |
| **Preliminary Check** | `MockExamRepository` with GW (40) and B (40) calculation. | Exam runner API, time limits, question randomization, submission persistence, passing grade percentage criteria. |
| **Progress Metrics** | `MockProgressRepository` with 6 answered questions, Beginner level. | Progress calculation engine, Leitner box transition rules, server-side sync mechanism. |

---

## 4. Repository Abstraction Pattern

All presentation widgets and Riverpod providers depend solely on the abstract interfaces:
- `AuthRepository` (`lib/features/authentication/data/auth_repository.dart`)
- `LearningRepository` (`lib/features/learning/data/learning_repository.dart`)
- `ExamRepository` (`lib/features/exam_history/data/exam_repository.dart`)
- `ProgressRepository` (`lib/features/progress/data/progress_repository.dart`)

When backend endpoints are supplied, production implementations (`HttpAuthRepository`, `HttpLearningRepository`, etc.) can be swapped in via Riverpod dependency injection with zero modifications to domain models or UI components.
