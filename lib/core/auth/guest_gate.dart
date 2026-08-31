import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_prompt_sheet.dart';
import '../routes/route_names.dart';

/// Gate for every "account-dependent" feature (favoriting, contacting an
/// agent, sending an enquiry, personalized notifications, ...): guests get
/// invited to sign in rather than blocked outright.
///
/// Already logged in → resolves immediately, no interruption. Guest → shows
/// [showAuthPromptSheet]; if they pick Login/Create Account and actually
/// complete it, the original action's call site (which awaits this) just
/// proceeds — that's the "guest favorites a property → logs in → property
/// is automatically saved" flow, with no separate replay/queue mechanism
/// needed. "Continue Browsing" (or dismissing the sheet) resolves `false`
/// and the caller does nothing further.
///
/// Usage:
/// ```dart
/// onFavoriteTap: () async {
///   if (await requireAuth(context, ref)) {
///     ref.read(favoritesProvider.notifier).toggle(project.id);
///   }
/// }
/// ```
Future<bool> requireAuth(
  BuildContext context,
  WidgetRef ref, {
  String? title,
  String? description,
}) async {
  if (ref.read(isLoggedInProvider)) return true;

  final AuthPromptChoice? choice = await showAuthPromptSheet(
    context,
    title: title ?? 'Create your property journey',
    description: description ??
        'Sign in to save properties, contact agents, schedule visits, '
            'and receive personalized updates.',
  );
  if (choice == null || !context.mounted) return false;

  final String route = choice == AuthPromptChoice.login
      ? RouteNames.login
      : RouteNames.register;
  await context.push(route);
  if (!context.mounted) return false;
  return ref.read(isLoggedInProvider);
}
