"""Targeted fixes for Kārya 4.0 ZIP during GitHub Actions builds.

Do not modify any user data. Applies to the temporary checkout after extraction.
"""
from pathlib import Path

settings = Path("lib/features/settings.dart")
src = settings.read_text(encoding="utf-8")
if "import '../core/models.dart';" not in src:
    anchor = "import '../core/state.dart';"
    if anchor not in src:
        raise SystemExit("Cannot find Settings imports; repair manually")
    src = src.replace(anchor, anchor + "\nimport '../core/models.dart';", 1)
    settings.write_text(src, encoding="utf-8")
    print("Imported colorFor() from core/models.dart in Settings")

test = Path("test/progression_test.dart")
src = test.read_text(encoding="utf-8")
before = "final id=await db.saveHabit(name:'Read',days:127);"
after = "await db.saveHabit(name:'Read',days:127);"
if before in src:
    test.write_text(src.replace(before, after, 1), encoding="utf-8")
    print("Removed unused habit ID variable")

print("Kārya 4 source patch applied.")
