import 'package:local_auth/local_auth.dart';

/// Wraps `local_auth` so views/providers never touch the platform channel
/// directly. Used to gate app relaunch behind Face ID/Touch ID (see
/// `SplashView`) and to confirm identity before turning the setting on
/// (see `ProfileView`).
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether this device has enrolled biometrics (or device credential)
  /// available at all, so the setting can stay hidden where it's useless.
  Future<bool> isAvailable() async {
    try {
      final bool supported = await _auth.isDeviceSupported();
      final bool canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Prompts Face ID/Touch ID (or the device's fallback PIN/pattern).
  /// Returns `false` on cancellation, failure, or any platform error rather
  /// than throwing — callers treat "not authenticated" uniformly either way.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
