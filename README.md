# Powerdrive Learning — Flutter Mobile App

Mobile application for Powerdrive driving school students ([lernen.powerdrive.at/dashboard](https://lernen.powerdrive.at/dashboard)).

## Project Overview

This mobile application provides Powerdrive driving school students with a mobile-first learning companion, featuring Leitner-spaced repetition study modules, question lookup, preliminary examination checks, timed mock exam simulations, historical score audits, and visual learning analytics.

The app is currently configured for a comprehensive offline static demonstration, using modular mock repositories that strictly adhere to clean architecture repository contracts.

---

## Implementation Status

- **Phase 1: Foundation, Theme & Navigation Shell** — ✅ Completed & Verified.
- **Phase 2: Domain Models & Repository Abstractions** — ✅ Completed & Verified.
- **Phase 3: Dashboard Screen** — ✅ Completed & Verified.
- **Phase 4: Learning Module & Question Lookup** — ✅ Completed & Verified.
- **Phase 5: Preliminary Check, Mock Exam Flow & Exam History** — ✅ Completed & Verified.
  - See `docs/PHASE_5_SPECIFICATION.md`.
- **Phase 6: Progress Dashboard and Learning Analytics** — ✅ Completed & Verified.
  - See `docs/PHASE_6_SPECIFICATION.md`.
- **Phase 7: Full Application Audit, UI Consistency & Backend Readiness** — ✅ Completed & Verified.
  - See `docs/BACKEND_INTEGRATION_READINESS.md`.
- **Phase 8: Powerdrive Learning Static Demo Finalization** — ✅ Completed & Verified.
  - See `docs/DEMO_HANDOFF.md` for the complete demo walkthrough script, screen inventory, and testing guide.

---

## Architecture & Documentation

- [Project Architecture & Directory Structure](docs/PROJECT_ARCHITECTURE.md)
- [Backend Integration Readiness & API Contracts](docs/BACKEND_INTEGRATION_READINESS.md)
- [Demonstration Handoff Guide](docs/DEMO_HANDOFF.md)

---

## Running Tests & Static Analysis

Ensure you run commands from the Flutter project directory:

```bash
# Check code formatting
dart format lib test

# Run static analysis
flutter analyze

# Execute all unit and widget tests
flutter test
```

---

## Building and Running on Android

### Connected Physical Device
```bash
# Check connected devices
flutter devices

# Run in debug mode on connected device
flutter run -d RMX3998
```

### Building the Debug APK
```bash
flutter build apk --debug
```
Binary output:
`build/app/outputs/flutter-apk/app-debug.apk`
