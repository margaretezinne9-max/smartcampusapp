import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/widgets/stream_view.dart';
import '../domain/feedback_models.dart';
import '../domain/feedback_repository.dart';

/// Admin view: usability survey results and the feedback received.
class FeedbackAdminPage extends StatelessWidget {
  const FeedbackAdminPage({super.key, required this.repository});

  final FeedbackRepository repository;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(context.tr('Survey results'), style: text.headlineSmall),
            const SizedBox(height: 16),
            StreamView<List<SusResponse>>(
              open: repository.watchSus,
              builder: (context, responses) {
                final average = Sus.average(responses);
                return Card.filled(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          average == null ? '-' : average.toStringAsFixed(1),
                          style: text.displaySmall,
                        ),
                        Text(context.tr('Average SUS score (out of 100)')),
                        const SizedBox(height: 8),
                        Text(
                          context.tr(
                            responses.length == 1
                                ? '{n} response'
                                : '{n} responses',
                            {'n': '${responses.length}'},
                          ),
                          style: text.bodyMedium,
                        ),
                        if (average != null)
                          Text(
                            Sus.isAboveAverage(average)
                                ? context.tr('Above the average of 68.')
                                : context.tr('Below the average of 68.'),
                            style: text.bodyMedium?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(context.tr('Feedback'), style: text.titleLarge),
            const SizedBox(height: 8),
            StreamView<List<FeedbackEntry>>(
              open: repository.watchFeedback,
              builder: (context, entries) {
                if (entries.isEmpty) {
                  return Text(context.tr('No feedback yet.'));
                }
                return Column(
                  children: [
                    for (final e in entries)
                      Card.outlined(
                        child: ListTile(
                          isThreeLine: true,
                          leading: Icon(switch (e.category) {
                            FeedbackCategory.bug => Icons.bug_report_outlined,
                            FeedbackCategory.idea => Icons.lightbulb_outline,
                            FeedbackCategory.other => Icons.chat_bubble_outline,
                          }),
                          title: Text(e.message),
                          subtitle: Text(
                            '${context.tr(e.role.label)}'
                            '${e.rating == null ? '' : ', ${e.rating}/5'}'
                            ', ${formatDay(e.createdAt, lang: context.lang)}',
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
