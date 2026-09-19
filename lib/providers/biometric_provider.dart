import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_service.dart';
import 'di_providers.dart';

final Provider<BiometricService> biometricServiceProvider =
    Provider<BiometricService>((Ref ref) => BiometricService());

/// Whether this device even has usable biometrics — the Face ID/Touch ID
/// toggle in Profile is hidden entirely when this is `false`.
final FutureProvider<bool> biometricAvailableProvider = FutureProvider<bool>((Ref ref) {
  return ref.watch(biometricServiceProvider).isAvailable();
});

/// The user's saved preference for whether app relaunch should be gated
/// behind Face ID/Touch ID (see `SplashView`'s unlock screen). Turning it
/// on requires a successful biometric check first, so the setting can never
/// be silently enabled without proving the device owner can actually pass it.
class BiometricSettingsController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(tokenStorageProvider).isBiometricEnabled();

  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      final bool confirmed = await ref
          .read(biometricServiceProvider)
          .authenticate('Confirm it\'s you to enable Face ID sign-in');
      if (!confirmed) return false;
    }
    await ref.read(tokenStorageProvider).setBiometricEnabled(enabled);
    state = AsyncValue<bool>.data(enabled);
    return true;
  }
}

final AsyncNotifierProvider<BiometricSettingsController, bool> biometricSettingsProvider =
    AsyncNotifierProvider<BiometricSettingsController, bool>(BiometricSettingsController.new);
