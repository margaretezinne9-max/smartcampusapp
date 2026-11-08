import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../../auth/domain/app_user.dart';
import '../role_registry.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.user, required this.config});

  final AppUser user;
  final RoleConfig config;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              context.tr('Welcome, {name}', {'name': user.firstName}),
              style: text.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              context.tr(config.tagline),
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final s in config.stats)
                  SizedBox(
                    width: 280,
                    child: Card.filled(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(s.icon, color: scheme.primary),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(s.value),
                                    style: text.titleLarge,
                                  ),
                                  Text(
                                    context.tr(s.label),
                                    style: text.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Text(context.tr('Quick actions'), style: text.titleMedium),
            const SizedBox(height: 8),
            for (final a in config.actions)
              Card.outlined(
                child: ListTile(
                  leading: Icon(a.icon),
                  title: Text(context.tr(a.title)),
                  subtitle: Text(context.tr(a.subtitle)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, // TODO: push the feature screen
                ),
              ),
          ],
        ),
      ),
    );
  }
}
