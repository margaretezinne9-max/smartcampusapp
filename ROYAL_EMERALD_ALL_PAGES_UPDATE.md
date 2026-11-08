# Royal Emerald — All Pages Update

This update extends the Hill City University Royal Emerald design language beyond the home dashboard.

## Updated experiences
- Shared Royal Emerald page-header and section-heading components.
- Dedicated Campus Events page with upcoming and past event sections, date tiles, event details, and live data from the existing notice stream.
- Examinations page with upcoming/completed summaries and improved exam cards; existing revision planner actions remain connected.
- Notices page with a branded header and clearer update hierarchy; publishing/deleting behavior remains in place.
- Timetable page with branded page header and clearer day grouping; class detail sheets remain connected.
- Study resources page with a branded learning-library header; resource links and lecturer management actions remain in place.
- Results page with an academic-results header, semester selector, GPA/CGPA cards, grade rows, and a designed empty state.
- Profile page with a branded identity panel; settings and sign-out remain in place.
- App-wide card, navigation, and form styling aligned to emerald, white, and gold.

## Data and functionality
The page redesigns continue to use the existing repositories, streams, route builders, and callbacks. No demo event, exam, result, or notice data has been substituted for live app data.

## Validation note
The editing environment used to prepare this ZIP does not have the Flutter SDK installed. Run the commands below on the Windows machine before replacing your working copy:

```powershell
flutter pub get
dart format lib
dart analyze
flutter test
flutter run -d chrome
```

Keep the previous project as a backup until the app has been launched and checked locally.
