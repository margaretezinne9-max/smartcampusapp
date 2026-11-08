import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../../../core/settings/app_settings.dart';

/// Language, theme and class-reminder settings, saved on the device.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('Settings'), style: text.titleMedium),
            const SizedBox(height: 16),
            Text(context.tr('Language'), style: text.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'fr', label: Text('Français')),
              ],
              selected: {settings.language},
              onSelectionChanged: (s) => settings.setLanguage(s.first),
            ),
            const SizedBox(height: 16),
            Text(context.tr('Theme'), style: text.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(context.tr('System')),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(context.tr('Light')),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(context.tr('Dark')),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
            const SizedBox(height: 16),
            Text(context.tr('Class reminder'), style: text.labelLarge),
            const SizedBox(height: 4),
            DropdownButton<int>(
              value: settings.reminderMinutes,
              isExpanded: true,
              onChanged: (m) {
                if (m != null) settings.setReminderMinutes(m);
              },
              items: [
                for (final m in AppSettings.reminderOptions)
                  DropdownMenuItem(
                    value: m,
                    child: Text(
                      m == 0
                          ? context.tr('Off')
                          : context.tr('{n} min before class', {'n': '$m'}),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('Reminders appear in the app while it is open.'),
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
