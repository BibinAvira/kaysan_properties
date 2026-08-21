import '../models/auth_models.dart';
import '../services/auth_service.dart';

/// Thin pass-through over [AuthService], kept as its own layer purely for
/// consistency with the rest of the app (`ProjectsRepository`,
/// `BlogsRepository`, ...) — controllers/providers depend on repositories,
/// never services, directly.
class AuthRepository {
  AuthRepository(this._service);
  final AuthService _service;

  Future<UserModel> register({
    required String username,
    required String password,
    String? email,
    String? phone,
    String? fullName,
  }) {
    return _service.register(
      username: username,
      password: password,
      email: email,
      phone: phone,
      fullName: fullName,
    );
  }

  Future<UserModel> login({required String username, required String password}) {
    return _service.login(username: username, password: password);
  }

  Future<UserModel> fetchProfile() => _service.fetchProfile();

  Future<UserModel> updateProfile(Map<String, dynamic> fields) => _service.updateProfile(fields);

  Future<void> logout() => _service.logout();

  Future<bool> hasStoredSession() => _service.hasStoredSession();
}
