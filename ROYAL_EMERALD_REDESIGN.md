# Royal Emerald redesign

This archive contains the original outer `smart_campus_portal` Flutter project with a visual refresh applied.

## Updated files

- `lib/features/campus/presentation/campus_home_page.dart` — refreshed university header, real university logo and campus photo backdrop, student greeting, next-class card, shortcut grid and home section styling. Existing repository streams and shortcut navigation are retained.
- `lib/features/campus/presentation/event_bar.dart` — compact two-column event cards; event detail bottom sheet is retained.
- `lib/features/campus/presentation/exams_page.dart` — featured emerald next-exam panel and revision-plan action; full exams page and exam cards are retained.
- `lib/features/portal/portal_shell.dart` — hides the duplicate global AppBar and reminder banner on the home tab; other tabs keep their normal shell and reminder behavior.
- `lib/core/brand.dart` and `lib/main.dart` — emerald seed colour and app-wide Material 3 card/navigation styling.

## University branding

The existing Hill-City University logo asset at `assets/images/logo.png` is preserved and used in the home header. The logo's original colours are not altered; the surrounding interface uses emerald green and gold.

## Run locally

From this project folder:

```bash
flutter pub get
 dart format lib
flutter analyze
flutter test
flutter run -d chrome
```

The ZIP archive was checked for integrity. Flutter analysis, tests and device builds were not run in the packaging environment; please run the commands above in the local Flutter SDK before deployment.
