#!/usr/bin/env python3
"""Apply narrow repairs to the archived Kārya source before CI checks.

The ZIP stored in the GitHub repository contains the original editable source.
These fixes are applied only to the temporary checkout for an APK build.
"""
from pathlib import Path

def replace_exact(path: str, before: str, after: str):
    p = Path(path)
    text = p.read_text(encoding="utf-8")
    if before not in text:
        if after in text:
            print(f"{path}: fix already applied")
            return
        raise SystemExit(f"Expected source snippet missing from {path}")
    p.write_text(text.replace(before, after, 1), encoding="utf-8")
    print(f"{path}: patched")

# A compile error: a const Row cannot contain a collection-for element.
replace_exact(
    "lib/features/progress.dart",
    "const Row(children:[for(final s in",
    "Row(children:[for(final s in",
)
# Clean up the sample-data tests without changing the actual assertions.
replace_exact(
    "test/database_test.dart",
    "import 'package:karya_app/core/models.dart';\n",
    "",
)
replace_exact(
    "test/logic_test.dart",
    "final logs=<String>{'2026-10-21','2026-10-21'};",
    "final logs=<String>{'2026-10-21'};\n    logs.add('2026-10-21');",
)

# flutter create generates a default widget_test.dart referencing MyApp, which
# the Kārya application does not define. Kārya has its own widgets_test.dart.
default_test = Path("test/widget_test.dart")
if default_test.is_file() and "MyApp" in default_test.read_text(encoding="utf-8"):
    default_test.unlink()
    print("Removed incompatible Flutter template widget test")

# Flutter 3.47 requires Gradle 8.14 or later for Android builds.
# Keep Android Gradle Plugin 8.11.1 (configured in settings.gradle.kts).
wrapper = Path("android/gradle/wrapper/gradle-wrapper.properties")
wrapper_text = wrapper.read_text(encoding="utf-8")
if "gradle-8.13-bin.zip" in wrapper_text:
    wrapper.write_text(
        wrapper_text.replace("gradle-8.13-bin.zip", "gradle-8.14-bin.zip"),
        encoding="utf-8",
    )
    print("Updated Android Gradle wrapper to 8.14")
elif "gradle-8.14-bin.zip" in wrapper_text:
    print("Android Gradle wrapper already targets 8.14")
else:
    raise SystemExit("Unexpected Android Gradle wrapper version")
