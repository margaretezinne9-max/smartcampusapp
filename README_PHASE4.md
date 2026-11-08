# Phase 4: exams and study planner, resources, feedback and survey, branding

## Run it (PowerShell, from the project folder, one line at a time)

1. Stop the app if it is running (Ctrl+C).
2. Copy this update into the project (adjust the path if your extract is nested):
   `Copy-Item -Path "C:\Users\HP\Downloads\campus_phase4_update\*" -Destination "C:\Users\HP\Downloads\smart_campus_portal" -Recurse -Force`
3. Tell Flutter about the images folder (run once). This adds two lines to pubspec.yaml:
   `(Get-Content pubspec.yaml) -replace 'uses-material-design: true', "uses-material-design: true`n  assets:`n    - assets/images/" | Set-Content pubspec.yaml`
   Check it: `Select-String -Path pubspec.yaml -Pattern "assets/images"`  (it must print one line)
4. `flutter pub get`
5. `flutter test`
6. `flutter run -d chrome`

No new packages are needed. If you skip step 3 the app still works; it just shows an icon instead of the logo.

## What is new

| Feature | Who | Where in the app |
|---|---|---|
| Next exam on Home, exam list with countdown | student, course rep, lecturer | Home, then "Exams and study planner" / "Exams" |
| Study planner (day-by-day plan, closer exam gets more time) | student, course rep | Exams page, "Study planner" button |
| Schedule and delete exams | admin | Admin Home, "Manage exams" |
| Study resources (links to notes and past questions) | lecturers add; students read | Home, "Study resources" |
| Feedback box (anonymous, role only) | everyone | Home, "Feedback" |
| Usability survey (System Usability Scale, 10 questions) | everyone | Feedback page, "Usability survey" |
| Feedback and survey results (average SUS score) | admin | Admin Home, "Feedback and survey results" |
| Logo, brand colour, optional campus photos | everyone | See "Branding" below |
| French for Results, exams, resources, feedback, survey | everyone | Profile > Settings |

## Branding: your logo, colours and photos

1. Put your real logo in `assets/images/logo.png` (replace the placeholder, same file name).
2. Put campus photos in `assets/images/campus_main.jpg` and `assets/images/campus_annex.jpg`.
   They appear at the top of the "Hall and campus info" sheet. If a file is missing, nothing is shown.
3. Open `lib/core/brand.dart` and set `kBrandSeed` to the main colour of the logo (`Color(0xFF` + 6-digit code).
   The whole light and dark theme is built from that one colour.
4. Stop and run again: `flutter run -d chrome`.

## Firebase mode: update the rules and reload the demo data

1. Publish the new `firestore.rules` (Firebase console > Firestore Database > Rules > paste > Publish).
2. Admin > Home > Load demo data (it now also creates exams and resources).
3. Everyone signs out and back in.

## How the new parts work

- **Study planner** (`campus/domain/study_planner.dart`, pure Dart, unit tested): each day the student's study time
  is shared between the exams still ahead, weighted by 1 / days left, in blocks of 15 minutes. An exam gets no
  study time on its own day.
- **Resources** are links, not uploaded files, because Firebase file storage needs a paid plan. Only `https` links
  are accepted. A lecturer can only share for courses they teach (checked by the rules).
- **SUS** (`feedback/domain/feedback_models.dart`): positive statements score answer minus 1, negative ones score
  5 minus answer, total times 2.5, giving 0 to 100. 68 is the commonly cited average.
- **Anonymity**: feedback and survey answers store the role only, never the person.

## Not in this phase (needs Android set up, so they are the next phase)

- Reminders and push notifications when the app is closed.
- App Check (protects the AI service from other apps), release build and Play Store packaging.
- Translating the Aspirant and Bursar screens.

## Tests

New: study planner rules, exam and resource visibility per role, link validation, SUS score maths, feedback rules,
and screen tests for exams, planner, resources, feedback, survey and the admin results.
The Firestore rules are not covered by `flutter test`: check them in the console Rules Playground.
