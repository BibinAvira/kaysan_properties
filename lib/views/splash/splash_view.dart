import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass/liquid_glass.dart';

/// Welcome / splash screen — a full-bleed hero photo with a dark gradient
/// scrim and the guest-access decision: "Explore Properties" (browse as a
/// guest, no account needed) or "Login / Create Account" for people who
/// already have — or want to start — an account.
///
/// While the screen is up, [AuthController] silently checks secure storage
/// for a saved session. If one is found and still valid, the person is
/// already signed in ("keep me logged in") and this screen is skipped
/// entirely — they land straight on Home once the minimum splash time has
/// passed. Everyone else sees the two-button decision below.
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  bool _minSplashElapsed = false;
  bool _navigatedHome = false;

  @override
  void initState() {
    super.initState();

    // One-shot fade + slide entrance for the button block.
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn =
        CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic));

    // Give the splash a minimum on-screen time so it doesn't flash by
    // instantly for already-logged-in users, even once the session check
    // resolves faster than that.
    Future.delayed(const Duration(milliseconds: AppConstants.splashDurationMs),
        () {
      if (!mounted) return;
      setState(() => _minSplashElapsed = true);
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  /// "Explore Properties" always opens Home as a guest — browsing
  /// properties never requires an account (App Store guideline 5.1.1(v)).
  /// Signing in/up is still one tap away — either right here or later from
  /// the More tab — whenever someone wants to save favorites, contact an
  /// agent, or manage a profile.
  void _exploreAsGuest() => context.go(RouteNames.home);

  void _loginOrCreateAccount() => context.push(RouteNames.login);

  @override
  Widget build(BuildContext context) {
    final AsyncValue<UserModel?> authState = ref.watch(authControllerProvider);
    final bool sessionResolved = !authState.isLoading;
    final bool loggedIn = authState.valueOrNull != null;

    // Already logged in — skip the button entirely and go straight to
    // Home once the minimum splash time has passed.
    if (_minSplashElapsed && sessionResolved && loggedIn && !_navigatedHome) {
      _navigatedHome = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(RouteNames.home);
      });
    }

    final bool showChecking =
        !_minSplashElapsed || !sessionResolved || loggedIn;

    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// Background Image
          Image.asset(
            "assets/images/splash.png",
            fit: BoxFit.cover,
          ),

          // Bottom scrim so the two-button decision block always reads
          // clearly against the photo, however much of it the buttons
          // end up covering — a soft fade rather than a hard clip.
          const Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0x00000000), Color(0xB3000000)],
                ),
              ),
              child: SizedBox(width: double.infinity, height: 260),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: Column(
                children: [
                  const Spacer(),
                  FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: showChecking
                            ? const _CheckingSessionIndicator(
                                key: ValueKey('checking'))
                            : Column(
                                key: const ValueKey('decision'),
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  LiquidGlassButton(
                                    label: 'Explore Properties',
                                    icon: Icons.explore_outlined,
                                    height: 54,
                                    onTap: _exploreAsGuest,
                                  ),
                                  const SizedBox(height: 10),
                                  LiquidGlassButton(
                                    label: 'Login / Create Account',
                                    icon: Icons.person_outline,
                                    filled: false,
                                    height: 54,
                                    onTap: _loginOrCreateAccount,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small glass pill shown in place of the "Get Started" button while the
/// app checks secure storage for a saved session, so the screen doesn't
/// look frozen or empty during that brief moment.
class _CheckingSessionIndicator extends StatelessWidget {
  const _CheckingSessionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: 30,
      blur: 20,
      tintOpacity: 0.08,
      shadow: false,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child:
              CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
        ),
      ),
    );
  }
}
