# Real screenshot capture checklist — requires a running Android build

Do not substitute promotional mockups for screenshots of the app. After the app builds, connect a real Android device or launch an emulator with a modern supported resolution. Add genuine sample tasks and habit check-ins through the UI and capture the Home, Tasks, Habits, Progress, and command-assistant screens. Screenshots must reflect working implemented features, and avoid showing personal messages or other private content. Keep readable typography and demonstrate both default colors and progress history.

On a Windows PowerShell terminal with Android SDK tools in PATH:

```powershell
adb devices
adb shell am force-stop com.karya.studentplanner
# Start Kārya by tapping its icon; open the desired screen.
adb exec-out screencap -p > home.png
```

For reliable PNG output on Windows, prefer Android Studio's **Running Devices > Screenshot** UI, or run `adb shell screencap -p /sdcard/karya.png` followed by `adb pull /sdcard/karya.png home.png`. Repeat on each screen, ensure images are actual app screens, remove test records if they expose personal details, and check screenshot sizes/quality in Play Console. The screenshot set is intentionally NOT included in the current store asset package because no Android runtime was available for capture.
