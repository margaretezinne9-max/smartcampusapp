import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../../../core/widgets/stream_view.dart';
import '../../auth/domain/app_user.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';
import 'campus_home_page.dart' show HomeShortcut;

/// Admin home: live counts and the "load demo data" action.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({
    super.key,
    required this.user,
    required this.repository,
    this.shortcuts = const [],
  });

  final AppUser user;
  final CampusRepository repository;
  final List<HomeShortcut> shortcuts;

  Future<void> _seed(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final loaded = context.tr('Demo data loaded. Students must sign in again.');
    final failed = context.tr('Could not load demo data: {error}');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Load demo data?')),
        content: Text(
          context.tr(
            'This adds two campuses, a weekly timetable, sample notices and enrolments for Computer Science level 400. It also assigns that department and level to every student and course rep. Set roles in the Users tab first.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('Load data')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await repository.seedDemoData();
      messenger.showSnackBar(SnackBar(content: Text(loaded)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(failed.replaceAll('{error}', '$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              context.tr('Welcome, {name}', {'name': user.firstName}),
              style: text.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('Publish notices and manage who can access what.'),
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 240,
                  child: StreamView<List<UserProfile>>(
                    open: repository.watchUsers,
                    builder: (context, users) => _StatCard(
                      icon: Icons.people_outline,
                      label: context.tr('Registered users'),
                      value: users.length,
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: StreamView<List<Notice>>(
                    open: repository.watchNotices,
                    builder: (context, notices) => _StatCard(
                      icon: Icons.campaign_outlined,
                      label: context.tr('Published notices'),
                      value: notices.length,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card.outlined(
              child: ListTile(
                leading: const Icon(Icons.dataset_outlined),
                title: Text(context.tr('Load demo data')),
                subtitle: Text(
                  context.tr(
                    'Sample campuses, timetable, notices and enrolments for testing and evaluation.',
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _seed(context),
              ),
            ),
            for (final shortcut in shortcuts)
              Card.outlined(
                child: ListTile(
                  leading: Icon(shortcut.icon),
                  title: Text(context.tr(shortcut.label)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => shortcut.open(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: text.titleLarge),
                  Text(label, style: text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
