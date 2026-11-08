import 'package:flutter/material.dart';

/// Every role the portal supports. Adding a value here forces the compiler
/// to flag every `switch` (e.g. in RoleRegistry) that must handle it.
enum UserRole {
  student('Student', Icons.school_outlined),
  lecturer('Lecturer', Icons.co_present_outlined),
  bursar('Bursar', Icons.account_balance_outlined),
  admin('Administrator', Icons.admin_panel_settings_outlined),
  courseRep('Course Rep', Icons.groups_outlined),
  aspirant('Aspirant', Icons.person_search_outlined);

  const UserRole(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Parses a role string coming from your backend / token claims.
  /// Unknown values fall back to the least-privileged role.
  static UserRole parse(String? value) => UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.aspirant,
  );
}
