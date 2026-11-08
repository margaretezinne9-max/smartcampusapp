import 'package:flutter/material.dart';

import '../brand.dart';

/// The university logo. Falls back to an icon when the image is not available,
/// so the app works before the real logo is added.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kLogoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.location_city,
        size: size,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
