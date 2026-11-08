import 'package:flutter/foundation.dart';

import '../domain/assistant_models.dart';
import '../domain/assistant_service.dart';

/// Holds one student's conversation with the assistant.
class AssistantController extends ChangeNotifier {
  AssistantController(this._service);

  final AssistantService _service;
  final List<AssistantMessage> _messages = [];
  bool _busy = false;
  String? _error;

  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  bool get isBusy => _busy;
  String? get error => _error;
  bool get isDemo => _service.isDemo;

  Future<void> ask(String question) async {
    final text = question.trim();
    if (text.isEmpty || _busy) return;
    if (text.length > AcademicPolicy.maxQuestionLength) {
      _error = 'Your question is too long. Please shorten it.';
      notifyListeners();
      return;
    }

    _messages.add(AssistantMessage(text: text, fromUser: true));
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final reply = await _service.ask(text);
      _messages.add(
        AssistantMessage(
          text: reply.text,
          fromUser: false,
          refused: reply.refused,
        ),
      );
    } on AssistantException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'The assistant is unavailable right now. Please try again.';
    }

    _busy = false;
    notifyListeners();
  }

  void reset() {
    _messages.clear();
    _error = null;
    _service.reset();
    notifyListeners();
  }
}
