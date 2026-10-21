# Kārya 2.0 — Verification report (2026-10-21)

| Check | Result | Verification |
|---|---|---|
| Original Python reference command tests | PASS (6/6) | `python -m unittest discover -s tests -v` inside extracted Python original |
| SQLite schema / foreign keys / unique constraints / disk persistence | PASS | `python tool/verify_source.py` — 8 source smoke tests |
| Android manifest XML and backup opt-out | PASS (structural) | XML parsed, expected permissions/flags present |
| App store graphics dimensions | PASS | PNG header asserts 512×512 and 1024×500 |
| Source/test Dart bracket-only syntax scan | PASS (lexical; NOT compiler) | Local quote-aware delimiter scanner, not a Dart parser |
| Package pubspec and CI YAML parse | PASS | Python YAML parser |
| `flutter pub get` | NOT RUN | Flutter absent; DNS to pub.dev unavailable |
| `dart format` / `flutter analyze` | NOT RUN | Flutter/Dart absent |
| Flutter unit + widget tests | NOT RUN | Flutter/Dart absent |
| Android test APK | NOT BUILT | Flutter/Android SDK absent; debug artifact not supplied |
| Android signed release AAB | NOT BUILT | Flutter toolchain, publisher confirmation, secure release signing absent |
| Real device reminders, stability, accessibility | NOT TESTED | No emulator or Android device |
| Real Play Store app screenshots | NOT CAPTURED | Requires running app |
| GitHub Actions CI | NOT RUN | Workflow generated only; repository not initialized |
| Play Console publication | NOT STARTED | Requires verified authorized account owner and Play Console action |

These source checks cannot establish Dart type correctness, generated Android scaffold correctness, dependency resolution or runtime behavior. Do not publish without full tests and review.
