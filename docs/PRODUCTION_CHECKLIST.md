# Before real users: checklist

Tick each line. Items marked (later) need Android or a paid plan, so they are listed in the thesis as future work.

## Security
- [ ] `firestore.rules` is the latest file and is published (Rules tab shows `match /exams/{id}` and `match /chatRooms/{roomId}`).
- [ ] Spot-check three rules in the Rules Playground: a student cannot read another student's enrolment; a student
      not enrolled in CSC401 cannot read its chat; only an admin can write to `notices`.
- [ ] Only your own admin account has role `admin` (Firestore > users).
- [ ] The Firebase web API key is restricted (Google Cloud console > APIs & Services > Credentials > the browser key >
      Application restrictions: websites; add `localhost` and your `web.app` address). The key is not a password, but
      restricting it stops other sites using your project.
- [ ] No real student data anywhere. Test accounts with made-up names only.
- [ ] App Check for the AI service (later): it proves requests come from your app. Needs a reCAPTCHA key for the web
      and Play Integrity for Android. Until then, rely on the free-plan limits.
- [ ] In Firebase console > AI Logic, set a per-user request limit.

## Data and content
- [ ] Real campus names, addresses and Google Maps links in the admin data (replace the demo ones).
- [ ] Real logo in `assets/images/logo.png`, brand colour in `lib/core/brand.dart`, campus photos added.
- [ ] A native French speaker has read `lib/core/l10n/translations.dart`.
- [ ] Demo data loaded once (Admin Home > Load demo data), then test accounts have the right roles.

## Quality
- [ ] `flutter test` is green.
- [ ] Walked through every task in `EVALUATION_GUIDE.md` yourself on a phone and a laptop.
- [ ] Tried the app in English and French, light and dark mode.

## Limits to state honestly in the thesis
- Reminders work while the app is open; reminders and push notifications when it is closed need Android set up (later).
- File uploads are replaced by links because file storage needs a paid plan.
- The assistant uses the free Gemini plan; it can be busy or reach its daily limit.
- Firestore rules are checked by hand, not by automated tests.
