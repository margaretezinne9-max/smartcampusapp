import 'package:flutter/foundation.dart';

import '../domain/admission_repository.dart';
import '../domain/application_models.dart';

/// Shared by the Application and Admission tabs so both stay in sync.
class ApplicationController extends ChangeNotifier {
  ApplicationController(this._repository, this._userId);

  final AdmissionRepository _repository;
  final String _userId;

  Application? _application;
  bool _busy = false;
  String? _error;

  Application? get application => _application;
  bool get isBusy => _busy;
  String? get error => _error;

  Future<void> load() async {
    _error = null;
    notifyListeners();
    try {
      _application = await _repository.load(_userId);
    } catch (_) {
      _error = 'Could not load your application.';
    }
    notifyListeners();
  }

  Future<bool> saveDraft(Application draft) =>
      _run(() => _repository.saveDraft(_userId, draft));

  Future<bool> submit(Application draft) =>
      _run(() => _repository.submit(_userId, draft));

  Future<bool> _run(Future<Application> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    var ok = true;
    try {
      _application = await action();
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
      ok = false;
    }
    _busy = false;
    notifyListeners();
    return ok;
  }
}
