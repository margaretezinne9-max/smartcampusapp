import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/translations.dart';
import '../domain/campus_models.dart';

/// Bottom sheet with the hall, the campus and how to get there.
/// The written directions are always shown, so they work even when Google
/// Maps cannot be opened.
Future<void> showCampusInfo(
  BuildContext context, {
  required ClassSlot slot,
  Campus? campus,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _CampusInfoSheet(slot: slot, campus: campus),
  );
}

class _CampusInfoSheet extends StatelessWidget {
  const _CampusInfoSheet({required this.slot, required this.campus});

  final ClassSlot slot;
  final Campus? campus;

  Future<void> _openMaps(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.tr(
      'Could not open Google Maps. Use the written directions.',
    );
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final info = campus;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // Add assets/images/campus_<id>.jpg to show a photo here.
                  child: Image.asset(
                    'assets/images/campus_${info.id}.jpg',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            Text(slot.hallName, style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              slot.campusName,
              style: text.titleMedium?.copyWith(color: scheme.primary),
            ),
            const SizedBox(height: 16),
            if (info == null)
              Text(
                context.tr(
                  'No directions have been added for this campus yet.',
                ),
              )
            else ...[
              Text(info.address, style: text.bodyMedium),
              const SizedBox(height: 16),
              Text(context.tr('How to get there'), style: text.titleSmall),
              const SizedBox(height: 4),
              Text(
                info.directions.isEmpty
                    ? context.tr('No written directions yet.')
                    : info.directions,
              ),
              if (info.mapsUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openMaps(context, info.mapsUrl),
                  icon: const Icon(Icons.directions_outlined),
                  label: Text(context.tr('Open in Google Maps')),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
