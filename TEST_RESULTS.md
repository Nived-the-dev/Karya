# Kārya 2.1 — Test results (2026-10-21)

## Verified
- 8 local Python source/SQLite/Android configuration checks: **passed**.
- Static delimiter consistency of Dart sources checked in local development; this is **not a Dart analyzer or compiler**.

## GitHub Actions 2.1 results — PASSED
GitHub run: `https://github.com/Nived-the-dev/Karya/actions/runs/39611394438`
- `dart format` — passed.
- `flutter analyze --no-fatal-infos` — passed (informational lint hints remain).
- `flutter test test` — **20 passed**, including the task-board dropdown regression test, Ideas database CRUD tests, Brain Dump parser and true-black palette tests.
- `flutter build apk --debug` — passed, APK created.
- GitHub artifact upload — passed.

## Not yet run on 2.1
- Real Android device smoke test of onboarding, editing, notes, haptics, reminders, theme variants and partially held swipes.
- Android v2.0 to v2.1 database migration tested on a real device.
- Google Play signed release app bundle.

## Historical 2.0 result
- 16 Flutter tests and a debug APK built in GitHub Actions, **but a real user found a task-screen dropdown assertion afterward**. This prompted the v2.1 safe subject popup and widget regression test.

See `PROJECT_STATUS.md` for release blockers. Never treat a successful CI compile as proof that every UI route was manually tested on-device.
