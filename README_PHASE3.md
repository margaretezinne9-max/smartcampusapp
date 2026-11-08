# Phase 3: academic assistant (Gemini) and course chats

## Run it (PowerShell, from the project folder, one line at a time)

1. Stop the app if it is running (Ctrl+C).
2. Add the AI package:  `flutter pub add firebase_ai`
3. Copy this update into the project (adjust the path if your extract is nested):
   `Copy-Item -Path "C:\Users\HP\Downloads\campus_phase3_update\*" -Destination "C:\Users\HP\Downloads\smart_campus_portal" -Recurse -Force`
4. Run the tests:  `flutter test`
5. Run the app:  `flutter run -d chrome`

Everything works offline with the demo backends while `kUseFirebase = false`.

## What to try (demo mode)

- Student: bottom bar is now Home, Timetable, Chat, Assistant, Profile.
  - Assistant: ask "Explain what a deadlock is" (answered), then "Who won the football match?" (refused).
    The yellow banner is the "check with your lecturers" notice.
  - Chat: open CSC 401, send a message.
- Lecturer: Chat > CSC 401 > reply. Sign out, sign in as Student, open the same chat: the message is there.
- Notices and (for students) Results are now shortcut cards at the bottom of Home. The bottom bar can hold only 5 tabs.

## Switch on the real Gemini assistant and real chat

Needs the Firebase steps from Phase 0 first (`flutterfire configure`, rules published, `kUseFirebase = true`).

1. Firebase console > **Build > AI Logic > Get started** > choose **Gemini Developer API** and finish the wizard.
   The no-cost "Spark" plan is enough: do NOT link a billing account unless you want paid limits.
2. Publish the updated `firestore.rules` (it now covers chat rooms and messages).
3. Sign in as admin > Home > **Load demo data** (it now also creates the chat rooms). Everyone signs out and in.
4. If the assistant says it is unavailable, the model name may have changed: open `lib/core/ai_config.dart`
   and use a current model name from the Firebase console model list.

## How the assistant keeps to the rules

| Rule from your brief | How it is done |
|---|---|
| Academic topics only | System instruction tells Gemini to answer ONLY academic requests and to reply with the single word REFUSED otherwise. The app turns REFUSED into a standard translated message. |
| Refuses non-academic requests | Same mechanism. The demo assistant uses a keyword list instead. |
| Never invent facts | System instruction forbids invented facts, citations, grades, timetables, policies; it must say when it is unsure. The app never feeds it student records. |
| Verify with lecturers | A banner is always shown on the assistant screen. |
| API key safety | The key stays in Firebase's service (Firebase AI Logic). It is not in the app. |

Honest limit: a system instruction greatly reduces but cannot guarantee perfect behaviour. Test it with
off-topic and tricky questions before your evaluation. Before real users, add Firebase **App Check** so only
your app can call the AI (Phase 4).

## How the chat works

- One room per course. Room id = course code without spaces (CSC401).
- Members: the course's lecturer and the students enrolled in it. A student never sees other courses.
- Data: `chatRooms/{roomId}` (course, lecturerId) and `chatRooms/{roomId}/messages/{id}`
  (senderId, senderName, senderRole, text, sentAt).
- Rules: only members read and post; a message must carry your real uid, name and role, 1 to 1000 characters,
  and the server time. Only admins can edit or delete messages.
- Messages appear live for everyone in the room (Firestore snapshots).

## Files

| Area | Where |
|---|---|
| Assistant | `features/assistant/` (domain: policy and models; data: offline and Gemini services; presentation: controller and page) |
| Chat | `features/chat/` (domain, in-memory and Firestore repositories, rooms list, room screen) |
| Home shortcuts | `HomeShortcut` in `campus/presentation/campus_home_page.dart`, built in `campus/campus_tabs.dart` |
| Tabs per role | `portal/role_registry.dart` |
| Rules | `firestore.rules` |

## Tests

New: policy and refusal detection, offline assistant, assistant controller (errors, reset, limits), assistant
screen, chat visibility per role, live messages, validation, membership, and a lecturer-to-student message
across two sign-ins. Updated: the notice tests now open notices from the Home shortcut.
The Firestore rules and the real Gemini calls are NOT covered by `flutter test`. Check the rules in the
Firebase console Rules Playground (for example: a student not enrolled in CSC401 must be denied reading
`chatRooms/CSC401/messages`).

## Limits

- No push notification for new chat messages yet (Phase 4).
- Chat is text only. No file sharing, edit or delete for users.
- Assistant history lives in memory for the session only.
- Aspirant and Bursar screens and the Results page are still English only.
