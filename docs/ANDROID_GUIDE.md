# Android: set up, run on a phone, build an APK

Do this when you are ready. Everything else in the project already works in the browser.

## 1. Install the tools (once, about 45 minutes)

1. Install **Android Studio** from developer.android.com/studio. Open it once and let it download the Android SDK.
2. In Android Studio: **More Actions > SDK Manager > SDK Tools**, tick **Android SDK Command-line Tools**, Apply.
3. Tell Flutter where Java is (Android Studio ships one):
   `flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"`
4. Accept the licences (answer y to each): `flutter doctor --android-licenses`
5. Check: `flutter doctor -v`. The **Android toolchain** line should have no red mark.

## 2. Run on a phone or an emulator

- **Real phone (easiest):** Settings > About phone > tap Build number 7 times > Developer options > USB debugging on.
  Plug in the cable and accept the prompt on the phone. `flutter devices` should list it.
- **Emulator:** Android Studio > Device Manager > Create device (a Pixel with a recent Android version).
- Run: `flutter run -d DEVICE_ID` (the id shown by `flutter devices`).

## 3. Build an APK to hand to testers

`flutter build apk --release` creates `build\app\outputs\flutter-apk\app-release.apk`.
Send that file (for example by Google Drive). Testers must allow "install unknown apps". This build is signed with a
debug key, which is fine for a university evaluation. A Play Store release needs your own signing key.

## 4. Reminders and push notifications when the app is closed (the next step)

- **Class reminders** can be scheduled on the phone itself with the `flutter_local_notifications` package: no server,
  works offline. The app already knows the timetable and the reminder time chosen in Settings.
- **Push notifications** (a new notice or chat message while the app is closed) use Firebase Cloud Messaging. Sending
  them automatically needs a small server function, which needs the paid Blaze plan. Without it, an admin can still
  send a message to everyone from the Firebase console (Messaging).
- Android 13 and newer ask the user to allow notifications; the app must request that permission.

When Android runs for you, tell me and I will add the local reminders first, testing step by step with you, because
this part depends on your Android project files.
