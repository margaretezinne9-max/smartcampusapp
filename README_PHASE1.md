# Phase 1: timetable, hall and campus info, live notices, role-based access

## Run it (PowerShell, from the project folder)

1. Stop the app if it is running (Ctrl+C in its terminal).
2. Add the one new package:  `flutter pub add url_launcher`
3. Copy this update into the project (adjust the first path if your extract is nested):
   `Copy-Item -Path "C:\Users\HP\Downloads\campus_phase1_update\*" -Destination "C:\Users\HP\Downloads\smart_campus_portal" -Recurse -Force`
4. Run the tests:  `flutter test`
5. Run the app:  `flutter run -d chrome`
6. Android: plug in a phone (USB debugging on) or start an emulator, then `flutter run`

With `kUseFirebase = false` (lib/core/config.dart) everything works with built-in
demo data and no internet. Sign in with the demo chips: Student, Lecturer, Admin, Course Rep.

## Switch to real Firebase (after `flutterfire configure` is done)

1. Firebase console > Firestore Database > Rules: paste `firestore.rules`, click Publish.
2. Set `kUseFirebase = true` in `lib/core/config.dart`, restart the app.
3. Register the test accounts in the app (each starts as an Aspirant).
4. Make the first admin by hand: Firestore > users > your document > change `role` to `admin`.
5. Sign in as admin > Users tab > give the other accounts their roles
   (student, courseRep, lecturer). Use ONE lecturer account.
6. Admin Home > Load demo data. This creates the campuses, timetable, notices and
   enrolments, and sets department and level on every student and course rep.
7. Everyone signs out and back in. Students now see the timetable.

## What was added

| Area | Files |
|---|---|
| Domain (pure Dart) | `features/campus/domain/` models, `next_class.dart`, `demo_data.dart`, repository interface |
| Data | `in_memory_campus_repository.dart` (demo/tests), `firestore_campus_repository.dart` (real time) |
| Screens | `features/campus/presentation/` home, timetable, notices, students, users, admin home, campus info sheet |
| Shared | `core/format.dart`, `core/widgets/stream_view.dart` |
| Security | `firestore.rules` |

Changed: `AppUser` (department, level), `role_registry.dart` (new tabs per role),
`portal_shell.dart` (a role can have its own Home), both auth repositories.
Note: the student "Courses" tab was replaced by the real Timetable.

## Screens per role

- Student / Course Rep: Home (next class, hall, campus, countdown, latest notices), Timetable, Notices, Results / Attendance
- Lecturer: Home (next class and location), Timetable, Students (own courses only), Notices
- Admin: Home (live counts, load demo data), Notices (publish and delete), Users (change roles)

## Data model (Firestore)

| Collection | Fields | Who can read | Who can write |
|---|---|---|---|
| `users/{uid}` | name, email, role, department, level, createdAt | owner, admin | create: owner as aspirant only; update: admin |
| `campuses/{id}` | name, address, mapsUrl, directions | signed-in users | admin |
| `timetable/{id}` | courseCode, courseTitle, lecturerId, lecturerName, department, level, weekday, startMinute, endMinute, hallName, campusId, campusName | signed-in users | admin |
| `notices/{id}` | title, body, category, eventDate, authorName, createdAt | signed-in users | admin |
| `enrollments/{id}` | studentId, studentName, courseCode, courseTitle, lecturerId, score | that student, that lecturer, admin | create/delete: admin; update: the lecturer, `score` only |

Real-time: screens listen to Firestore snapshot streams, so an admin's new notice
appears on every open device without a refresh.

## Next-class logic

`findNextClass` (domain/next_class.dart) turns weekly slots (weekday + minutes) into real
dates, treats a class in progress as "next", and wraps to next week. It is pure Dart and
fully unit tested.

## Tests

`flutter test` runs the earlier tests plus about 40 new ones: next-class rules,
formatting, timetable and enrolment visibility per role, live notices, and widget tests
for the student, lecturer and admin screens.
The Firestore rules are NOT covered by `flutter test`. Check them by hand in the Firebase
console (Rules > Rules Playground), for example: a student reading another student's
enrolment must be denied.

## Known limits (Phase 2 and 3)

Reminders and push notifications, calendar notice bar, English/French, dark mode, targeted
announcements, AI assistant, chat and navigation polish are not in this phase.
Campus names, directions and Maps links in the demo data are placeholders.
