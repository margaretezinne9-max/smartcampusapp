# Smart Campus Companion: architecture, data model and screens

Use this as the base for the design chapter of your thesis.

## 1. Stack

Flutter (Material 3) and Dart, one code base for web and Android. Firebase: Authentication (email and password),
Cloud Firestore (real-time database and security rules), Firebase AI Logic with Gemini (academic assistant).
Planned: Cloud Messaging (push notifications), App Check.

## 2. Layers (clean architecture)

Each feature is split into three layers; the screens never talk to Firebase directly.

- **domain**: plain Dart models, rules and algorithms, and repository *interfaces*. No Flutter, no Firebase.
- **data**: repository implementations. Two for every repository: *in-memory* (demo and tests) and *Firestore*.
- **presentation**: screens and controllers (Flutter widgets, `ChangeNotifier`).

One flag, `kUseFirebase` in `lib/core/config.dart`, switches every repository between demo and Firebase
(through `useFirebaseBackends` in `lib/core/backend.dart`, which the tests force to false).
That is why the whole app can be tested without a network or a Firebase project.

## 3. Folder map

```
lib/
  main.dart                      app start, theme, language, settings scope
  core/                          config, brand, format, l10n (French), settings, router, shared widgets
  features/
    auth/                        sign in, register, roles (domain/data/presentation)
    portal/                      role registry, adaptive shell (bottom bar / side rail), profile, settings card
    campus/                      timetable, next class, notices, events bar, exams, study planner, resources,
                                 admin screens, demo data
    student/                     results (built live from the scores lecturers enter)
    aspirant/                    admission application and status
    assistant/                   academic assistant (policy, offline demo, Gemini)
    chat/                        course chats
    feedback/                    feedback box, SUS survey, admin results
test/                            unit tests (domain, repositories) and widget tests (screens)
firestore.rules                  server-side access control
```

## 4. Roles and navigation

`MainPortalRouter` listens to the sign-in state: splash, then login, then the portal for the user's role.
`RoleRegistry` (an exhaustive `switch` over the `UserRole` enum) maps every role to its tabs; adding a role
without a configuration does not compile.

| Role | Bottom bar | Home shortcuts |
|---|---|---|
| Student | Home, Timetable, Chat, Assistant, Profile | All notices, Exams and study planner, Study resources, Results, Feedback |
| Course rep | same as student | same, without Results |
| Lecturer | Home, Timetable, Students, Chat, Profile | All notices, Exams, Study resources, Feedback |
| Admin | Home, Notices, Users, Profile | Manage exams, Feedback and survey results, Load demo data |
| Bursar | Home, Payments, Receipts, Profile | placeholders |
| Aspirant | Home, Application, Admission, Profile | application flow |

The bottom bar holds at most five tabs (Material guideline), so less-used screens are Home shortcuts.

## 5. Data model (Firestore)

| Collection | Main fields | Read | Write |
|---|---|---|---|
| `users/{uid}` | name, email, role, department, level | owner, admin | create: owner as aspirant; update: admin |
| `campuses/{id}` | name, address, mapsUrl, directions | signed in | admin |
| `timetable/{id}` | course, lecturerId, department, level, weekday, start and end minute, hall, campus | signed in | admin |
| `notices/{id}` | title, body, category, eventDate, department, level | signed in (filtered in the app) | admin |
| `enrollments/{id}` | studentId, course, lecturerId, units, score | that student, that lecturer, admin | admin; lecturer may change `score` only (empty or 0 to 100) |
| `chatRooms/{roomId}` | course, lecturerId | its lecturer, enrolled students, admin | admin |
| `chatRooms/{roomId}/messages/{id}` | senderId, name, role, text, sentAt | room members, admin | members, as themselves |
| `exams/{id}` | course, lecturerId, department, level, start, duration, hall, campus | signed in | admin |
| `resources/{id}` | course, title, https url, type, lecturerId, department, level | signed in | lecturer of that course, admin |
| `feedback/{id}` | role, category, message, rating | admin | any signed-in user (create only) |
| `susResponses/{id}` | role, answers (10), score | admin | any signed-in user (create only) |

## 6. Security model

Roles are enforced twice: the screens hide what a role should not use, and `firestore.rules` refuses the request on
the server. The rules use the enrolment document id (`<studentUid>_<courseCode>`) and the chat room's lecturerId to decide
membership, so a lecturer sees only their own students and a student only their own courses. Self-registration can
only ever create an aspirant; only an admin changes roles. The AI key is held by Firebase AI Logic, never in the app.

## 7. Key algorithms (all unit tested)

- **Next class**: turns weekly slots into real dates, treats a class in progress as next, wraps to next week.
- **Notice targeting**: department and level filter; lecturers match on department only; admins see all.
- **Study planner**: daily study time shared between upcoming exams weighted by 1 / days left, in 15-minute blocks.
- **Results**: grade letters and points on a 5-point scale (A 70+, B 60+, C 50+, D 45+, E 40+); GPA weighted by credit units.
- **SUS score**: (sum of positive (answer - 1) and negative (5 - answer)) x 2.5.
- **Assistant policy**: system instruction limits Gemini to academic help, one-word REFUSED for anything else,
  never invent facts; the app shows a translated refusal and a "verify with your lecturers" banner.

## 8. Testing

Domain logic and repositories are tested as plain Dart. Screens are tested with widget tests on the demo backends,
including per-role navigation, live updates, language and theme switching, and the evaluation tasks.
The Firestore rules and real Gemini calls are checked by hand (Rules Playground, manual questions).

## 9. Limits and future work

Push notifications and reminders when the app is closed, App Check, file uploads (needs a paid storage plan),
sessions and semesters in results, extra powers for class representatives, and a real fees module for the bursar.
