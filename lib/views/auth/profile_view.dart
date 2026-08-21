import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/route_names.dart';
import '../../core/utils/validators.dart';
import '../../models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_exception.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  bool _editing = false;
  bool _initialized = false;

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
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: <Widget>[
          TextButton(
              onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => context.pop(true), child: const Text('Log Out')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) context.go(RouteNames.login);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e is AuthException ? e.message : 'Could not load your profile.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (UserModel? user) {
          if (user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text("You're not logged in."),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push(RouteNames.login),
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              ),
            );
          }

          _seedControllers(user);
          final bool isSaving = authState.isLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 28,
                          child: Text(
                            user.username.isNotEmpty
                                ? user.username[0].toUpperCase()
                                : '?',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(user.username,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              if (user.createdAt != null)
                                Text(
                                  'Member since ${user.createdAt!.year}-${user.createdAt!.month.toString().padLeft(2, '0')}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                              _editing ? Icons.close : Icons.edit_outlined),
                          onPressed: () => setState(() => _editing = !_editing),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _fullName,
                      enabled: _editing,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      enabled: _editing,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.optionalEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      enabled: _editing,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: Validators.optionalPhone,
                    ),
                    if (_editing) ...<Widget>[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _save,
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
