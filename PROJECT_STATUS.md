# Kārya 2.0 — Project status (revised 2026-10-21)

**Status: source refined; Android compile/test and publication NOT verified.**

## Implemented or improved in source
- Flutter UI for tasks, subjects, subtasks, habits, progress graph, heatmap, command assistant and settings; neo-brutalist branding
- Task subject-folder navigation now opens its own filtered task list
- Live subtask check-off/create/delete without closing the details sheet
- Strict command-date parsing, safer calendar-day arithmetic and archive-history ordering
- Settings clear-data now clears application preferences as well as SQLite records; reminder queue is synchronized
- Local SQLite/Drift schema, real 7-day task completion history graph, optional task/habit reminder defaults, Flutter tests and a repeatable offline source-check suite
- Android API 36 configuration, notification permission/reboot receiver, backup opt-out, artwork, privacy draft, store text and publishing guide
- Optional GitHub Actions `android-build.yml` and Windows one-command build verifier

## Verification evidence
- 6/6 original Python reference tests passed
- 8/8 offline source and SQLite smoke tests passed (including real SQLite constraints/file re-open)
- XML and package YAML parsed; all Dart source files passed bracket-only lexical balance scan
- Launcher and feature artwork have the specified pixel dimensions

## Not verified / critical next checks
- Flutter/Dart SDK is **not installed here**; direct downloads to Flutter hosts fail DNS resolution
- `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`, Android APK/AAB build and emulator tests **not run**
- GitHub Actions workflow authored but **not run**; cannot claim an APK will compile without CI result
- Reminder permissions, reboot/timezone behavior, screen-reader usability, crash-free run, and real app screenshots require Android testing
- App ID `com.karya.studentplanner` is provisional; no signing key supplied or generated
- Live privacy URL, contact info, verified Play publisher, final policy forms and review are pending

**Next action:** Use the Windows build verifier on a Flutter/Android Studio machine, or run the supplied GitHub Actions CI after adding the source to a repository. Resolve any compilation or runtime errors before treating Kārya as releasable.
