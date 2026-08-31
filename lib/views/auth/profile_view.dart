import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_exception.dart';
import '../../widgets/glass/glass_dialog.dart';
import '../../widgets/glass/liquid_glass.dart';
import 'widgets/auth_glass_widgets.dart';

/// Profile screen — rebuilt on the same [GlassAuthScaffold] chrome as
/// Login/Register/Splash (hero photo + dark scrim + frosted glass panel)
/// so it reads as a native part of the app's Liquid Glass language rather
/// than a plain light Material form, for both the guest and logged-in
/// states.
class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

/// Unfocuses whatever field currently has focus, then pops on the *next*
/// frame rather than in the same call.
///
/// Reproduced on-device, with a full stack trace, that popping a route
/// while a `TextField` still holds focus can crash with a framework
/// assertion (`_dependents.isEmpty`): the trace showed the crash inside
/// the TextField's own internal text-selection `RawGestureDetector`,
/// rebuilding as a side effect of unfocus, colliding with this dialog's
/// per-frame animated exit transition rebuilding the same subtree in the
/// same frame. Calling `unfocus()` immediately followed by `pop()` in one
/// synchronous call — tried first — does not fix it: unfocus's own
/// teardown hasn't finished by the time pop starts its transition.
/// Deferring the pop to `addPostFrameCallback` gives unfocus's rebuild a
/// complete frame of its own before the route's exit transition begins.
void _unfocusThenPop(BuildContext context, bool result) {
  FocusManager.instance.primaryFocus?.unfocus();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) Navigator.of(context).pop(result);
  });
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  bool _editing = false;
  bool _initialized = false;
  bool _deleting = false;

  void _seedControllers(UserModel user) {
    if (_initialized) return;
    _fullName.text = user.fullName ?? '';
    _email.text = user.email ?? '';
    _phone.text = user.phone ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .updateProfile(<String, dynamic>{
      'full_name': _fullName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
    });
  }

  Future<void> _confirmLogout() async {
    final bool? confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (BuildContext context) => GlassAlertDialog(
        icon: Icons.logout_rounded,
        title: 'Log Out',
        content: const Text('Are you sure you want to log out?'),
        actions: <Widget>[
          LiquidGlassButton(
            label: 'Log Out',
            icon: Icons.logout_rounded,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.white60),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) context.go(RouteNames.login);
    }
  }

  /// Single dialog — the warning plus a "type DELETE to confirm" field,
  /// with the destructive action disabled until it matches — before
  /// calling the backend to permanently remove the account. App Store
  /// guideline 5.1.1(v) requires this be an in-app action a user can
  /// complete themselves, not a "contact support" dead end.
  Future<void> _confirmDeleteAccount() async {
    final TextEditingController confirmField = TextEditingController();
    final bool? confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final bool canDelete = confirmField.text.trim() == 'DELETE';
          return GlassAlertDialog(
            icon: Icons.delete_forever_rounded,
            iconColor: AppColors.error,
            title: 'Delete Account',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'This permanently deletes your account and all associated '
                  'data — saved favorites tied to it, enquiries, and profile '
                  'details. This can\'t be undone.',
                ),
                const SizedBox(height: 16),
                const Text('Type DELETE below to confirm.'),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmField,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (String _) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.error, width: 1.4),
                    ),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              LiquidGlassButton(
                label: 'Delete',
                icon: Icons.delete_forever_rounded,
                accentColor: canDelete ? AppColors.error : null,
                onTap: canDelete
                    ? () => _unfocusThenPop(context, true)
                    : null,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _unfocusThenPop(context, false),
                style: TextButton.styleFrom(foregroundColor: Colors.white60),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
    confirmField.dispose();
    if (confirmed != true || !mounted) return;

    // Let the dialog's exit transition fully finish before mutating state
    // — see glassDialogTransitionDuration's doc comment.
    await Future<void>.delayed(glassDialogTransitionDuration);
    if (!mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      if (mounted) context.go(RouteNames.login);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      final String message =
          e is AuthException ? e.message : 'Could not delete your account. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserModel?>>(authControllerProvider,
        (AsyncValue<UserModel?>? prev, AsyncValue<UserModel?> next) {
      next.whenOrNull(
        data: (UserModel? user) {
          if (user != null && _editing && prev?.isLoading == true) {
            setState(() => _editing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated.')),
            );
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

    final AsyncValue<UserModel?> authState = ref.watch(authControllerProvider);
    final bool loggedIn = authState.valueOrNull != null;

    return GlassAuthScaffold(
      actions: <Widget>[
        if (loggedIn)
          LiquidGlassCircle(
            icon: Icons.logout_rounded,
            iconSize: 18,
            onTap: _confirmLogout,
          ),
      ],
      child: authState.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (Object e, StackTrace st) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            e is AuthException ? e.message : 'Could not load your profile.',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        data: (UserModel? user) {
          if (user == null) return const _GuestProfilePanel();

          _seedControllers(user);
          final bool isSaving = authState.isLoading;
          return _AccountProfilePanel(
            user: user,
            editing: _editing,
            isSaving: isSaving,
            deleting: _deleting,
            formKey: _formKey,
            fullNameController: _fullName,
            emailController: _email,
            phoneController: _phone,
            onToggleEdit: () => setState(() => _editing = !_editing),
            onSave: _save,
            onDeleteAccount: _confirmDeleteAccount,
          );
        },
      ),
    );
  }
}

/// Guest state — no account-specific info shown, just an invitation to
/// sign in, matching the guest-access spec exactly, styled with the same
/// glass panel/button language as Login/Register.
class _GuestProfilePanel extends StatelessWidget {
  const _GuestProfilePanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Center(
          child: GlassIconBadge(icon: Icons.person_outline, glow: true),
        ),
        const SizedBox(height: 18),
        const Text(
          'Guest User',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to unlock personalized features',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 28),
        GlassAuthPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LiquidGlassButton(
                label: 'Login',
                icon: Icons.login_rounded,
                onTap: () => context.push(RouteNames.login),
              ),
              const SizedBox(height: 12),
              LiquidGlassButton(
                label: 'Create Account',
                icon: Icons.person_add_alt_1_rounded,
                filled: false,
                onTap: () => context.push(RouteNames.register),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Logged-in state — avatar + username + editable details, all restyled
/// onto the glass panel/[GlassTextField] language already used for
/// Login/Register instead of plain light Material form fields.
class _AccountProfilePanel extends StatelessWidget {
  const _AccountProfilePanel({
    required this.user,
    required this.editing,
    required this.isSaving,
    required this.deleting,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.onToggleEdit,
    required this.onSave,
    required this.onDeleteAccount,
  });

  final UserModel user;
  final bool editing;
  final bool isSaving;
  final bool deleting;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final VoidCallback onToggleEdit;
  final VoidCallback onSave;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _GlassAvatar(letter: user.username.isNotEmpty ? user.username[0].toUpperCase() : '?'),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(user.username,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                    if (user.createdAt != null)
                      Text(
                        'Member since ${user.createdAt!.year}-${user.createdAt!.month.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                      ),
                  ],
                ),
              ),
              LiquidGlassCircle(
                icon: editing ? Icons.close_rounded : Icons.edit_outlined,
                iconSize: 18,
                size: 38,
                onTap: onToggleEdit,
              ),
            ],
          ),
          const SizedBox(height: 24),
          GlassAuthPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GlassTextField(
                  controller: fullNameController,
                  label: 'Full Name',
                  icon: Icons.badge_outlined,
                  enabled: editing,
                ),
                const SizedBox(height: 14),
                GlassTextField(
                  controller: emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  enabled: editing,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.optionalEmail,
                ),
                const SizedBox(height: 14),
                GlassTextField(
                  controller: phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  enabled: editing,
                  keyboardType: TextInputType.phone,
                  validator: Validators.optionalPhone,
                ),
                if (editing) ...<Widget>[
                  const SizedBox(height: 20),
                  LiquidGlassButton(
                    label: 'Save Changes',
                    icon: Icons.check_rounded,
                    loading: isSaving,
                    onTap: isSaving ? null : onSave,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          Divider(color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          LiquidGlassButton(
            label: 'Delete Account',
            icon: Icons.delete_forever_outlined,
            filled: false,
            accentColor: AppColors.error,
            loading: deleting,
            onTap: deleting ? null : onDeleteAccount,
          ),
        ],
      ),
    );
  }
}

/// Frosted glass avatar circle — the account-panel equivalent of
/// [GlassIconBadge], sized and styled to sit inline in the profile header
/// row instead of standing alone as a centered hero badge.
class _GlassAvatar extends StatelessWidget {
  const _GlassAvatar({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: 28,
      blur: 24,
      tintOpacity: 0.16,
      width: 56,
      height: 56,
      shadow: false,
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
