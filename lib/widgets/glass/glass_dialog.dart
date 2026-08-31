import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'liquid_glass.dart';

/// Matches [showGlassDialog]'s `transitionDuration`. Callers that mutate
/// state (or start another async operation) right after a glass dialog
/// closes should `await Future<void>.delayed(glassDialogTransitionDuration)`
/// first — see profile_view.dart's delete-account flow for why: touching
/// state while the dialog's own exit transition is still in flight can
/// race Flutter's internal listener cleanup and trip a framework
/// assertion, reproduced on-device before that delay was added.
const Duration glassDialogTransitionDuration = Duration(milliseconds: 220);

/// Custom Liquid-Glass-themed replacement for [showDialog]/[AlertDialog] —
/// a blurred, darkened backdrop behind a [GlassDarkCard] panel, matching
/// the same premium look as [showAuthPromptSheet] instead of the default
/// platform dialog chrome. Fully owns its own tap-to-dismiss (rather than
/// layering on top of the framework's barrier) so the blur can animate in
/// step with the fade/scale.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: glassDialogTransitionDuration,
    pageBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      // showDialog/AlertDialog provide a Material ancestor for free; this
      // custom replacement needs to do it explicitly so Material-dependent
      // descendants (TextField, TextButton, ...) don't break — reproduced
      // on-device as a "No Material widget found" render error without it.
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Material(
              type: MaterialType.transparency,
              child: Builder(builder: builder),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) {
      final double t = Curves.easeOutCubic.transform(animation.value);
      return Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: barrierDismissible
                  ? () => Navigator.of(context).maybePop()
                  : null,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14 * t, sigmaY: 14 * t),
                child: Container(color: Colors.black.withValues(alpha: 0.55 * t)),
              ),
            ),
          ),
          Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
          ),
        ],
      );
    },
  );
}

/// Dialog content matching [GlassDarkCard]'s look — an optional icon
/// badge, title, message, and a vertical stack of actions (mirroring
/// [showAuthPromptSheet]'s primary/secondary/tertiary [LiquidGlassButton]
/// layout, already the app's established dialog-button convention, rather
/// than a horizontal row of platform TextButtons).
class GlassAlertDialog extends StatelessWidget {
  const GlassAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.icon,
    this.iconColor = AppColors.goldLight,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
  final IconData? icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GlassDarkCard(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            GlassIconBadge(icon: icon!, color: iconColor),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          DefaultTextStyle(
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 14, height: 1.4),
            child: content,
          ),
          const SizedBox(height: 22),
          ...actions,
        ],
      ),
    );
  }
}
