import 'package:flutter/material.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../widgets/app_logo.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/portal/portal_shell.dart';

/// Single entry point that decides what the user sees:
///   unknown          -> splash (restoring session)
///   unauthenticated  -> LoginPage
///   authenticated    -> PortalShell for the user's role
///
/// Role-specific destinations live in RoleRegistry, whose exhaustive
/// `switch` guarantees at compile time that every UserRole is handled.
class MainPortalRouter extends StatelessWidget {
  const MainPortalRouter({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final user = auth.user;

        final Widget page = switch (auth.status) {
          AuthStatus.unknown => const _SplashView(key: ValueKey('splash')),
          AuthStatus.unauthenticated => LoginPage(
            key: const ValueKey('login'),
            auth: auth,
          ),
          AuthStatus.authenticated => PortalShell(
            // Keyed by user id so a role switch never reuses old state.
            key: ValueKey('portal-${user!.id}'),
            user: user,
            onSignOut: auth.signOut,
          ),
        };

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: page,
        );
      },
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 72),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
