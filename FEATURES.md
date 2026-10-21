# Feature inventory — source implementation, pending Android verification

| Feature | Source implementation | Verification |
|---|---|---|
| Home, Tasks, Habits, Progress tabs | Flutter navigation and screens | Not run |
| Add/edit/complete/reopen/delete/search/filter/sort tasks | Drift CRUD, UI | Not run |
| Priorities, due dates & times, optional reminder | Forms and database | Not run |
| Subject folders: add, edit, delete, colors/icons | CRUD and UI | Not run |
| Subtasks, task duplicate | Database and detail sheet | Not run |
| Habits: daily/selected weekdays, history and archive | SQL schedules/status revisions and UI | Not run |
| Check off habits and undo, uniqueness | SQL primary key and set display | SQL constraint checked independently |
| 7-day bar chart & monthly calendar heatmap | Data-driven Flutter widgets | Not run |
| Rule-based chatbot commands & direct task-entry syntax | Dart parser + database command flow | Not run |
| Light/dark/follow-system mode | Theme controller using preferences | Not run |
| Local reminders: permission, edit/reschedule, reboot | Plugin configuration and scheduling | Needs device testing |
| In-app privacy, licenses, clear all local records | Settings UI | Not run |
| Play icon & feature graphic | Original files provided | Pixel dimensions verified |
| Real screenshots, verified APK, signed AAB | Not produced | Blocked by SDK/device/signing |

The source has no user-facing JSON import/export. Historical habit schedule revisions and active/inactive state are represented by date-keyed event records; past scheduled dates remain meaningful after a change.

**Important limitation:** Only an initial v1 database creation schema exists; no upgrade-from-old-Android-release migrations can be tested because there was no older Kārya Android release. Existing desktop Python task databases are not automatically imported (by design, since no JSON import/export is requested).

## October 2026 source refinement

- Tap a subject on Home to open tasks filtered to that subject.
- Manage subtasks in a live-updating task detail sheet.
- Reject impossible dates in rule-based `/addtask` input.
- Show real task completions over the last seven days.
- Optionally create a new task reminder one hour before its deadline or a new habit reminder at 6 PM (Settings).
- Clear all data also clears saved local preferences.
- Offline SQLite/Android source smoke checks and CI workflows included; Flutter builds still require external toolchain verification.
