import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../role_registry.dart';

/// Placeholder for each role's feature module. Replace the body with the
/// real feature screen as you build it out.
class ModulePage extends StatelessWidget {
  const ModulePage({super.key, required this.module});

  final PortalModule module;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(module.selectedIcon, size: 56, color: scheme.primary),
            const SizedBox(height: 16),
            Text(context.tr(module.label), style: text.headlineSmall),
            const SizedBox(height: 8),
            Text(
              context.tr(module.description),
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
