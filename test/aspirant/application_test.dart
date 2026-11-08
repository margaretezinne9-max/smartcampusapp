import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/features/aspirant/data/mock_admission_repository.dart';
import 'package:smart_campus_portal/features/aspirant/domain/application_models.dart';
import 'package:smart_campus_portal/features/aspirant/presentation/application_controller.dart';

Application completeApplication() => Application(
      phone: '08012345678',
      address: '12 Hill Road',
      dateOfBirth: DateTime(2005, 3, 2),
      programme: 'Law',
      examScore: 280,
      documents: {...AdmissionRules.requiredDocuments},
    );

void main() {
  group('Application model', () {
    test('a new application is an incomplete, editable draft', () {
      const app = Application();

      expect(app.status, ApplicationStatus.draft);
      expect(app.isEditable, isTrue);
      expect(app.isComplete, isFalse);
    });

    test('is complete only when every field and document is present', () {
      expect(completeApplication().isComplete, isTrue);
    });

    test('is incomplete when one document is missing', () {
      final docs = {...AdmissionRules.requiredDocuments}..remove("O'Level result");
      final app = Application(
        phone: '08012345678',
        address: '12 Hill Road',
        dateOfBirth: DateTime(2005, 3, 2),
        programme: 'Law',
        examScore: 280,
        documents: docs,
      );

      expect(app.hasAllDocuments, isFalse);
      expect(app.isComplete, isFalse);
    });

    test('a submitted application is no longer editable', () {
      final submitted =
          completeApplication().copyWith(status: ApplicationStatus.submitted);

      expect(submitted.isEditable, isFalse);
    });

    test('statuses are ordered draft < submitted < review < admitted', () {
      expect(ApplicationStatus.draft.index, lessThan(ApplicationStatus.submitted.index));
      expect(ApplicationStatus.submitted.index, lessThan(ApplicationStatus.underReview.index));
      expect(ApplicationStatus.underReview.index, lessThan(ApplicationStatus.admitted.index));
    });
  });

  group('ApplicationController', () {
    late ApplicationController controller;

    setUp(() {
      controller = ApplicationController(MockAdmissionRepository(), 'user-1');
    });

    test('loads an empty draft for a new aspirant', () async {
      await controller.load();

      expect(controller.application?.status, ApplicationStatus.draft);
    });

    test('saves draft progress', () async {
      final ok = await controller.saveDraft(const Application(phone: '0801'));

      expect(ok, isTrue);
      expect(controller.application?.phone, '0801');
    });

    test('refuses to submit an incomplete application', () async {
      final ok = await controller.submit(const Application(phone: '0801'));

      expect(ok, isFalse);
      expect(controller.error, isNotNull);
      expect(controller.application?.status, isNot(ApplicationStatus.submitted));
    });

    test('submits a complete application', () async {
      final ok = await controller.submit(completeApplication());

      expect(ok, isTrue);
      expect(controller.application?.status, ApplicationStatus.submitted);
      expect(controller.application?.submittedAt, isNotNull);
    });

    test('a submitted application is still there after reloading', () async {
      await controller.submit(completeApplication());
      await controller.load();

      expect(controller.application?.isEditable, isFalse);
      expect(controller.application?.programme, 'Law');
    });
  });
}
