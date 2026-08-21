import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import 'di_providers.dart';

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
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue<UserModel?>.data(null);
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    state = const AsyncValue<UserModel?>.loading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).updateProfile(fields));
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
/// separate from [AuthController] because a successful registration does
/// NOT log the user in (the API returns no tokens from `/register/`); the
/// register screen just needs its own idle -> loading -> data/error cycle,
/// mirroring `EnquiryController`.
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
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            username: username,
            password: password,
            email: email,
            phone: phone,
            fullName: fullName,
          ),
    );
  }

  void reset() => state = const AsyncValue<UserModel?>.data(null);
}

final AsyncNotifierProvider<RegisterController, UserModel?> registerControllerProvider =
    AsyncNotifierProvider<RegisterController, UserModel?>(RegisterController.new);
