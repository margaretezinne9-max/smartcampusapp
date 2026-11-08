import 'package:flutter/material.dart';

/// Loads data once and shows a spinner, an error with Retry, or the content.
class FutureView<T> extends StatefulWidget {
  const FutureView({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<FutureView<T>> createState() => _FutureViewState<T>();
}

class _FutureViewState<T> extends State<FutureView<T>> {
  late Future<T> _future = widget.load();

  void _retry() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 12),
                const Text('Could not load this page.'),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _retry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        return widget.builder(context, snapshot.requireData);
      },
    );
  }
}
