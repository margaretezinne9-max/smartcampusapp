import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/brand.dart';
import '../../auth/domain/app_user.dart';
import 'settings_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user, required this.onSignOut});

  final AppUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final settings = AppSettingsScope.maybeOf(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF075B36), Color(0xFF033E25)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF075B36).withValues(alpha: .16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: const Color(0xFFFFC629),
                      foregroundColor: const Color(0xFF033E25),
                      child: Text(
                        user.initials,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.name,
                      style: text.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: text.bodyMedium?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      avatar: Icon(
                        user.role.icon,
                        size: 17,
                        color: const Color(0xFF075B36),
                      ),
                      label: Text(
                        context.tr(user.role.label),
                        style: const TextStyle(
                          color: Color(0xFF075B36),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      kUniversityName,
                      style: TextStyle(
                        color: Color(0xFFFFD45A),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
              ),
              if (settings != null) ...[
                const SizedBox(height: 24),
                SettingsCard(settings: settings),
              ],
              const SizedBox(height: 24),
              Center(
                child: FilledButton.tonalIcon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  label: Text(context.tr('Sign out')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
