import '../domain/assistant_models.dart';
import '../domain/assistant_service.dart';

class _Topic {
  const _Topic(this.keywords, this.answer);
  final List<String> keywords;
  final String answer;
}

/// Demo assistant that needs no internet and no AI. It knows a handful of
/// topics, refuses obviously non-academic requests and otherwise says it
/// does not know. It exists so the screen and the rules can be tried offline.
class OfflineAssistantService implements AssistantService {
  static const _offTopic = [
    'football',
    'soccer',
    'movie',
    'music',
    'lyrics',
    'dating',
    'girlfriend',
    'boyfriend',
    'recipe',
    'betting',
    'politic',
    'gossip',
    'celebrity',
    'weather',
    'joke',
    'tiktok',
    'instagram',
    'bitcoin',
  ];

  static const _topics = [
    _Topic(
      ['deadlock', 'interblocage'],
      '''
A deadlock happens when two or more processes each hold a resource and wait for a resource held by another, so none of them can continue.

It needs four conditions at the same time: mutual exclusion, hold and wait, no preemption, and circular wait. Removing any one of them prevents deadlock. A common fix is to make every process request resources in the same fixed order.''',
    ),
    _Topic(
      ['normalization', 'normalisation', 'normal form'],
      '''
Normalization organises tables to reduce redundancy and update anomalies.

1NF: every field holds a single value, with no repeating groups.
2NF: 1NF, and every non-key field depends on the whole key, not only part of it.
3NF: 2NF, and non-key fields depend only on the key, not on other non-key fields.''',
    ),
    _Topic(
      ['compiler', 'compile'],
      '''
A compiler translates source code into another form, usually machine code, in phases: lexical analysis (tokens), syntax analysis (parse tree), semantic analysis (types and meaning), intermediate code generation, optimisation, and code generation.''',
    ),
    _Topic(
      ['big o', 'big-o', 'complexity'],
      '''
Big O describes how running time or memory grows as the input size n grows.

O(1) constant, O(log n) such as binary search, O(n) such as a linear search, O(n log n) such as merge sort, O(n^2) such as simple nested-loop sorts.''',
    ),
    _Topic(
      ['osi'],
      '''
The OSI model has seven layers, from bottom to top: Physical, Data Link, Network, Transport, Session, Presentation, Application.''',
    ),
    _Topic(
      ['recursion', 'recursive'],
      '''
Recursion is when a function solves a problem by calling itself on a smaller version of the problem. It needs a base case that stops the calls and a recursive case that moves toward it. Example: factorial(n) = n x factorial(n - 1), with factorial(0) = 1.''',
    ),
    _Topic(
      ['revise', 'revision', 'réviser', 'révision', 'exam tips', 'study'],
      '''
Revision tips: work backwards from your exam dates and write a timetable; practise with past questions; test yourself instead of only re-reading; review topics again after a few days (spaced repetition); take short breaks and sleep well before the exam.''',
    ),
  ];

  static const _notKnown = '''
I do not have a verified answer to that in demo mode, so I will not guess. In demo mode I only know a few topics: deadlock, database normalization, compilers, Big O, the OSI model, recursion and exam revision. Please check your textbook or ask your lecturer.''';

  @override
  bool get isDemo => true;

  @override
  Future<AssistantReply> ask(String question) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final text = question.toLowerCase();

    if (_offTopic.any(text.contains)) return const AssistantReply.refused();

    for (final topic in _topics) {
      if (topic.keywords.any(text.contains)) {
        return AssistantReply(topic.answer.trim());
      }
    }
    return const AssistantReply(_notKnown);
  }

  @override
  void reset() {}
}
