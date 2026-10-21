# Kārya — beginner's Android & Google Play publishing guide

This guide is for the finished **verified** build, not a declaration that one already exists. Complete steps in order and return to this checklist after each milestone.

## 1. Install tools and test locally

1. On Windows visit https://docs.flutter.dev/get-started/install and install Flutter. Add Flutter's `bin` folder to your PATH.
2. Install Android Studio from https://developer.android.com/studio. In **SDK Manager**, install Android API **36** and Android SDK Build Tools. Ensure the bundled JDK/Java 17 is in use.
3. Open a terminal in the extracted Kārya Flutter source folder. Follow `tool/BOOTSTRAP_ANDROID.md` to generate Gradle wrapper files without changing the provided project settings.
4. Run `flutter doctor -v`, resolve reported Android SDK/license issues, run `flutter pub get`, then `dart format .`, `flutter analyze`, and `flutter test`.
5. Plug in an Android phone with USB debugging enabled, or create an Android emulator in Android Studio **Device Manager**. Run `flutter devices` then `flutter run`. Test tasks, habits, recurring reminders, both theme modes and offline operation. Correct any reported errors. Use `flutter build apk --debug` to generate a test APK. It normally appears at `build/app/outputs/flutter-apk/app-debug.apk`.
6. Capture **real screenshots** from the working Android emulator/phone, with only real data and implemented UI. Screenshots were not created in the source handoff.

**Android release target:** Starting August 31, 2026, new Play submissions generally need **API 36 or higher**. This source declares target 36; verify the final built bundle. Official reference: https://support.google.com/googleplay/android-developer/answer/11926878

## 2. Publisher account — age and verification

Open https://play.google.com/console/signup. The person who owns the Play developer account must be **at least 18**. Google's documented registration fee is **US$25 once**, subject to local payment/fees. The account holder must accept Google's agreement, complete identity checks and provide their authentic information. If you are not eligible by age, an eligible adult may independently register, own and administer the account. **Do not use fake birth dates, someone else's identification, or shortcuts.** The account owner remains responsible for the application and must make the decisions/submit legal declarations. Official: https://support.google.com/googleplay/android-developer/answer/6112435/

If applicable, the adult publisher should choose a **personal** or **organisation** account based on their real situation and follow Google's verification steps. Account ownership is generally not transferable, so choose carefully.

## 3. Final app identity and signing

The code currently uses **provisional** package ID `com.karya.studentplanner`. The publisher must decide and confirm a unique final ID before the initial Play upload. To change it, update `applicationId` and `namespace` in `android/app/build.gradle.kts`, plus the Kotlin package/directory for `MainActivity.kt`. Changing an app's package name later is not an ordinary update.

On the publisher's **own trusted computer**, generate an upload key, for example using Java's `keytool` (Java 17):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 3072 -validity 10000 -alias upload
```

Set secure passwords. Store multiple secure backup copies of the keystore and passwords; never send them through chat and never commit them to source control. Create `android/key.properties` locally (already gitignored) pointing to the key:

```properties
storeFile=/your/secure/location/upload-keystore.jks
storePassword=YOUR_LOCAL_SECRET
keyPassword=YOUR_LOCAL_SECRET
keyAlias=upload
```

On Windows, escape backslashes in a path, or use forward slashes. Do not include that file in distributed source ZIPs. The release Gradle configuration uses release signing only when a local `key.properties` exists; a bundle produced without it **is not upload ready**.

Run `flutter build appbundle --release`. Verify its success and signing. The expected artifact is `build/app/outputs/bundle/release/app-release.aab`, but only trust a **real build output**. Android App Bundles, not debug APKs, are the normal Play Store release artifacts. Follow Flutter's official documentation: https://docs.flutter.dev/deployment/android

## 4. Create and configure the app in Play Console

Log into the verified publisher account at https://play.google.com/console.

1. Select **Create app** and enter app name **Kārya — Tasks & Habits** (or a confirmed available name), default language, app vs game and free distribution. Complete policy acknowledgements in the account owner's own judgment.
2. Under **Grow users → Store presence → Main store listing** (menu wording can change), copy appropriate descriptions from `PLAY_STORE_LISTING.md`, upload `store_assets/play_icon_512.png` and `store_assets/feature_graphic_1024x500.png`, and upload genuine Android screenshots captured in stage 1.
3. Add truthful public contact information (support email required) and a public HTTPS privacy policy URL. `PRIVACY_POLICY.html` is a **draft**, not already hosted; publish it on a site the account owner controls, fill the publisher contact section, check the mobile in-app statement and verify the URL loads publicly before submitting.
4. Choose **Productivity** and age-appropriate audience based on the actual app and planned users, not for easier approval.

## 5. Complete App content declarations

In Play Console, complete **App content** forms: privacy policy, advertising declaration (**no ads** based on this implementation), content rating, intended audience/target age groups, data safety, permissions and app access. There is no account or login screen. Local user content should stay device-only when the app is correctly built without data-transmitting dependencies. Check the **actual final build and all libraries** before claiming 'no collection' or 'no sharing'. Google explains on-device access vs collection: https://support.google.com/googleplay/answer/11416267

Data handled locally: homework/task titles and descriptions, local due dates, subjects, habit schedules, daily completion logs, display preferences. Permissions: Android 13+ notification permission (optional) and reboot-completed receiver (for local reminders). No Internet permission is declared by the app's main manifest. Android backups are disabled in the manifest, but verify behavior on shipped builds.

Since students, including younger users, may use Kārya, the verified publisher must carefully review all applicable Play Families and audience policies. The publisher is responsible for final declarations and compliance; this template does not guarantee approval.

## 6. Test and request production access

Use **Test and release → Testing → Internal testing** to verify the signed bundle and share it with trusted testers. For a newly created personal developer account (after November 13, 2023), Google currently requires a **closed test with at least 12 opted-in testers for 14 consecutive days** before applying for production access. The Play Console may impose additional account-specific requirements. Testers need to opt in and remain opted in; report bugs and test fixes honestly. Official: https://support.google.com/googleplay/android-developer/answer/14151465

When eligible, the publisher applies for production access and responds truthfully to Google's testing/quality questions. Do not misrepresent testing.

## 7. Production rollout

When the Console shows the app is eligible and all policy forms are complete, navigate to **Test and release → Production → Create new release**. Configure **Play App Signing**, upload the actual **signed AAB**, review errors/warnings, fill release notes from `PLAY_STORE_LISTING.md`, select distribution countries as desired, and ask the verified publisher to review/approve the final submission. Payment, legal declarations, identity checks, and public release are the publisher's responsibility. Publication exists only once Play Console confirms the app is live; processing/review may take time.

## 8. Release updates

For each update, increment the `+versionCode` component of `version:` in `pubspec.yaml` (for example `1.0.1+2`), run full QA, sign using the **same correct upload key**, create the new AAB and upload it through a new Play Console release. Maintain policy compliance, Android target API levels, compatibility, data safety, and privacy text as the app evolves. Keep safe copies of source, keystore and documentation.

### Source links

- Flutter Android release instructions: https://docs.flutter.dev/deployment/android
- Play account requirements & fee: https://support.google.com/googleplay/android-developer/answer/6112435/
- 2026 target API requirements: https://support.google.com/googleplay/android-developer/answer/11926878
- Closed test requirements: https://support.google.com/googleplay/android-developer/answer/14151465
- App Data safety explanations: https://support.google.com/googleplay/answer/11416267
