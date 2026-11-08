import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../../auth/domain/app_user.dart';
import '../domain/feedback_models.dart';
import '../domain/feedback_repository.dart';

/// The System Usability Scale questionnaire used to evaluate the app.
class SusPage extends StatefulWidget {
  const SusPage({super.key, required this.user, required this.repository});

  final AppUser user;
  final FeedbackRepository repository;

  @override
  State<SusPage> createState() => _SusPageState();
}

class _SusPageState extends State<SusPage> {
  final List<int?> _answers = List<int?>.filled(Sus.statements.length, null);
  bool _busy = false;
  bool _done = false;
  String? _error;

  bool get _complete => _answers.every((a) => a != null);

  Future<void> _submit() async {
    final failed = context.tr('Could not send the survey. Please try again.');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.submitSus(
        role: widget.user.role,
        answers: [for (final a in _answers) a!],
      );
      if (mounted) setState(() => _done = true);
    } catch (_) {
      if (mounted) setState(() => _error = failed);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Usability survey'))),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _done
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 64,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('Thank you for taking part.'),
                          style: text.titleLarge,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      context.tr(
                        'For each statement, choose how much you agree.',
                      ),
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('1 = strongly disagree, 5 = strongly agree'),
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < Sus.statements.length; i++)
                      Card.outlined(
                        key: ValueKey('sus-$i'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i + 1}. ${context.tr(Sus.statements[i])}',
                              ),
                              const SizedBox(height: 12),
                              SegmentedButton<int>(
                                showSelectedIcon: false,
                                emptySelectionAllowed: true,
                                segments: [
                                  for (var v = 1; v <= 5; v++)
                                    ButtonSegment(value: v, label: Text('$v')),
                                ],
                                selected: {
                                  if (_answers[i] != null) _answers[i]!,
                                },
                                onSelectionChanged: (s) => setState(
                                  () =>
                                      _answers[i] = s.isEmpty ? null : s.first,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: (_complete && !_busy) ? _submit : null,
                        child: Text(context.tr('Submit survey')),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
