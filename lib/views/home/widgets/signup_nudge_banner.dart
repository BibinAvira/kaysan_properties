import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/route_names.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/glass/liquid_glass.dart';

const String _dismissedPrefKey = 'signup_nudge_dismissed';

/// Tracks whether the person has dismissed the Home sign-up nudge, so it
/// doesn't reappear once they've said "not now". Kept as its own provider
/// (rather than local widget state) so the dismissal survives navigating
/// away from and back to Home within the same session.
class SignupNudgeDismissedController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dismissedPrefKey) ?? false;
  }

  Future<void> dismiss() async {
    state = const AsyncValue<bool>.data(true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedPrefKey, true);
  }
}

final AsyncNotifierProvider<SignupNudgeDismissedController, bool> signupNudgeDismissedProvider =
    AsyncNotifierProvider<SignupNudgeDismissedController, bool>(SignupNudgeDismissedController.new);

/// A soft, dismissible prompt encouraging sign-up — shown on Home only to
/// logged-out people who haven't dismissed it before. Browsing is never
/// blocked on this (App Store guideline 5.1.1(v)): it's just a nudge, not
/// a gate, and "Not now" makes it disappear for good.
class SignUpNudgeBanner extends ConsumerWidget {
  const SignUpNudgeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool loggedIn = ref.watch(authControllerProvider).valueOrNull != null;
    final bool dismissed = ref.watch(signupNudgeDismissedProvider).valueOrNull ?? true;
    if (loggedIn || dismissed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GlassDarkCard(
        borderRadius: 20,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(RouteNames.login),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              child: Row(
                children: <Widget>[
                  const GlassIconBadge(
                    icon: Icons.favorite_rounded,
                    size: 44,
                    iconSize: 20,
                    glow: true,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Sign up to save favorites',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sync your saved properties and track enquiries.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(signupNudgeDismissedProvider.notifier).dismiss(),
                    child: const Text('Not now', style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
