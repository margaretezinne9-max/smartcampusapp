import 'package:flutter/material.dart';

import '../l10n/translations.dart';

/// Shows live data from a Stream: spinner while waiting, a message on error,
/// otherwise [builder]. The stream is opened ONCE (not on every rebuild), so
/// parents can rebuild freely without re-subscribing.
class StreamView<T> extends StatefulWidget {
  const StreamView({super.key, required this.open, required this.builder});

  final Stream<T> Function() open;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<StreamView<T>> createState() => _StreamViewState<T>();
}

class _StreamViewState<T> extends State<StreamView<T>> {
  late final Stream<T> _stream = widget.open();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined),
                const SizedBox(height: 8),
                Text(context.tr('Could not load this data.')),
                const SizedBox(height: 4),
                Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.builder(context, snapshot.requireData);
      },
    );
  }
}
