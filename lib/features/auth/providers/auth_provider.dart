import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_diary/security/biometric_service.dart';

enum AuthState { locked, unlocked }

class AuthNotifier extends StateNotifier<AuthState> {
  final BiometricService _biometricService;

  AuthNotifier(this._biometricService) : super(AuthState.locked);

  void unlock() {
    state = AuthState.unlocked;
  }

  void lock() {
    state = AuthState.locked;
  }

  Future<bool> checkBiometric() async {
    final available = await _biometricService.isAvailable();
    if (!available) {
      unlock();
      return true;
    }

    final success = await _biometricService.authenticate();
    if (success) {
      unlock();
    }
    return success;
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final biometricService = ref.watch(biometricServiceProvider);
  return AuthNotifier(biometricService);
});
