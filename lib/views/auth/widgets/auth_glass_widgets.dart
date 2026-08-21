import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/glass/liquid_glass.dart';

/// Shared full-bleed "glass over a photo" chrome for the Login and
/// Register screens — the same hero image + dark scrim treatment as the
/// splash screen, a floating glass back button, and a scrollable body so
/// the (long) Register form doesn't overflow on small devices.
class GlassAuthScaffold extends StatelessWidget {
  const GlassAuthScaffold({super.key, required this.child, this.onBack});

  final Widget child;

  /// Overrides the default back behavior (pop if possible, otherwise
  /// return to the splash/welcome screen).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AssetPaths.loginBg, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0x99000000),
                  Color(0xB3000000),
                  Color(0xF0000000),
                ],
                stops: <double>[0.0, 0.4, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      LiquidGlassCircle(
                        icon: Icons.arrow_back_ios_new_rounded,
                        iconSize: 18,
                        onTap: onBack ??
                            () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(RouteNames.splash);
                              }
                            },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          16,
                          20,
                          24 + MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Center(child: child),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The frosted panel that holds the actual form — sits on top of
/// [GlassAuthScaffold]'s photo background.
class GlassAuthPanel extends StatelessWidget {
  const GlassAuthPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: 28,
      blur: 30,
      tintOpacity: 0.10,
      borderOpacity: 0.22,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: child,
    );
  }
}

/// A [TextFormField] styled to sit legibly on the glass panel: translucent
/// white fill, white text/icons, and a brighter border on focus — the
/// same visual language as the rest of the glass UI rather than the
/// app's normal light Material text field.
class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
    );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      cursorColor: Colors.white,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
        floatingLabelStyle: const TextStyle(color: Colors.white),
        prefixIcon:
            icon != null ? Icon(icon, color: Colors.white70, size: 20) : null,
        suffixIcon: suffixIcon,
        suffixIconColor: Colors.white70,
        filled: true,
        fillColor: Colors.white.withValues(alpha: enabled ? 0.09 : 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: baseBorder,
        enabledBorder: baseBorder,
        disabledBorder: baseBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: AppColors.error.withValues(alpha: 0.85)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFFB4B4)),
      ),
    );
  }
}
