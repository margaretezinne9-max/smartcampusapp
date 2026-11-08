import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../../auth/domain/app_user.dart';
import '../domain/feedback_models.dart';
import '../domain/feedback_repository.dart';
import 'sus_page.dart';

/// Feedback box: tell the admins about a problem or an idea. Anonymous: only
/// the role is stored. Also the entry point to the usability survey.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, required this.user, required this.repository});

  final AppUser user;
  final FeedbackRepository repository;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _message = TextEditingController();
  FeedbackCategory _category = FeedbackCategory.idea;
  int? _rating;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  String _categoryLabel(FeedbackCategory c) => switch (c) {
    FeedbackCategory.bug => 'Problem',
    FeedbackCategory.idea => 'Idea',
    FeedbackCategory.other => 'Other',
  };

  Future<void> _send() async {
    final thanks = context.tr('Thank you for your feedback.');
    final messenger = ScaffoldMessenger.of(context);
    final problem = FeedbackRules.validate(_message.text, _rating);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final failed = context.tr(
      'Could not send your feedback. Please try again.',
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.submitFeedback(
        role: widget.user.role,
        category: _category,
        message: _message.text,
        rating: _rating,
      );
      _message.clear();
      messenger.showSnackBar(SnackBar(content: Text(thanks)));
      if (mounted) setState(() => _rating = null);
    } catch (_) {
      if (mounted) setState(() => _error = failed);
    }
    if (mounted) setState(() => _busy = false);
  }

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
            Text(context.tr('Feedback'), style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              context.tr(
                'Your feedback is anonymous. Only your role is saved.',
              ),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SegmentedButton<FeedbackCategory>(
              segments: [
                for (final c in FeedbackCategory.values)
                  ButtonSegment(
                    value: c,
                    label: Text(context.tr(_categoryLabel(c))),
                  ),
              ],
              selected: {_category},
              onSelectionChanged: (s) => setState(() => _category = s.first),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('How would you rate the app? (optional)'),
              style: text.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 1; i <= 5; i++)
                  ChoiceChip(
                    label: Text('$i'),
                    avatar: const Icon(Icons.star, size: 16),
                    selected: _rating == i,
                    onSelected: (on) => setState(() => _rating = on ? i : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _message,
              minLines: 3,
              maxLines: 6,
              maxLength: FeedbackRules.maxMessageLength,
              decoration: InputDecoration(
                labelText: context.tr('Your message'),
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(context.tr(_error!), style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _busy ? null : _send,
                icon: const Icon(Icons.send_outlined),
                label: Text(context.tr('Send feedback')),
              ),
            ),
            const SizedBox(height: 32),
            Card.outlined(
              child: ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(context.tr('Usability survey')),
                subtitle: Text(
                  context.tr(
                    'Ten quick questions (about 2 minutes) to help evaluate this app.',
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SusPage(
                      user: widget.user,
                      repository: widget.repository,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
