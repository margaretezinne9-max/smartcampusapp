import 'package:flutter/material.dart';

import '../aspirant/aspirant_tabs.dart';
import '../assistant/assistant_tabs.dart';
import '../auth/domain/app_user.dart';
import '../auth/domain/user_role.dart';
import '../campus/campus_tabs.dart';
import '../chat/chat_tabs.dart';

/// Builds a role module's real screen. When null, a placeholder is shown.
typedef ModulePageBuilder = Widget Function(AppUser user);

class PortalModule {
  const PortalModule({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.description,
    this.pageBuilder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String description;
  final ModulePageBuilder? pageBuilder;
}

class StatSpec {
  const StatSpec(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class ActionSpec {
  const ActionSpec(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final IconData icon;
}

class RoleConfig {
  const RoleConfig({
    required this.tagline,
    required this.modules,
    this.stats = const [],
    this.actions = const [],
    this.homeBuilder,
  });

  final String tagline;

  /// Role-specific tabs. The shell adds Home first and Profile last,
  /// so keep this at 1-3 entries (Material NavigationBar allows 3-5 tabs).
  final List<PortalModule> modules;

  /// Used by the generic dashboard when [homeBuilder] is null.
  final List<StatSpec> stats;
  final List<ActionSpec> actions;

  /// A role's own Home screen. When null the generic DashboardPage is shown.
  final ModulePageBuilder? homeBuilder;
}

/// Maps each role to its dashboard content and navigation.
/// The switch is exhaustive: adding a UserRole without a config won't compile.
abstract final class RoleRegistry {
  static RoleConfig of(UserRole role) => switch (role) {
    UserRole.student => const RoleConfig(
      tagline: 'Your timetable, chats and study help in one place.',
      homeBuilder: buildCampusHome,
      modules: [
        PortalModule(
          label: 'Timetable',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
          description: 'Your weekly classes with hall and campus.',
          pageBuilder: buildTimetable,
        ),
        PortalModule(
          label: 'Chat',
          icon: Icons.forum_outlined,
          selectedIcon: Icons.forum,
          description: 'Course chats with your lecturers and classmates.',
          pageBuilder: buildChat,
        ),
        PortalModule(
          label: 'Assistant',
          icon: Icons.smart_toy_outlined,
          selectedIcon: Icons.smart_toy,
          description: 'Ask academic questions and get study help.',
          pageBuilder: buildAssistant,
        ),
      ],
    ),
    UserRole.lecturer => const RoleConfig(
      tagline: 'Your classes, locations and students.',
      homeBuilder: buildCampusHome,
      modules: [
        PortalModule(
          label: 'Timetable',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
          description: 'The classes you teach, with hall and campus.',
          pageBuilder: buildTimetable,
        ),
        PortalModule(
          label: 'Students',
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          description: 'Students enrolled in your courses.',
          pageBuilder: buildLecturerStudents,
        ),
        PortalModule(
          label: 'Chat',
          icon: Icons.forum_outlined,
          selectedIcon: Icons.forum,
          description: 'Message the students of your courses.',
          pageBuilder: buildChat,
        ),
      ],
    ),
    UserRole.bursar => const RoleConfig(
      tagline: 'Track fee payments, receipts and reconciliation.',
      stats: [
        StatSpec('Collected today', '₦4.2M', Icons.payments_outlined),
        StatSpec('Pending verifications', '23', Icons.pending_actions),
        StatSpec('Defaulters', '118', Icons.warning_amber_outlined),
      ],
      actions: [
        ActionSpec(
          'Verify payments',
          'Match bank and gateway records',
          Icons.fact_check_outlined,
        ),
        ActionSpec(
          'Generate report',
          'Daily and semester summaries',
          Icons.summarize_outlined,
        ),
      ],
      modules: [
        PortalModule(
          label: 'Payments',
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments,
          description: 'Incoming payments and verification queue.',
        ),
        PortalModule(
          label: 'Receipts',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          description: 'Issue, search and reprint receipts.',
        ),
      ],
    ),
    UserRole.admin => const RoleConfig(
      tagline: 'Publish notices and manage who can access what.',
      homeBuilder: buildAdminHome,
      modules: [
        PortalModule(
          label: 'Notices',
          icon: Icons.campaign_outlined,
          selectedIcon: Icons.campaign,
          description: 'Publish and remove notices and events.',
          pageBuilder: buildAdminNotices,
        ),
        PortalModule(
          label: 'Users',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          description: 'See every account and change its role.',
          pageBuilder: buildAdminUsers,
        ),
      ],
    ),
    UserRole.courseRep => const RoleConfig(
      tagline: 'Keep your class informed and organised.',
      homeBuilder: buildCampusHome,
      modules: [
        PortalModule(
          label: 'Timetable',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
          description: 'Your class timetable with hall and campus.',
          pageBuilder: buildTimetable,
        ),
        PortalModule(
          label: 'Chat',
          icon: Icons.forum_outlined,
          selectedIcon: Icons.forum,
          description: 'Course chats with your lecturers and classmates.',
          pageBuilder: buildChat,
        ),
        PortalModule(
          label: 'Assistant',
          icon: Icons.smart_toy_outlined,
          selectedIcon: Icons.smart_toy,
          description: 'Ask academic questions and get study help.',
          pageBuilder: buildAssistant,
        ),
      ],
    ),
    UserRole.aspirant => const RoleConfig(
      tagline: 'Complete your application to Hill City University.',
      stats: [
        StatSpec('Application', 'In progress', Icons.edit_document),
        StatSpec('Documents uploaded', '2 of 5', Icons.upload_file_outlined),
        StatSpec('Admission status', 'Pending', Icons.hourglass_empty),
      ],
      actions: [
        ActionSpec(
          'Continue application',
          'Pick up where you stopped',
          Icons.assignment_outlined,
        ),
        ActionSpec(
          'Pay application fee',
          'Required before submission',
          Icons.credit_card_outlined,
        ),
      ],
      modules: [
        PortalModule(
          label: 'Application',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          description: 'Personal details, programme choice and documents.',
          pageBuilder: buildAspirantApplication,
        ),
        PortalModule(
          label: 'Admission',
          icon: Icons.verified_outlined,
          selectedIcon: Icons.verified,
          description: 'Check your admission decision and next steps.',
          pageBuilder: buildAspirantAdmission,
        ),
      ],
    ),
  };
}
