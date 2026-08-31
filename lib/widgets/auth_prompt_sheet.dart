import 'package:flutter/material.dart';
import 'glass/liquid_glass.dart';

/// Which action the person picked in [showAuthPromptSheet] — or `null` if
/// they dismissed it / tapped "Continue Browsing".
enum AuthPromptChoice { login, createAccount }

/// The "modern login bottom sheet" guest users see when they tap a
/// restricted feature (favoriting, contacting an agent, sending an
/// enquiry, ...). Deliberately framed as an upgrade invitation rather than
/// a wall: browsing is never blocked, and "Continue Browsing" is always
/// one tap away.
///
/// Reuses the same frosted-glass language as Splash/Login/Register
/// ([LiquidGlass]/[LiquidGlassButton]) so this reads as part of the same
/// premium experience rather than a bolted-on system dialog.
Future<AuthPromptChoice?> showAuthPromptSheet(
  BuildContext context, {
  String title = 'Create your property journey',
  String description =
      'Sign in to save properties, contact agents, schedule visits, '
          'and receive personalized updates.',
}) {
  return showModalBottomSheet<AuthPromptChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) =>
        _AuthPromptSheet(title: title, description: description),
  );
}

class _AuthPromptSheet extends StatelessWidget {
  const _AuthPromptSheet({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: GlassDarkCard(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const GlassIconBadge(icon: Icons.villa_outlined),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            LiquidGlassButton(
              label: 'Login',
              icon: Icons.login_rounded,
              onTap: () => Navigator.of(context).pop(AuthPromptChoice.login),
            ),
            const SizedBox(height: 12),
            LiquidGlassButton(
              label: 'Create Account',
              icon: Icons.person_add_alt_1_rounded,
              filled: false,
              onTap: () =>
                  Navigator.of(context).pop(AuthPromptChoice.createAccount),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white60),
              child: const Text('Continue Browsing'),
            ),
          ],
        ),
      ),
    );
  }
}
