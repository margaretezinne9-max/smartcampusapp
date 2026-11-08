# Put the app online (Firebase Hosting, free plan)

Real users can then open the app on their phones from a link, with nothing to install.
You need: Firebase set up and working (Phase 0), `kUseFirebase = true`, the rules published.

## One-time

1. Find your Firebase project id. It prints one line:
   `Select-String -Path lib\firebase_options.dart -Pattern "projectId" | Select-Object -First 1`
   (the id is the text between the quotes, for example `hill-city-portal-1a2b3`).
2. Log in if needed: `firebase login`
3. In the Firebase console, open **Build > Hosting** and click **Get started** if you see it (you can skip the
   instructions it shows; they are not needed).

## Every time you want to publish a new version

1. Build the web app:  `flutter build web --release`
2. Publish it (replace YOUR_PROJECT_ID):
   `firebase deploy --only hosting --config firebase.hosting.json --project YOUR_PROJECT_ID`
3. Open the address it prints, which looks like `https://YOUR_PROJECT_ID.web.app`.
   Send that link to your testers.

The `firebase.hosting.json` file is separate from the `firebase.json` that `flutterfire configure` created, so
nothing of yours is overwritten.

## Check after publishing

- Sign in with a test account on a phone browser. Register, sign out, sign in again.
- The assistant answers a question.
- Admin publishes a notice and a second device shows it without refreshing.

## If something fails

| Problem | Fix |
|---|---|
| `Failed to get Firebase project` | Wrong project id, or you are logged in with another Google account (`firebase logout` then `firebase login`) |
| Blank page | Run `flutter build web --release` again and check it finished without errors |
| Login error about an unauthorised domain | Firebase console > Authentication > Settings > Authorised domains: add the `web.app` address |
| Old version still showing | Hard refresh (Ctrl+Shift+R), or open in a private window |

## Cost

Hosting on the free plan is enough for a student evaluation (generous monthly download and storage limits).
No billing account is needed.
