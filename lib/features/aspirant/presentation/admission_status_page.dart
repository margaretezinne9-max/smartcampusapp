import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../domain/application_models.dart';
import 'application_controller.dart';

class AdmissionStatusPage extends StatelessWidget {
  const AdmissionStatusPage({super.key, required this.controller});

  final ApplicationController controller;

  static const _timeline = [
    (ApplicationStatus.submitted, 'Application submitted'),
    (ApplicationStatus.underReview, 'Under review by admissions'),
    (ApplicationStatus.admitted, 'Admission decision'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final app = controller.application;
        if (app == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final programme = app.programme;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(context.tr('Admission status'), style: text.headlineSmall),
                const SizedBox(height: 16),
                if (app.status == ApplicationStatus.admitted)
                  Card.filled(
                    color: scheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        context.tr(
                          'Congratulations! You have been offered admission to study {programme} at Hill City University.',
                          {
                            'programme': programme == null
                                ? ''
                                : context.tr(programme),
                          },
                        ),
                        style: text.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  )
                else if (app.status == ApplicationStatus.draft)
                  Card.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        context.tr(
                          'You have not submitted your application yet. Complete the Application tab to start the admission process.',
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                for (final (status, label) in _timeline)
                  ListTile(
                    leading: Icon(
                      app.status.index >= status.index
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: app.status.index >= status.index
                          ? scheme.primary
                          : scheme.outline,
                    ),
                    title: Text(context.tr(label)),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: controller.load,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.tr('Refresh status')),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr(
                    'Demo mode: after you submit, the status moves to "Under review" after about 15 seconds and "Admitted" after about 40. Press Refresh to see it change. In production an admissions officer updates the status.',
                  ),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
