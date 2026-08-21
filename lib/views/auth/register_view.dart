import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/route_names.dart';
import '../../core/utils/validators.dart';
import '../../models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_exception.dart';
import '../../widgets/glass/liquid_glass.dart';
import 'widgets/auth_glass_widgets.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _fullName = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String _dialCode = '+971';

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _email.dispose();
    _phone.dispose();
    _fullName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    await ref.read(registerControllerProvider.notifier).submit(
          username: _username.text.trim(),
          password: _password.text,
          email: _email.text.trim(),
          phone: '$_dialCode${_phone.text.trim()}',
          fullName: _fullName.text.trim(),
        );
  }

  void _goToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserModel?>>(
      registerControllerProvider,
      (AsyncValue<UserModel?>? prev, AsyncValue<UserModel?> next) {
        next.whenOrNull(
          data: (UserModel? user) {
            if (user == null) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created! Log in to continue.'),
              ),
            );

            ref.read(registerControllerProvider.notifier).reset();

            context.pushReplacement(
              RouteNames.login,
              extra: _username.text.trim(),
            );
          },
          error: (Object e, StackTrace st) {
            final String message = e is AuthException
                ? e.message
                : 'Something went wrong. Please try again.';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
        );
      },
    );

    final bool isLoading = ref.watch(registerControllerProvider).isLoading;

    return GlassAuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 12),
            const Text(
              'Join ${AppConstants.appName}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create an account to save favorites and manage your enquiries.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            GlassAuthPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Username
                  GlassTextField(
                    controller: _username,
                    label: 'Username',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: Validators.username,
                    autofillHints: const [
                      AutofillHints.newUsername,
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Password
                  GlassTextField(
                    controller: _password,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      color: Colors.white70,
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    textInputAction: TextInputAction.next,
                    validator: Validators.password,
                    autofillHints: const [
                      AutofillHints.newPassword,
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Confirm Password
                  GlassTextField(
                    controller: _confirmPassword,
                    label: 'Confirm Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      color: Colors.white70,
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                    ),
                    textInputAction: TextInputAction.next,
                    validator: Validators.confirmPassword(_password),
                  ),

                  const SizedBox(height: 14),

                  // Full Name
                  GlassTextField(
                    controller: _fullName,
                    label: 'Full Name',
                    icon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // Email
                  GlassTextField(
                    controller: _email,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),

                  const SizedBox(height: 14),

                  // Phone (country code + number)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: CountryCodePicker(
                          onChanged: (CountryCode code) {
                            setState(() {
                              _dialCode = code.dialCode ?? '+971';
                            });
                          },
                          initialSelection: 'AE',
                          favorite: const ['+971', 'AE'],
                          showCountryOnly: false,
                          showOnlyCountryWhenClosed: false,
                          alignLeft: false,
                          textStyle: const TextStyle(color: Colors.white),
                          dialogTextStyle: const TextStyle(color: Colors.black),
                          searchStyle: const TextStyle(color: Colors.black),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassTextField(
                          controller: _phone,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          validator: Validators.phone,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  LiquidGlassButton(
                    label: 'Create Account',
                    icon: Icons.person_add_alt_1_rounded,
                    loading: isLoading,
                    onTap: isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: _goToLogin,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Already have an account? Log in',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
