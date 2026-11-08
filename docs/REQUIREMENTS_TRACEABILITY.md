# Requirements traceability

Links each requirement of the project brief to where it is built, how it is tested, and its honest status.
Status: **Done**, **Partial** (works, with a stated limit) or **Not yet**.

## Survey findings
| Finding | Where it is met |
|---|---|
| Campus, hall and annex information (23 students) | Campus info sheet, campuses data |
| Academic AI assistant (22) | Assistant tab |
| Calendar notice bar (18) | Events bar on Home |
| Reminder before class (17) | Reminder banner (while the app is open); closed-app reminders: not yet |
| Timetable with reminders (14) | Timetable tab and reminder banner |
| Lecturers: next-class reminder with location | Home next-class card and banner |
| Lecturers: student-lecturer chat | Chat tab |
| Role-based access, course reps, grades, courses | See access control below |

## Must-have features
| # | Requirement | Status | Built in | Tests |
|---|---|---|---|---|
| 1 | Timetable per user | Done | `campus/presentation/timetable_page.dart` | `campus_repository_test`, `campus_screens_test` |
| 2 | Next-class reminders with time, hall, campus | Partial | Next-class card, `reminder_banner.dart`. Reminders while the app is closed need Android | `next_class_test`, `settings_test` |
| 3 | Hall and campus info for every class | Done | `campus_info_sheet.dart`, Google Maps link with written fallback | `campus_screens_test` |
| 4 | Admin publishing, live on every device | Done | Firestore streams, `notices_page.dart`, `exams_admin_page.dart` | live-notice and exam tests |
| 5 | Calendar notice bar of events | Done | `event_bar.dart`, `upcomingEvents` | `notice_logic_test`, `targeting_screens_test` |
| 6 | Academic AI assistant, academic only, disclaimer, no invention | Done | `features/assistant` (system instruction, REFUSED handling, banner) | `assistant_test`. Real Gemini answers checked by hand |

## Should / could-have
| Feature | Status | Notes |
|---|---|---|
| Student-lecturer chat | Done | One chat per course, members only |
| Campus navigation main campus and annex | Done | Google Maps directions plus written directions |
| Push notifications, also when closed | Not yet | Needs Android set up and a server function (paid plan) |
| Exam countdown and study planner | Done | `study_planner.dart`, unit tested |
| Targeted announcements by department or level | Done | `noticeVisibleTo` |
| English and French | Done | All screens; a native speaker should proofread. Coverage test in `translation_coverage_test` |
| Lecturer resources | Done | Links, not file uploads (storage needs a paid plan) |
| Feedback box | Done | Anonymous |

## Access control
| Requirement | Status | How |
|---|---|---|
| Roles enforced in Firestore rules, not only the UI | Done | `firestore.rules`. Rules are checked by hand in the Rules Playground |
| A lecturer sees only students and grades of their courses | Done | Enrolment rules by `lecturerId`; lecturers enter scores for their own courses only |
| Class reps distinguished from students | Partial | Separate role with its own account type; today they have the student features. Extra rep powers (for example posting class notices) are future work |
| Students see only their own grades and data | Done | Enrolments readable only by that student; results built from their own scores |
| Admins publish and manage users | Done | Notices, exams, Users tab |
| Test accounts and sample data only | Done | Demo data loader and guide |

## Look and feel
| Requirement | Status | Notes |
|---|---|---|
| Material 3, university colours | Done | One brand colour in `core/brand.dart`; replace with the real logo colour |
| Real logo and campus photos | Partial | Placeholders work; add the real files in `assets/images` |
| Accessible, small screens, optional dark mode | Done | Responsive layouts, dark mode in Settings |

## Evaluation readiness
| Item | Status |
|---|---|
| Student, lecturer and admin task flows on test accounts | Done (`EVALUATION_GUIDE.md`) |
| System Usability Scale inside the app, results for the admin | Done |
| App reachable by testers | Done with Firebase Hosting (`DEPLOY.md`) |

## Output requirements
Zip with README and numbered PowerShell steps, commented code, architecture and data model documented
(`docs/ARCHITECTURE.md`), tests reported each time: Done.
