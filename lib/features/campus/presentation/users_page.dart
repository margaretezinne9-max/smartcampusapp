import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../../../core/widgets/stream_view.dart';
import '../../auth/domain/user_role.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';

/// Admin tab: see every account and change its role.
class UsersPage extends StatelessWidget {
  const UsersPage({
    super.key,
    required this.repository,
    required this.currentUserId,
  });

  final CampusRepository repository;
  final String currentUserId;

  Future<void> _change(
    BuildContext context,
    UserProfile u,
    UserRole role,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = context.tr('{name} is now {role}.', {
      'name': u.name,
      'role': context.tr(role.label),
    });
    final failed = context.tr('Could not change the role.');
    try {
      await repository.updateUserRole(u.id, role);
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  String _subtitle(BuildContext context, UserProfile u) {
    final department = u.department;
    if (department == null) return u.email;
    final audience = context.tr('{department}, level {level}', {
      'department': department,
      'level': '${u.level ?? '-'}',
    });
    return '${u.email}\n$audience';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return StreamView<List<UserProfile>>(
      open: repository.watchUsers,
      builder: (context, users) {
        final sorted = [
          ...users,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(context.tr('Users'), style: text.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  context.tr(
                    'Change a role to give someone a different dashboard. They must sign in again to see it.',
                  ),
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                for (final u in sorted)
                  Card.outlined(
                    child: ListTile(
                      title: Text(u.name),
                      isThreeLine: u.department != null,
                      subtitle: Text(_subtitle(context, u)),
                      trailing: u.id == currentUserId
                          ? Text(context.tr('You'))
                          : DropdownButton<UserRole>(
                              value: u.role,
                              onChanged: (role) {
                                if (role != null && role != u.role) {
                                  _change(context, u, role);
                                }
                              },
                              items: [
                                for (final r in UserRole.values)
                                  DropdownMenuItem(
                                    value: r,
                                    child: Text(context.tr(r.label)),
                                  ),
                              ],
                            ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
