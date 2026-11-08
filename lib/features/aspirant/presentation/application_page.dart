import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../domain/application_models.dart';
import 'application_controller.dart';

class ApplicationPage extends StatelessWidget {
  const ApplicationPage({super.key, required this.controller});

  final ApplicationController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final app = controller.application;
        if (app == null) {
          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.tr(controller.error!)),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: controller.load,
                    child: Text(context.tr('Try again')),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        return app.isEditable
            ? _ApplicationForm(controller: controller, initial: app)
            : _SubmittedView(application: app);
      },
    );
  }
}

class _ApplicationForm extends StatefulWidget {
  const _ApplicationForm({required this.controller, required this.initial});

  final ApplicationController controller;
  final Application initial;

  @override
  State<_ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<_ApplicationForm> {
  final _personalKey = GlobalKey<FormState>();
  final _programmeKey = GlobalKey<FormState>();

  late final _phone = TextEditingController(text: widget.initial.phone);
  late final _address = TextEditingController(text: widget.initial.address);
  late final _score = TextEditingController(
    text: widget.initial.examScore?.toString() ?? '',
  );
  late final _dobText = TextEditingController(
    text: widget.initial.dateOfBirth == null
        ? ''
        : formatDate(widget.initial.dateOfBirth!),
  );

  late DateTime? _dob = widget.initial.dateOfBirth;
  late String? _programme = widget.initial.programme;
  late final Set<String> _docs = {...widget.initial.documents};
  int _step = 0;

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _score.dispose();
    _dobText.dispose();
    super.dispose();
  }

  Application _snapshot() => Application(
    phone: _phone.text.trim(),
    address: _address.text.trim(),
    dateOfBirth: _dob,
    programme: _programme,
    examScore: int.tryParse(_score.text.trim()),
    documents: {..._docs},
  );

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2006),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _dobText.text = formatDate(picked);
      });
    }
  }

  Future<void> _next() async {
    final valid = switch (_step) {
      0 => _personalKey.currentState!.validate(),
      1 => _programmeKey.currentState!.validate(),
      _ => true,
    };
    if (!valid) return;

    if (_step == 2 && !_docs.containsAll(AdmissionRules.requiredDocuments)) {
      _message(context.tr('Please attach all required documents.'));
      return;
    }

    final draft = _snapshot();

    if (_step < 3) {
      await widget.controller.saveDraft(draft);
      if (mounted) setState(() => _step++);
      return;
    }

    if (!draft.isComplete) {
      _message(context.tr('Please complete all steps before submitting.'));
      return;
    }
    final ok = await widget.controller.submit(draft);
    if (!ok && mounted) {
      _message(context.tr(widget.controller.error ?? 'Submission failed.'));
    }
  }

  StepState _stateOf(int i) =>
      _step > i ? StepState.complete : StepState.indexed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final busy = widget.controller.isBusy;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Admission application'),
                    style: text.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                      'Your progress is saved each time you continue.',
                    ),
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stepper(
                currentStep: _step,
                onStepTapped: (i) => setState(() => _step = i),
                onStepContinue: _next,
                onStepCancel: () => setState(() => _step--),
                controlsBuilder: (context, details) => Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      FilledButton(
                        onPressed: busy ? null : details.onStepContinue,
                        child: Text(
                          _step == 3
                              ? context.tr('Submit application')
                              : context.tr('Continue'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_step > 0)
                        TextButton(
                          onPressed: busy ? null : details.onStepCancel,
                          child: Text(context.tr('Back')),
                        ),
                    ],
                  ),
                ),
                steps: [
                  Step(
                    title: Text(context.tr('Personal details')),
                    isActive: _step == 0,
                    state: _stateOf(0),
                    content: Form(
                      key: _personalKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: context.tr('Phone number'),
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().length < 7)
                                ? context.tr('Enter a valid phone number.')
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dobText,
                            readOnly: true,
                            onTap: _pickDate,
                            decoration: InputDecoration(
                              labelText: context.tr('Date of birth'),
                              prefixIcon: const Icon(Icons.cake_outlined),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? context.tr('Select your date of birth.')
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _address,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: context.tr('Home address'),
                              prefixIcon: const Icon(Icons.home_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().length < 5)
                                ? context.tr('Enter your home address.')
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Step(
                    title: Text(context.tr('Programme choice')),
                    isActive: _step == 1,
                    state: _stateOf(1),
                    content: Form(
                      key: _programmeKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _programme,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: context.tr('Programme'),
                              prefixIcon: const Icon(Icons.school_outlined),
                            ),
                            items: [
                              for (final p in AdmissionRules.programmes)
                                DropdownMenuItem(
                                  value: p,
                                  child: Text(context.tr(p)),
                                ),
                            ],
                            onChanged: (v) => setState(() => _programme = v),
                            validator: (v) => v == null
                                ? context.tr('Choose a programme.')
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _score,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: context.tr(
                                'Entrance exam score (0-{max})',
                                {'max': '${AdmissionRules.maxExamScore}'},
                              ),
                              prefixIcon: const Icon(Icons.pin_outlined),
                            ),
                            validator: (v) {
                              final n = int.tryParse(v?.trim() ?? '');
                              if (n == null ||
                                  n < 0 ||
                                  n > AdmissionRules.maxExamScore) {
                                return context.tr(
                                  'Enter a score between 0 and {max}.',
                                  {'max': '${AdmissionRules.maxExamScore}'},
                                );
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Step(
                    title: Text(context.tr('Documents')),
                    isActive: _step == 2,
                    state: _stateOf(2),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            'Demo mode: attaching only simulates an upload. Real uploads need the file_picker package and a storage backend.',
                          ),
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final doc in AdmissionRules.requiredDocuments)
                          Card.outlined(
                            child: ListTile(
                              leading: Icon(
                                _docs.contains(doc)
                                    ? Icons.check_circle
                                    : Icons.upload_file_outlined,
                              ),
                              title: Text(context.tr(doc)),
                              subtitle: Text(
                                _docs.contains(doc)
                                    ? context.tr('Attached')
                                    : context.tr('Not attached'),
                              ),
                              trailing: _docs.contains(doc)
                                  ? TextButton(
                                      onPressed: () =>
                                          setState(() => _docs.remove(doc)),
                                      child: Text(context.tr('Remove')),
                                    )
                                  : FilledButton.tonal(
                                      onPressed: () =>
                                          setState(() => _docs.add(doc)),
                                      child: Text(context.tr('Attach')),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Step(
                    title: Text(context.tr('Review and submit')),
                    isActive: _step == 3,
                    state: _stateOf(3),
                    content: _Review(application: _snapshot()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );

    final programme = application.programme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(context.tr('Phone'), application.phone),
        row(
          context.tr('Date of birth'),
          application.dateOfBirth == null
              ? ''
              : formatDate(application.dateOfBirth!),
        ),
        row(context.tr('Address'), application.address),
        row(
          context.tr('Programme'),
          programme == null ? '' : context.tr(programme),
        ),
        row(context.tr('Exam score'), application.examScore?.toString() ?? ''),
        row(
          context.tr('Documents'),
          context.tr('{n} of {m} attached', {
            'n': '${application.documents.length}',
            'm': '${AdmissionRules.requiredDocuments.length}',
          }),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('You cannot edit your application after submitting.'),
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SubmittedView extends StatelessWidget {
  const _SubmittedView({required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final programme = application.programme;
    final sent = application.submittedAt;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              context.tr('Application submitted'),
              style: text.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              [
                if (programme != null) context.tr(programme),
                if (sent != null)
                  context.tr('Submitted {date}', {'date': formatDate(sent)}),
              ].join('\n'),
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(context.tr('Track your progress in the Admission tab.')),
          ],
        ),
      ),
    );
  }
}
