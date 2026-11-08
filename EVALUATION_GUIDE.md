# Evaluation guide: running the user test and the SUS survey

Use this for the "real users test the app with set tasks, then complete the SUS" part of your thesis.

## 1. Prepare (once)

1. Firebase mode on (`kUseFirebase = true`), rules published.
2. Register the test accounts in the app, then give them roles in Admin > Users:
   `student.test@...`, `courserep.test@...`, `lecturer.test@...` (one lecturer), and keep your admin.
   Use made-up names and test emails only. Never use real student records.
3. Admin > Home > Load demo data. Everyone signs out and in once.
4. Open the app on two devices or browser windows: one as admin, one as a student (needed for task A3).
5. Test the AI assistant yourself first. Free capacity can be busy; ask two questions before each session.

## 2. Tasks

Give each participant the task card, one task at a time. Do not help; note what they struggle with.

### Student
| # | Task | Success when |
|---|---|---|
| S1 | View your timetable | Timetable tab shows the week |
| S2 | Find the hall and campus of your next class | Reads hall and campus from Home or the info sheet |
| S3 | Read the latest notice | Opens a notice from Home or All notices |
| S4 | Find when your next exam is and how many days are left | Reads it from Home or Exams |
| S5 | Receive a reminder | Banner appears before a class (set Profile > Settings > Class reminder to 60 min) |
| S6 | Ask the AI assistant a study question | Gets an answer |
| S7 | Switch the app to French | Whole app changes language |

### Lecturer
| # | Task | Success when |
|---|---|---|
| L1 | See your next class and where it is | Reads class, hall, campus on Home |
| L2 | View the students of one of your courses | Opens Students tab and a course |
| L3 | Send a message to the students of a course | Message posted in Chat; student account sees it |
| L4 | Share a resource link for a course | Appears in Study resources |

### Admin
| # | Task | Success when |
|---|---|---|
| A1 | Publish a notice for one department and level | Notice appears for a matching student |
| A2 | Schedule an exam | Appears in the student's Exams list |
| A3 | Publish a notice and see it on another device without refreshing | Appears on the second device on its own |

## 3. Record for each participant and task

Completed (yes/no/with help), time taken, number of wrong taps or mistakes, and comments in their own words.
A simple table in a spreadsheet is enough: participant id, role, task, completed, seconds, errors, comment.

## 4. SUS survey

1. After the tasks, the participant opens Home > Feedback > Usability survey and answers the 10 statements.
   It works in English and French (Profile > Settings).
2. Admin > Home > Feedback and survey results shows the number of responses and the average score out of 100.
3. Interpretation: 68 is the commonly cited average. Higher is better. Report the average and the range, and
   mention how many participants you had per role. With very few participants, say the result is indicative only.
4. The survey is anonymous (role only). To compare roles later, also note the order in which people finished.

## 5. Ethics and good practice (write a line in your thesis)

- Tell participants the purpose, that taking part is voluntary, and that answers are anonymous.
- Use test accounts and sample data only.
- Do not collect names or contact details in the app.
- Keep your own notes (task table) separate from the in-app answers.

## 6. If something goes wrong on the day

| Problem | What to do |
|---|---|
| Assistant says "very busy" | Wait a minute and retry; it uses two models automatically |
| A student sees no timetable | Role, department and level are set by "Load demo data"; sign out and in |
| Notice not showing for a student | Check its audience (department and level) matches the student |
| App won't load | Stop and run `flutter run -d chrome` again |
