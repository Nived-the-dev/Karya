# Google Play release checklist

- [ ] Eligible, verified adult publisher/account owner confirmed (Google Play requires age 18+).
- [ ] Confirm final Android application ID and unique app name before first upload.
- [ ] Flutter / Android Studio / SDK 36 installed, Gradle wrapper generated (see `tool/BUILD_KARYA_WINDOWS.ps1` or CI).
- [ ] Dependencies resolved, formatting/analyze/tests clean.
- [ ] Launch Android app on real device/emulator; verify core CRUD and offline access.
- [ ] Verify real reminders after reboot, app termination, timezone change and permission denial.
- [ ] Verify dark/light mode, talkback, large text and small-screen layout.
- [ ] Verify settings delete data, reinstall, Android backup behavior.
- [ ] Have publisher independently generate/upload-key, back it up in safe storage and configure ignored `android/key.properties`.
- [ ] Build signed **release** Android App Bundle; verify signing and target API 36.
- [ ] Host reviewed HTML privacy policy with a genuine support email on public HTTPS URL and use that link in-app and in Console if required.
- [ ] Re-check Google Play policies and complete Data Safety, content rating, target audience, ads, permissions and app access questionnaires truthfully.
- [ ] Capture real screenshots from Android and produce supported aspect ratios/sizes.
- [ ] Upload store icon, feature graphic, real screenshots, descriptions, contact, release notes.
- [ ] Use internal testing, followed by applicable closed-testing requirements.
- [ ] Address test issues and request production eligibility when permitted.
- [ ] Submit final production release and await actual Play Console confirmation.

A simulated app picture is not a valid substitute for a real screenshot. This checklist does not assert publication.
