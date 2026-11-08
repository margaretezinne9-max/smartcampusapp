import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/core/l10n/translations.dart';
import 'package:smart_campus_portal/features/aspirant/domain/application_models.dart';
import 'package:smart_campus_portal/features/assistant/domain/assistant_models.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/feedback/domain/feedback_models.dart';
import 'package:smart_campus_portal/features/portal/role_registry.dart';

/// Guards the French interface: any new screen text that is passed through
/// `context.tr(...)` must have a French entry, or this test fails and names it.
void main() {
  test('every text passed to tr() in the code has a French translation', () {
    final pattern = RegExp(r"""\btr\(\s*'((?:[^'\\]|\\.)*)'""");
    final missing = <String>{};

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('translations.dart'));

    for (final file in files) {
      for (final m in pattern.allMatches(file.readAsStringSync())) {
        final key = m.group(1)!.replaceAll(r"\'", "'");
        if (!frenchStrings.containsKey(key)) missing.add(key);
      }
    }
    expect(missing, isEmpty, reason: 'Add French for: $missing');
  });

  test('role names, tab labels and descriptions are translated', () {
    final keys = <String>{'Home', 'Profile'};
    for (final role in UserRole.values) {
      keys.add(role.label);
      final config = RoleRegistry.of(role);
      for (final m in config.modules) {
        keys..add(m.label)..add(m.description);
      }
    }
    expect(keys.where((k) => !frenchStrings.containsKey(k)), isEmpty);
  });

  test('the generic dashboards (bursar, aspirant) are translated', () {
    final keys = <String>{};
    for (final role in UserRole.values) {
      final config = RoleRegistry.of(role);
      if (config.homeBuilder != null) continue;
      keys.add(config.tagline);
      keys.addAll(config.stats.map((s) => s.label));
      keys.addAll(config.actions.expand((a) => [a.title, a.subtitle]));
    }
    expect(keys.where((k) => !frenchStrings.containsKey(k)), isEmpty);
  });

  test('survey statements, assistant suggestions and admission lists are translated', () {
    final keys = <String>{
      ...Sus.statements,
      ...AcademicPolicy.suggestions,
      ...AdmissionRules.programmes,
      ...AdmissionRules.requiredDocuments,
    };
    expect(keys.where((k) => !frenchStrings.containsKey(k)), isEmpty);
  });

  test('the French text keeps the same placeholders as the English', () {
    final placeholder = RegExp(r'\{[a-z]+\}');
    final broken = <String>[];
    frenchStrings.forEach((english, french) {
      final a = placeholder.allMatches(english).map((m) => m.group(0)).toSet();
      final b = placeholder.allMatches(french).map((m) => m.group(0)).toSet();
      if (a.length != b.length || !a.containsAll(b)) broken.add(english);
    });
    expect(broken, isEmpty);
  });
}
