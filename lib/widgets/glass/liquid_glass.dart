library liquid_glass;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

/// Shared "Apple Liquid Glass" building blocks.
///
/// Every glass surface in the app — the floating bottom nav, the home
/// search bar, category chips, floating icon buttons, and the property
/// overlay badges — is built from these three primitives so the frosted
/// look, blur strength and highlight/shadow treatment stay identical
/// everywhere instead of being re-implemented per widget.

/// A true frosted-glass surface: real backdrop blur (not just a
/// translucent color), a soft white top-highlight to fake a glass
/// reflection, a hairline border, and a very soft ambient shadow so it
/// reads as floating above the content rather than glued to it.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 30,
    this.blur = 30,
    this.tint = Colors.white,
    this.tintOpacity = 0.15,
    this.borderOpacity = 0.28,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.shadow = true,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final Color tint;
  final double tintOpacity;
  final double borderOpacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: shadow
          ? BoxDecoration(
              borderRadius: radius,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: tint.withValues(alpha: tintOpacity),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.white.withValues(alpha: tintOpacity + 0.10),
                  Colors.white.withValues(alpha: tintOpacity * 0.4),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: borderOpacity),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A circular frosted-glass icon button — used for the notification bell,
/// search filter button, favourite hearts, back button and every other
/// floating round control that sits on top of a photo or content.
class LiquidGlassCircle extends StatelessWidget {
  const LiquidGlassCircle({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.iconColor = Colors.white,
    this.blur = 24,
    this.tintOpacity = 0.16,
    this.filled = false,
    this.fillColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color iconColor;
  final double blur;
  final double tintOpacity;

  /// When true, renders a solid (non-glass) filled circle instead — used
  /// for the selected bottom-nav destination, which the reference design
  /// keeps as an opaque black "puck" rather than glass.
  final bool filled;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Material(
        color: fillColor ?? Colors.black,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
      );
    }

    return LiquidGlass(
      borderRadius: size / 2,
      blur: blur,
      tintOpacity: tintOpacity,
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }
}

/// A small frosted-glass pill used for text badges floating over photos —
/// gallery counters, status badges, location/price/rating chips.
class LiquidGlassPill extends StatelessWidget {
  const LiquidGlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.borderRadius = 16,
    this.blur = 22,
    this.tintOpacity = 0.18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final double tintOpacity;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: borderRadius,
      blur: blur,
      tintOpacity: tintOpacity,
      padding: padding,
      shadow: false,
      child: child,
    );
  }
}

/// A full-width frosted-glass pill button — the "Get Started" / "Log In" /
/// "Create Account" primary action used on the splash and auth screens.
/// Real backdrop blur + a soft top-left-to-bottom-right white gradient give
/// it the same "liquid glass" material as the rest of the app, with a
/// gentle press-scale for tactile feedback.
///
/// [filled] toggles between the brighter primary treatment (e.g. "Log In")
/// and a dimmer, more translucent secondary treatment (e.g. "Create
/// Account") so two of these can sit next to each other with a clear
/// visual hierarchy without needing a completely different widget.
class LiquidGlassButton extends StatefulWidget {
  const LiquidGlassButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.filled = true,
    this.height = 58,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final bool filled;
  final double height;

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onTap == null || widget.loading;

    return Opacity(
      opacity: widget.onTap == null && !widget.loading ? 0.55 : 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.97 : 1,
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
          onTapCancel: disabled ? null : () => setState(() => _pressed = false),
          onTapUp: disabled
              ? null
              : (_) {
                  setState(() => _pressed = false);
                  widget.onTap?.call();
                },
          child: GlassContainer.clearGlass(
            width: double.infinity,
            height: widget.height,
            borderRadius: BorderRadius.circular(widget.height / 2),
            blur: 25,
            elevation: widget.filled ? 10 : 0,
            color: Colors.white.withValues(alpha: widget.filled ? 0.08 : 0.04),
            borderColor: Colors.white.withValues(alpha: widget.filled ? 0.25 : 0.35),
            shadowColor: Colors.black.withValues(alpha: 0.25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.filled
                  ? <Color>[
                      Colors.white.withValues(alpha: .18),
                      Colors.white.withValues(alpha: .08),
                      Colors.white.withValues(alpha: .03),
                    ]
                  : <Color>[
                      Colors.white.withValues(alpha: .07),
                      Colors.white.withValues(alpha: .02),
                    ],
            ),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (widget.icon != null) ...<Widget>[
                          Icon(widget.icon, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
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
