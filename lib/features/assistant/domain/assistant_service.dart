import 'assistant_models.dart';

/// Anything that can answer an academic question. Two implementations:
/// a small offline demo and Gemini through Firebase AI Logic.
abstract interface class AssistantService {
  Future<AssistantReply> ask(String question);

  /// Forgets the conversation so far.
  void reset();

  /// True when answers come from the built-in demo, not a real AI.
  bool get isDemo;
}
