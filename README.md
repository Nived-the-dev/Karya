# Kārya (कार्य) — Android source project

**Less Organising. More Doing.**  | Creator: **Nived Chandrasudan**

A native Flutter/Dart port and expansion of the supplied rule-based Python task app. The Android app does **not** run Python, embed a WebView, or need an account, Firebase, an AI API, ads or a server.

> **Build status:** This is a substantial uncompiled source handoff, **not a verified production build**. The authoring environment had no Flutter/Dart SDK, Android SDK, Gradle wrapper JAR, emulator or outbound network to install them. An APK/AAB and genuine screenshots cannot be provided here. See `PROJECT_STATUS.md` and `TEST_RESULTS.md` before attempting distribution.

## Prerequisites

- Recent stable **Flutter supporting Dart 3.12** (also satisfies the notification package minimum Flutter 3.38.1)
- Android Studio and Android SDK Platform **36**, Java **17**
- Android physical device or emulator for real testing
- Internet on your development machine for `flutter pub get` and Gradle

## Quick start

1. Extract the project.
2. Follow `tool/BOOTSTRAP_ANDROID.md` to generate missing Flutter/Gradle wrapper scaffolding **without overwriting this project's Android configuration**.
3. Open the folder in Android Studio or VS Code.
4. In the terminal:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

5. You can instead run `powershell -ExecutionPolicy Bypass -File .\tool\BUILD_KARYA_WINDOWS.ps1` on Windows to perform those development checks and copy the debug APK to `exports/`. The `.github/workflows/android-build.yml` workflow can also run checks and publish the debug APK as an Actions artifact after you place this project in a repository.
6. Open `GOOGLE_PLAY_PUBLISHING_GUIDE.md` for the next stage. Do **not** upload a bundle until package name, Play publisher, policy details, testing, and upload signing have been confirmed.

Run `python tool/verify_source.py` to execute **offline source and SQLite smoke tests** even without Flutter. These do not replace `flutter analyze`, real Flutter tests, or an Android build.

## Project map

- `lib/core/models.dart`: task, subject, habit and date models; historical scheduling
- `lib/core/database.dart`: Drift/SQLite persistence, relational constraints, CRUD and transactions
- `lib/core/commands.dart`: deterministic parsing and help text
- `lib/core/notifications.dart`: local inexact Android notification scheduling
- `lib/core/state.dart`: Riverpod data and theme state
- `lib/features/`: screens, dialogs, neo-brutalist widgets, progress graph, heatmap, chatbot
- `android/`: Android Manifest, Kotlin entrypoint, Gradle templates, privacy/backup and local notifications config
- `test/`, `integration_test/`: Dart/Flutter tests **provided but not yet run**; additional parser/date-history tests are included
- `store_assets/`: app icon and feature graphic; real app screenshots pending; see `tool/SCREENSHOT_CHECKLIST.md`
- `.github/workflows/android-build.yml`: optional cloud CI which attempts Flutter analysis/tests and a debug APK; workflow has **not been run**

## Privacy and data

User content is stored in local SQLite. The app doesn't transmit user-generated information to the developer. The Android manifest is configured to disable cloud/device-transfer backups. Local notification scheduling requires user permission on modern Android; reminder delivery is subject to Android power-management behavior and requires real-device testing.

No JSON export, tracking SDK, login, ads, or generative AI are included. The chatbot supports deterministic commands and should always be described as **rule-based**.

## Release constraints

The package ID `com.karya.studentplanner` is **provisional**. Confirm that it is unused and that it is the final intended ID **before uploading to Play Console**. No signing keys or passwords have been placed in the source. No official NEOKUL affiliation is asserted.

## Caution on future edits

Database schema is version 1. Adding new tables/columns later requires a Drift `onUpgrade` migration and upgrade tests. Local dates are date-only strings and notification instants are local ISO timestamps. Changing app timezone, migrating existing installations or restoring archived habits should be verified on physical devices.

## Kārya 2.1 update (2026-10-21)

The v2.1 source adds five color personalities with black OLED-style dark canvases, Ideas notepad, Brain Dump task preview, subject-first Home, quick task creation, guided tour, page swipes and configurable haptics. See `FEATURES.md` and `PROJECT_STATUS.md` for exact functionality and verification limits.

**Upgrading from Kārya 2.0:** The SQLite schema is migrated from v1 to v2 and preserves existing tasks/habits while creating an `ideas` table. Do not clear app data when updating the APK if you want to retain records. APK updates require the same Android signing identity and application ID.
