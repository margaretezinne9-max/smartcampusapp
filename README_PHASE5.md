# Phase 5: grades, full French, deployment and documents

## Run it (PowerShell, from the project folder, one line at a time)

1. Stop the app if it is running (Ctrl+C).
2. Copy this update into the project (adjust the path if your extract is nested):
   `Copy-Item -Path "C:\Users\HP\Downloads\campus_phase5_update\*" -Destination "C:\Users\HP\Downloads\smart_campus_portal" -Recurse -Force`
3. `flutter test`
4. `flutter run -d chrome`

No new packages are needed.

## For Firebase mode (important)

1. Publish the new `firestore.rules` (Firebase console > Firestore Database > Rules > paste > Publish).
   The enrolment rule now also checks that a score is empty or a whole number from 0 to 100.
2. Admin > Home > **Load demo data** again. Enrolments now carry credit units.
3. Everyone signs out and back in.

## What is new

| Item | Details |
|---|---|
| **Grades** | A lecturer opens Students > course and taps the pencil next to a student to enter a score (0 to 100). The student sees it in Home > Results with grade letter, semester GPA and CGPA. Lecturers can only grade their own courses (rules and app). Results no longer use demo data in Firebase mode. |
| **Full French** | The Aspirant application and admission screens, the Bursar and Aspirant dashboards and Results are translated. A test (`translation_coverage_test`) fails if any text passed to `tr()` has no French. |
| **Put it online** | `docs/DEPLOY.md` and `firebase.hosting.json`: publish to a free `web.app` address testers can open on phones. |
| **Documents** | `docs/USER_MANUAL.md`, `docs/REQUIREMENTS_TRACEABILITY.md`, `docs/PRODUCTION_CHECKLIST.md`, `docs/ANDROID_GUIDE.md`, updated `docs/ARCHITECTURE.md`. |
| **Earlier fixes folded in** | The dialog fix for adding resources and exams, and the assistant quota handling, are included in this zip. |

## Notes

- Results use a 5-point scale (A 70+, B 60+, C 50+, D 45+, E 40+). Change the cut-offs in
  `features/student/domain/student_models.dart` to match your university's policy, and update the matching test.
- All scores of a student form one "Current semester" for now. Separate sessions and semesters are future work.
- Credit units come from the enrolment (demo data: most courses 3, CSC 499 has 6, GST 401 has 2).

## Tests

New: score entry rules (valid range, only the course's lecturer, clearing a score), who sees which enrolments,
results and GPA from scores, the lecturer-to-student score flow on screen, the French coverage guard.
