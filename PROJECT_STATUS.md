# Kārya 2.1 — Project status

## Implemented in source
- Replaced the crash-prone subject dropdown with safe popup selectors. Added regression widget test.
- Five personalities (Classic, Soft Pop, Monochrome, Forest, Lavender Haze), each with Light, Dark, or System brightness. All dark themes use **#000000** app canvases.
- Subject-first Home with colored folders, live open-task counts, and add/manage shortcuts.
- Quick one-field task creation; optional subject/date/priority/reminder details.
- Five swipeable tabs (Home, Tasks, Habits, Ideas, Progress) with finger-following PageView and animated navigation indicator.
- Haptic feedback and card presses, adjustable haptics/reduced motion.
- First-launch guided tour with skip and replay from Settings.
- Offline Brain Dump (suggestions + explicit review before saving) while retaining advanced command assistant. No AI API is advertised or called.
- Ideas notepad with SQLite persistence, pinned notes, search, autosave, and convert-to-task.
- About story written with requested language and authentic GitHub/LinkedIn links.
- Offline-first and ad-free; no accounts or tracking SDKs.
- Database schema upgraded to version 2; migration preserves v1 tasks, subjects, habits.
- App version 2.1.0+2, Gradle 8.14, Kotlin 2.2.20.

## Verification
- The readable Flutter source is committed directly in GitHub (`lib/`, `android/`, `assets/`, `test/`, `integration_test/`), and the source-promotion workflow passed on 2026-10-21.
- Offline Python/SQLite/Android configuration checks: 8 passed (2026-10-21).
- GitHub Actions Kārya 2.1 run #39611394438: Dart analysis passed, 20 Flutter tests passed, Android debug APK built and uploaded successfully.
- Device installation and interactive manual smoke test: **not yet performed**. Source checks, Dart analysis, Flutter tests, and debug APK build passed in CI.
- Earlier Kārya 2.0 had 16 passing Flutter tests and an installable debug APK, but Android real-world testing identified a dropdown assertion.

## Next actions
1. Install the verified Kārya 2.1 debug APK and manually verify onboarding, tab swipes, subject selection, notes, habits, reminders, appearance, and persistence on Android.
2. Only then prepare a signed release bundle using the authorized publisher's retained upload key and complete the Google Play requirements. Do not use a debug APK for Play release.
