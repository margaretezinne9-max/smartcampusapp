import 'dart:async';

/// A value that can be watched: every new listener receives the current value
/// at once, then every later change. Used by the in-memory (demo) repositories
/// to behave like Firestore snapshot streams.
class LiveValue<T> {
  LiveValue(this._value);

  T _value;
  final _changes = StreamController<T>.broadcast();

  T get value => _value;

  set value(T v) {
    _value = v;
    _changes.add(v);
  }

  Stream<T> watch() {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;
    controller = StreamController<T>(
      onListen: () {
        controller.add(_value);
        subscription = _changes.stream.listen(controller.add);
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }
}
