import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/l10n/translations.dart';
import '../../core/widgets/app_logo.dart';
import '../auth/domain/app_user.dart';
import '../auth/domain/user_role.dart';
import '../campus/campus_service.dart';
import '../campus/presentation/reminder_banner.dart';
import 'pages/dashboard_page.dart';
import 'pages/module_page.dart';
import 'pages/profile_page.dart';
import 'role_registry.dart';

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon, this.page);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

/// Adaptive scaffold: bottom NavigationBar on phones, NavigationRail on
/// tablets / desktop web. Tabs are built from the user's role. Roles that
/// have a timetable also get the class-reminder banner above every tab.
class PortalShell extends StatefulWidget {
  const PortalShell({super.key, required this.user, required this.onSignOut});

  final AppUser user;
  final VoidCallback onSignOut;

  @override
  State<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends State<PortalShell> {
  int _index = 0;

  static const _rolesWithTimetable = {
    UserRole.student,
    UserRole.courseRep,
    UserRole.lecturer,
  };

  late final RoleConfig _config = RoleRegistry.of(widget.user.role);

  late final List<_Tab> _tabs = [
    _Tab(
      'Home',
      Icons.dashboard_outlined,
      Icons.dashboard,
      _config.homeBuilder?.call(widget.user) ??
          DashboardPage(user: widget.user, config: _config),
    ),
    for (final m in _config.modules)
      _Tab(
        m.label,
        m.icon,
        m.selectedIcon,
        m.pageBuilder?.call(widget.user) ?? ModulePage(module: m),
      ),
    _Tab(
      'Profile',
      Icons.person_outline,
      Icons.person,
      ProfilePage(user: widget.user, onSignOut: widget.onSignOut),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showReminders = _rolesWithTimetable.contains(widget.user.role);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;

        final isHomeTab = _index == 0;
        final content = Column(
          children: [
            if (showReminders && !isHomeTab)
              ReminderBanner(user: widget.user, repository: campusRepository),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [for (final t in _tabs) t.page],
              ),
            ),
          ],
        );

        return Scaffold(
          appBar: isHomeTab
              ? null
              : AppBar(
                  title: const Row(
                    children: [
                      AppLogo(size: 32),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          kUniversityName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Chip(
                        avatar: Icon(widget.user.role.icon, size: 18),
                        label: Text(context.tr(widget.user.role.label)),
                        backgroundColor: scheme.secondaryContainer,
                      ),
                    ),
                  ],
                ),
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _index,
                      extended: constraints.maxWidth >= 1100,
                      labelType: constraints.maxWidth >= 1100
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      onDestinationSelected: (i) => setState(() => _index = i),
                      destinations: [
                        for (final t in _tabs)
                          NavigationRailDestination(
                            icon: Icon(t.icon),
                            selectedIcon: Icon(t.selectedIcon),
                            label: Text(context.tr(t.label)),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final t in _tabs)
                      NavigationDestination(
                        icon: Icon(t.icon),
                        selectedIcon: Icon(t.selectedIcon),
                        label: context.tr(t.label),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
