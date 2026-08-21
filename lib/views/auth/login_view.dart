import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/route_names.dart';
import '../../core/utils/validators.dart';
import '../../models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_exception.dart';
import '../../widgets/glass/liquid_glass.dart';
import 'widgets/auth_glass_widgets.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key, this.prefillUsername});

  /// Username to prefill, e.g. when arriving here right after a successful
  /// registration so the person doesn't have to retype it.
  final String? prefillUsername;

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _username =
      TextEditingController(text: widget.prefillUsername ?? '');
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).login(
          username: _username.text.trim(),
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserModel?>>(authControllerProvider,
        (AsyncValue<UserModel?>? prev, AsyncValue<UserModel?> next) {
      next.whenOrNull(
        data: (UserModel? user) {
          if (user != null && context.canPop()) {
            context.pop();
          } else if (user != null) {
            context.go(RouteNames.home);
          }
        },
        error: (Object e, StackTrace st) {
          final String message = e is AuthException
              ? e.message
              : 'Something went wrong. Please try again.';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        },
      );
    });

    final bool isLoading = ref.watch(authControllerProvider).isLoading;

    return GlassAuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // const SizedBox(height: 12),
            Text(
              'Welcome back',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Log in to save favorites, track enquiries, and pick up where you left off.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                  height: 1.4),
            ),
            const SizedBox(height: 24),
            GlassAuthPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  GlassTextField(
                    controller: _username,
                    label: 'Username',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: Validators.username,
                    autofillHints: const <String>[AutofillHints.username],
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                    controller: _password,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      color: Colors.white70,
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    textInputAction: TextInputAction.done,
                    validator: Validators.password,
                    autofillHints: const <String>[AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 22),
                  LiquidGlassButton(
                    label: 'Log In',
                    icon: Icons.login_rounded,
                    loading: isLoading,
                    onTap: isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => context.push(RouteNames.register),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text("Don't have an account? Sign up"),
              ),
            ),
            const SizedBox(height: 52),
          ],
        ),
      ),
    );
  }
}
