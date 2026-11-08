enum ApplicationStatus {
  draft('Not submitted'),
  submitted('Submitted'),
  underReview('Under review'),
  admitted('Admitted');

  const ApplicationStatus(this.label);
  final String label;
}

/// Static admission settings. Move these to your backend when ready.
abstract final class AdmissionRules {
  static const programmes = [
    'Computer Science',
    'Accounting',
    'Law',
    'Nursing Science',
    'Mechanical Engineering',
    'Mass Communication',
  ];

  static const requiredDocuments = [
    'Birth certificate',
    "O'Level result",
    'Passport photograph',
  ];

  static const maxExamScore = 400;
}

String formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class Application {
  const Application({
    this.phone = '',
    this.address = '',
    this.dateOfBirth,
    this.programme,
    this.examScore,
    this.documents = const <String>{},
    this.status = ApplicationStatus.draft,
    this.submittedAt,
  });

  final String phone;
  final String address;
  final DateTime? dateOfBirth;
  final String? programme;
  final int? examScore;
  final Set<String> documents;
  final ApplicationStatus status;
  final DateTime? submittedAt;

  bool get isEditable => status == ApplicationStatus.draft;

  bool get hasAllDocuments =>
      AdmissionRules.requiredDocuments.every(documents.contains);

  bool get isComplete =>
      phone.isNotEmpty &&
      address.isNotEmpty &&
      dateOfBirth != null &&
      programme != null &&
      examScore != null &&
      hasAllDocuments;

  Application copyWith({ApplicationStatus? status, DateTime? submittedAt}) =>
      Application(
        phone: phone,
        address: address,
        dateOfBirth: dateOfBirth,
        programme: programme,
        examScore: examScore,
        documents: documents,
        status: status ?? this.status,
        submittedAt: submittedAt ?? this.submittedAt,
      );
}
