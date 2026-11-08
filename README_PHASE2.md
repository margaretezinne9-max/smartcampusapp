# Phase 2: reminders, calendar events bar, targeted notices, English/French, dark mode

## Run it (PowerShell, from the project folder, one line at a time)

1. Stop the app if it is running (Ctrl+C).
2. Add the new packages:
   `flutter pub add shared_preferences`
   `flutter pub add flutter_localizations --sdk=flutter`
3. Copy this update into the project (adjust the path if your extract is nested):
   `Copy-Item -Path "C:\Users\HP\Downloads\campus_phase2_update\*" -Destination "C:\Users\HP\Downloads\smart_campus_portal" -Recurse -Force`
4. Run the tests:  `flutter test`
5. Run the app:  `flutter run -d chrome`

## What to try

1. Sign in as Student. At the top of Home you see the **Upcoming events** bar; tap an event for details.
2. Profile tab > Settings: switch to **Français** (the whole app changes), pick **Dark**, change the **Class reminder** time.
   These choices are saved and are still there after you restart the app.
3. Reminder: it shows a banner on every tab when a class is about to start (default 15 minutes before).
   To see it without waiting for Monday 08:00, set the reminder to 60 minutes and use a time close to a class.
4. Sign in as Admin > Notices > Publish notice. Choose an audience (department and/or level).
   A notice for "Law, Level 100" is invisible to the Computer Science level 400 student but visible to the admin.

## What was added

| Feature | Where |
|---|---|
| Settings (language, theme, reminder), saved on the device | `core/settings/app_settings.dart`, `portal/pages/settings_card.dart` |
| English/French | `core/l10n/translations.dart` (English text is the key; missing French falls back to English) |
| Class reminder banner | `campus/presentation/reminder_banner.dart` |
| Calendar events bar | `campus/presentation/event_bar.dart`, `upcomingEvents` in `domain/notice_logic.dart` |
| Targeted notices (department, level) | `Notice.department/level`, `noticeVisibleTo` in `domain/notice_logic.dart`, audience pickers in the publish dialog |
| Dark mode | `themeMode` in `main.dart` |

Changed: `main.dart`, `portal_shell.dart`, login and profile pages, all campus screens (now translated),
`format.dart` (French dates), `next_class.dart` (`skipOngoing`), demo data (3 more events, 2 targeted notices).
Firestore rules: unchanged.

## How targeting works

A notice has an optional department and level (empty = everyone). `noticeVisibleTo` decides what each user sees:
same department, same level; lecturers match on department only; admins see everything.
This is a display filter, not secret data, so it is done in the app. Roles and private data
(grades, enrolments, role changes) are still enforced by Firestore rules.

## Honest limits

- Reminders appear while the app is open. Reminders when the app is closed need Android local
  notifications and push (Phase 4, after Android is set up).
- Student Results, Aspirant screens and the Bursar/Aspirant dashboards are still English only.
  They are translated in the final polish phase.
- French is a lightweight dictionary, not the ARB/gen-l10n system. It is easy to explain in the thesis
  and cannot crash on a missing string. Tab label "Horaire" is short on purpose so it fits a phone.
- Have a native French speaker proofread `translations.dart` before your evaluation.

## Tests

`flutter test` now also covers: next-class `skipOngoing`, French date formatting, notice targeting rules,
upcoming-events filtering, settings saving, translation and fallback, the reminder banner (timing, lead time,
off, dismiss), language and theme switching, the events bar, and targeted notices on screen.
