import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../../core/ai_config.dart';
import '../domain/assistant_models.dart';
import '../domain/assistant_service.dart';

/// Gemini through Firebase AI Logic. The API key never lives in the app:
/// Firebase's service proxy holds it. Requires `kUseFirebase = true`,
/// Firebase AI Logic switched on in the Firebase console, and the
/// firebase_ai package.
///
/// Every question is sent as one self-contained request together with the last
/// few turns kept here. If a request fails, nothing is added to that history,
/// so one failure can never break the next question. When a model is busy or
/// unavailable, the next model in [kAssistantModels] is tried.
class GeminiAssistantService implements AssistantService {
  /// One attempt longer than this is abandoned and the next model is tried.
  static const _timeout = Duration(seconds: 30);

  /// Question-and-answer pairs kept as context for follow-up questions.
  static const _turnsKept = 5;

  final Map<String, GenerativeModel> _models = {};
  final List<Content> _history = [];

  @override
  bool get isDemo => false;

  GenerativeModel _buildModel(String name) =>
      FirebaseAI.googleAI().generativeModel(
        model: name,
        systemInstruction: Content.system(AcademicPolicy.systemPrompt),
        // Newer Gemini models count their internal "thinking" toward this
        // limit, so keep it generous or answers can come back empty.
        generationConfig: GenerationConfig(
          maxOutputTokens: 2048,
          temperature: 0.3,
        ),
      );

  /// Server-side trouble where another model may still work.
  bool _worthTryingAnotherModel(Object error) {
    final text = error.toString().toLowerCase();
    return const [
      '500',
      '503',
      'high demand',
      'overloaded',
      'unavailable',
      'internal',
      '404',
      'not found',
      ..._quotaWords,
    ].any(text.contains);
  }

  /// The free plan has per-minute and per-day limits for each model.
  static const _quotaWords = [
    '429',
    'quota',
    'resource_exhausted',
    'resource-exhausted',
    'rate limit',
  ];

  bool _isQuotaError(Object error) {
    final text = error.toString().toLowerCase();
    return _quotaWords.any(text.contains);
  }

  @override
  Future<AssistantReply> ask(String question) async {
    final stopwatch = Stopwatch()..start();
    var timedOut = false;
    var quotaHit = false;

    for (final name in kAssistantModels) {
      try {
        final model = _models[name] ??= _buildModel(name);
        final response = await model
            .generateContent([..._history, Content.text(question)])
            .timeout(_timeout);
        debugPrint(
          'Gemini ($name) answered in ${stopwatch.elapsedMilliseconds} ms',
        );

        final text = response.text?.trim() ?? '';
        if (text.isEmpty) {
          debugPrint(
            'Gemini returned no text. Finish reasons: '
            '${response.candidates.map((c) => c.finishReason).toList()}',
          );
          throw const AssistantException(
            'The assistant did not return an answer. Try rephrasing your question.',
          );
        }
        if (AcademicPolicy.isRefusal(text))
          return const AssistantReply.refused();

        _remember(question, text);
        return AssistantReply(text);
      } on AssistantException {
        rethrow;
      } on TimeoutException {
        timedOut = true;
        debugPrint(
          'Gemini ($name) timed out after ${stopwatch.elapsedMilliseconds} ms',
        );
      } catch (e) {
        // The screen shows a short friendly message; the real reason is
        // printed in the terminal (run window) so you can see what to fix.
        debugPrint(
          'Gemini ($name) error after ${stopwatch.elapsedMilliseconds} ms: '
          '${e.runtimeType}: $e',
        );
        if (!_worthTryingAnotherModel(e)) {
          throw const AssistantException(
            'The assistant is unavailable right now. Please try again.',
          );
        }
        timedOut = false;
        if (_isQuotaError(e)) quotaHit = true;
      }
    }

    throw AssistantException(
      quotaHit
          ? 'The assistant has reached its free usage limit for now. Please try again later.'
          : timedOut
          ? 'The assistant took too long to answer. Please try again.'
          : 'The assistant is very busy right now. Please try again in a minute.',
    );
  }

  void _remember(String question, String answer) {
    _history
      ..add(Content.text(question))
      ..add(Content.model([TextPart(answer)]));
    final maxItems = _turnsKept * 2;
    if (_history.length > maxItems) {
      _history.removeRange(0, _history.length - maxItems);
    }
  }

  @override
  void reset() => _history.clear();
}
