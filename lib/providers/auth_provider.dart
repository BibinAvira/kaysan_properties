import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import 'di_providers.dart';
import 'guest_session_provider.dart';

/// Tracks the logged-in user for the whole app: `null` while logged out,
/// a [UserModel] once logged in. On first read it checks secure storage
/// for a stored access token and, if found, fetches the live profile
/// (which also proves the token — or its refresh — still works).
class AuthController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final bool hasSession = await ref.read(authRepositoryProvider).hasStoredSession();
    if (!hasSession) return null;
    try {
      return await ref.read(authRepositoryProvider).fetchProfile();
    } catch (_) {
      // Both access and refresh tokens are dead — treat as logged out.
      await ref.read(authRepositoryProvider).logout();
      return null;
    }
  }

  Future<void> login({required String username, required String password}) async {
    state = const AsyncValue<UserModel?>.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(username: username, password: password),
    );
    // Guest → registered transition: retire the guest identifier (see
    // guest_session_provider.dart's doc comment on why there's nothing
    // else to "merge" — the guest's local activity data is already this
    // device's data, not namespaced by session ID).
    if (state.valueOrNull != null) {
      await ref.read(guestSessionProvider.notifier).clearSessionId();
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue<UserModel?>.data(null);
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    state = const AsyncValue<UserModel?>.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).updateProfile(fields));
  }

  /// Permanently deletes the account (App Store 5.1.1(v)). Throws on
  /// failure — the caller's confirmation dialog is responsible for showing
  /// that to the user — and leaves [state] untouched so a failed attempt
  /// doesn't log the person out. On success, state becomes logged-out.
  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
    state = const AsyncValue<UserModel?>.data(null);
  }
}

final AsyncNotifierProvider<AuthController, UserModel?> authControllerProvider =
    AsyncNotifierProvider<AuthController, UserModel?>(AuthController.new);

/// Convenience read-only view for widgets that only care whether someone
/// is currently logged in (e.g. the More tab's Account section).
final Provider<bool> isLoggedInProvider = Provider<bool>((Ref ref) {
  return ref.watch(authControllerProvider).value != null;
});

/// Tracks the async lifecycle of the Register form specifically — kept
/// separate from [AuthController] because the API returns no tokens from
/// `/register/`, so a successful registration alone doesn't establish a
/// session. To avoid handing the user a blank Login screen right after
/// they've just typed a password (the exact defect Apple's reviewer hit —
/// see App Store rejection for build 1.0.0(7), Guideline 2.1(a)), [submit]
/// immediately logs in with the same credentials via [AuthController] once
/// registration succeeds. This controller's own state just reflects whether
/// the register call itself succeeded, mirroring `EnquiryController`.
class RegisterController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async => null;

  Future<void> submit({
    required String username,
    required String password,
    String? email,
    String? phone,
    String? fullName,
  }) async {
    state = const AsyncValue<UserModel?>.loading();
    final AsyncValue<UserModel?> result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            username: username,
            password: password,
            email: email,
            phone: phone,
            fullName: fullName,
          ),
    );

    if (result.hasValue && result.value != null) {
      // Registration succeeded on the backend; auto-login with the same
      // credentials so the user lands in the app instead of being bounced
      // to a Login form they'd have to fill in again. `login()` guards its
      // own errors, so a hiccup here just leaves AuthController logged out
      // — the view falls back to the manual Login screen in that case.
      await ref.read(authControllerProvider.notifier).login(
            username: username,
            password: password,
          );
    }

    state = result;
  }

  void reset() => state = const AsyncValue<UserModel?>.data(null);
}

final AsyncNotifierProvider<RegisterController, UserModel?> registerControllerProvider =
    AsyncNotifierProvider<RegisterController, UserModel?>(RegisterController.new);
