import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/core/l10n/translations.dart';
import 'package:smart_campus_portal/core/settings/app_settings.dart';
import 'package:smart_campus_portal/features/auth/data/mock_auth_repository.dart';
import 'package:smart_campus_portal/features/auth/domain/app_user.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/auth/presentation/auth_controller.dart';
import 'package:smart_campus_portal/features/campus/data/in_memory_campus_repository.dart';
import 'package:smart_campus_portal/features/campus/presentation/reminder_banner.dart';
import 'package:smart_campus_portal/main.dart';

const student = AppUser(
  id: 'hcu-student-001',
  name: 'Demo Student',
  email: 'student@hcu.edu',
  role: UserRole.student,
  department: 'Computer Science',
  level: 400,
);

Future<AppSettings> bootApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final settings = AppSettings();
  final auth = AuthController(MockAuthRepository())..bootstrap();
  await tester.pumpWidget(SmartCampusApp(auth: auth, settings: settings));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return settings;
}

Future<void> signInAsStudent(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ActionChip, 'Student'));
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

Finder tab(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

Future<void> openProfile(WidgetTester tester) async {
  await tester.tap(tab('Profile'));
  await tester.pumpAndSettle();
}

void main() {
  group('AppSettings', () {
    test('starts with English, system theme and a 15 minute reminder', () {
      final s = AppSettings();

      expect(s.language, 'en');
      expect(s.themeMode, ThemeMode.system);
      expect(s.reminderMinutes, 15);
    });

    test('changes notify listeners and are saved', () async {
      final store = MemorySettingsStore();
      final s = AppSettings(store: store);
      var notified = 0;
      s.addListener(() => notified++);

      await s.setLanguage('fr');
      await s.setThemeMode(ThemeMode.dark);
      await s.setReminderMinutes(30);

      expect(notified, 3);
      final reloaded = AppSettings(store: store);
      await reloaded.load();
      expect(reloaded.language, 'fr');
      expect(reloaded.themeMode, ThemeMode.dark);
      expect(reloaded.reminderMinutes, 30);
    });

    test('an unsupported language is ignored', () async {
      final s = AppSettings();

      await s.setLanguage('de');

      expect(s.language, 'en');
    });

    test('corrupt saved values fall back to the defaults', () async {
      final store = MemorySettingsStore();
      await store.write('language', 'xx');
      await store.write('themeMode', 'neon');
      await store.write('reminderMinutes', '7');
      final s = AppSettings(store: store);

      await s.load();

      expect(s.language, 'en');
      expect(s.themeMode, ThemeMode.system);
      expect(s.reminderMinutes, 15);
    });
  });

  group('translate', () {
    test('English text is returned as written', () {
      expect(translate('Next class', 'en'), 'Next class');
    });

    test('French text comes from the dictionary', () {
      expect(translate('Next class', 'fr'), 'Prochain cours');
      expect(translate('Sign out', 'fr'), 'Se déconnecter');
    });

    test('a missing translation falls back to English', () {
      expect(translate('A sentence nobody translated', 'fr'),
          'A sentence nobody translated');
    });

    test('placeholders are filled in both languages', () {
      expect(translate('Welcome, {name}', 'en', {'name': 'Ada'}), 'Welcome, Ada');
      expect(translate('Welcome, {name}', 'fr', {'name': 'Ada'}), 'Bienvenue, Ada');
    });
  });

  group('settings screens', () {
    testWidgets('switching to French translates the app', (tester) async {
      final settings = await bootApp(tester);
      await signInAsStudent(tester);
      await openProfile(tester);

      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      expect(settings.language, 'fr');
      expect(find.text('Se déconnecter'), findsOneWidget);
      expect(tab('Accueil'), findsOneWidget);

      await tester.tap(tab('Accueil'));
      await tester.pumpAndSettle();
      expect(find.text('Bienvenue, Demo'), findsOneWidget);
      // "Next class" or, during a lesson, "Happening now".
      expect(
        find.byWidgetPredicate((w) =>
            w is Text && (w.data == 'Prochain cours' || w.data == 'En cours')),
        findsOneWidget,
      );
    });

    testWidgets('the theme setting changes the app theme mode', (tester) async {
      final settings = await bootApp(tester);
      await signInAsStudent(tester);
      await openProfile(tester);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(settings.themeMode, ThemeMode.dark);
      expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          ThemeMode.dark);
    });

    testWidgets('the reminder lead time can be turned off', (tester) async {
      final settings = await bootApp(tester);
      await signInAsStudent(tester);
      await openProfile(tester);

      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Off'));
      await tester.pumpAndSettle();

      expect(settings.reminderMinutes, 0);
    });
  });

  group('class reminder banner', () {
    // The demo timetable has CSC 401 Compiler Construction on Mondays at 08:00.
    final mondayAt = (int h, int m) => DateTime(2026, 10, 26, h, m);

    Future<void> show(
      WidgetTester tester,
      AppSettings settings,
      DateTime now,
    ) async {
      await tester.pumpWidget(
        AppSettingsScope(
          settings: settings,
          child: MaterialApp(
            home: Scaffold(
              body: ReminderBanner(
                user: student,
                repository: InMemoryCampusRepository(),
                clock: () => now,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('appears shortly before a class', (tester) async {
      await show(tester, AppSettings(), mondayAt(7, 50));

      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.textContaining('Compiler Construction'), findsOneWidget);
      expect(find.textContaining('10 min'), findsOneWidget);
    });

    testWidgets('stays hidden when the class is still far away', (tester) async {
      await show(tester, AppSettings(), mondayAt(6, 0));

      expect(find.byType(MaterialBanner), findsNothing);
    });

    testWidgets('respects the lead time from the settings', (tester) async {
      final settings = AppSettings();
      await settings.setReminderMinutes(5);

      await show(tester, settings, mondayAt(7, 50));
      expect(find.byType(MaterialBanner), findsNothing);

      await show(tester, settings, mondayAt(7, 56));
      expect(find.byType(MaterialBanner), findsOneWidget);
    });

    testWidgets('is hidden when reminders are off', (tester) async {
      final settings = AppSettings();
      await settings.setReminderMinutes(0);

      await show(tester, settings, mondayAt(7, 50));

      expect(find.byType(MaterialBanner), findsNothing);
    });

    testWidgets('does not appear while the class is already running',
        (tester) async {
      await show(tester, AppSettings(), mondayAt(8, 30));

      expect(find.byType(MaterialBanner), findsNothing);
    });

    testWidgets('can be dismissed', (tester) async {
      await show(tester, AppSettings(), mondayAt(7, 50));

      await tester.tap(find.text('Dismiss'));
      await tester.pump();

      expect(find.byType(MaterialBanner), findsNothing);
    });
  });
}
