import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../domain/assistant_models.dart';
import 'assistant_controller.dart';

/// Academic assistant: a chat that only answers study questions and always
/// reminds the student to verify answers with their lecturers.
class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key, required this.controller});

  final AssistantController controller;

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    await widget.controller.ask(text);
  }

  String _disclaimer(BuildContext context, bool demo) {
    final base = context.tr(
      'AI answers can contain mistakes. Check important information with your lecturers.',
    );
    if (!demo) return base;
    final note = context.tr(
      'Demo mode: answers come from a small built-in list, not a real AI.',
    );
    return '$base\n$note';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final items = controller.messages.reversed.toList();
        final busy = controller.isBusy;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card.filled(
                    color: scheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: scheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _disclaimer(context, controller.isDemo),
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (items.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: TextButton.icon(
                        onPressed: busy ? null : controller.reset,
                        icon: const Icon(Icons.refresh),
                        label: Text(context.tr('New conversation')),
                      ),
                    ),
                  ),
                Expanded(
                  child: items.isEmpty && !busy
                      ? _Welcome(onPick: _send)
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length + (busy ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (busy && i == 0) {
                              return _Bubble(
                                text: context.tr('Thinking...'),
                                fromUser: false,
                              );
                            }
                            final m = items[busy ? i - 1 : i];
                            return _Bubble(
                              text: m.refused
                                  ? context.tr(
                                      'I can only help with academic questions: course content, study methods and exam revision.',
                                    )
                                  : m.text,
                              fromUser: m.fromUser,
                              refused: m.refused,
                            );
                          },
                        ),
                ),
                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      context.tr(controller.error!),
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: AcademicPolicy.maxQuestionLength,
                          decoration: InputDecoration(
                            hintText: context.tr('Ask a question'),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: context.tr('Send'),
                        onPressed: busy ? null : _send,
                        icon: const Icon(Icons.send),
                      ),
                    ],
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

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onPick});

  final Future<void> Function([String?]) onPick;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 48, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              context.tr(
                'Ask me about your courses, exam revision and study methods.',
              ),
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(context.tr('Try asking'), style: text.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final s in AcademicPolicy.suggestions)
                  ActionChip(
                    label: Text(context.tr(s)),
                    onPressed: () => onPick(context.tr(s)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.fromUser,
    this.refused = false,
  });

  final String text;
  final bool fromUser;
  final bool refused;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = fromUser
        ? scheme.primaryContainer
        : refused
        ? scheme.errorContainer
        : scheme.surfaceContainerHighest;
    final foreground = fromUser
        ? scheme.onPrimaryContainer
        : refused
        ? scheme.onErrorContainer
        : scheme.onSurface;

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: TextStyle(color: foreground)),
      ),
    );
  }
}
