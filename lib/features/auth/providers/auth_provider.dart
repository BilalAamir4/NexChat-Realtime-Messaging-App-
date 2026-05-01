import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexchat_real_time_messaging_app/core/models/user_model.dart';
import 'package:nexchat_real_time_messaging_app/features/auth/data/auth_service.dart';

// ─── Auth Service Provider ────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ─── Auth State Provider ──────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ─── Current User Model Provider ─────────────────────────────────────────────
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return null;
      return ref.read(authServiceProvider).getUser(user.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ─── Auth Notifier ────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState.initial());

  // ─── Sign Up ────────────────────────────────────────────────────────────
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,   // ← already added
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        username: username,     // ← already added
      );
      if (user != null) {
        state = const AuthState.otpPending();
      } else {
        state = const AuthState.error('Sign up failed. Please try again.');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // ─── Sign In ────────────────────────────────────────────────────────────
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _authService.signIn(
        email: email,
        password: password,
      );
      if (user != null) {
        state = const AuthState.otpPending();
      } else {
        state = const AuthState.error('Sign in failed. Please try again.');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // ─── Send OTP ───────────────────────────────────────────────────────────
  // FIX: Added onAutoVerified callback. If Android auto-verifies the phone
  // (verificationCompleted fires), we jump straight to authenticated state
  // without waiting for the user to type a code — avoiding the race condition
  // where verificationCompleted consumes the credential before manual entry.
  Future<void> sendOtp({required String phoneNumber}) async {
    state = const AuthState.loading();
    await _authService.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        print('📱 [AuthNotifier] codeSent → verificationId=$verificationId');
        state = AuthState.codeSent(verificationId);
      },
      onError: (error) {
        print('❌ [AuthNotifier] sendOtp error → $error');
        state = AuthState.error(error);
      },
      // FIX: Android auto-verify path — go straight to authenticated
      onAutoVerified: () {
        print('✅ [AuthNotifier] onAutoVerified → setting authenticated');
        state = const AuthState.authenticated();
      },
    );
  }

  // ─── Verify OTP ─────────────────────────────────────────────────────────
  Future<void> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    state = const AuthState.loading();
    try {
      print('🔵 [AuthNotifier] verifyOtp called');
      await _authService.verifyOtp(
        verificationId: verificationId,
        otpCode: otpCode,
      );
      state = const AuthState.authenticated();
    } catch (e) {
      print('❌ [AuthNotifier] verifyOtp error → $e');
      state = AuthState.error(e.toString());
    }
  }

  // ─── Sign Out ───────────────────────────────────────────────────────────
  Future<void> signOut() async {
    state = const AuthState.loading();
    try {
      await _authService.signOut();
      state = const AuthState.initial();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // ─── Reset State ────────────────────────────────────────────────────────
  void reset() => state = const AuthState.initial();
}

// ─── Auth Notifier Provider ───────────────────────────────────────────────────
final authNotifierProvider =
StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

// ─── Auth State (sealed class) ────────────────────────────────────────────────
class AuthState {
  final AuthStatus status;
  final String? error;
  final String? verificationId;

  const AuthState._({
    required this.status,
    this.error,
    this.verificationId,
  });

  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.otpPending() = _OtpPending;
  const factory AuthState.codeSent(String verificationId) = _CodeSent;
  const factory AuthState.authenticated() = _Authenticated;
  const factory AuthState.error(String message) = _Error;

  bool get isLoading => status == AuthStatus.loading;
  bool get isError => status == AuthStatus.error;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isOtpPending => status == AuthStatus.otpPending;
  bool get isCodeSent => status == AuthStatus.codeSent;
}

enum AuthStatus {
  initial,
  loading,
  otpPending,
  codeSent,
  authenticated,
  error,
}

class _Initial extends AuthState {
  const _Initial() : super._(status: AuthStatus.initial);
}

class _Loading extends AuthState {
  const _Loading() : super._(status: AuthStatus.loading);
}

class _OtpPending extends AuthState {
  const _OtpPending() : super._(status: AuthStatus.otpPending);
}

class _CodeSent extends AuthState {
  const _CodeSent(String verificationId)
      : super._(status: AuthStatus.codeSent, verificationId: verificationId);
}

class _Authenticated extends AuthState {
  const _Authenticated() : super._(status: AuthStatus.authenticated);
}

class _Error extends AuthState {
  const _Error(String message)
      : super._(status: AuthStatus.error, error: message);
}