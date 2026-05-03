import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexchat_real_time_messaging_app/core/models/user_model.dart';
import 'package:nexchat_real_time_messaging_app/core/services/notification_service.dart';
import 'dart:async';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Auth State Stream ───────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ─── Sign Up ─────────────────────────────────────────────────────────────
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = credential.user;
      if (user == null) return null;

      await user.updateDisplayName(displayName.trim());

      final UserModel newUser = UserModel(
        uid: user.uid,
        email: email.trim(),
        phoneNumber: '',
        displayName: displayName.trim(),
        username: username.trim().toLowerCase(),
        photoUrl: '',
        isOnline: true,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      // ── Save FCM token for newly registered user ────────────────────────
      await NotificationService.instance.saveTokenToFirestore();

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = credential.user;
      if (user == null) return null;

      await _updateOnlineStatus(user.uid, true);

      // ── Save FCM token on every login ──────────────────────────────────
      await NotificationService.instance.saveTokenToFirestore();

      return await getUser(user.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      final String? uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _updateOnlineStatus(uid, false);

        // ── Remove FCM token so this device stops receiving notifications ─
        await NotificationService.instance.deleteTokenFromFirestore();
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─── SMS OTP — Send Code ─────────────────────────────────────────────────
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function()? onAutoVerified,
  }) async {
    try {
      final existing = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber.trim())
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final existingUid = existing.docs.first.id;
        final currentUid = _auth.currentUser?.uid;
        if (existingUid != currentUid) {
          onError('This phone number is already connected to an account.');
          return;
        }
      }
    } catch (_) {}

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final User? user = _auth.currentUser;
          if (user != null) {
            await user.linkWithCredential(credential);
            await _firestore.collection('users').doc(user.uid).update({
              'phoneVerified': true,
              'lastSeen': FieldValue.serverTimestamp(),
            });
          }
          onAutoVerified?.call();
        } catch (e) {
          onError(e.toString());
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(_handleAuthException(e));
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  // ─── SMS OTP — Verify Code ───────────────────────────────────────────────
  Future<void> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpCode,
    );

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No signed-in user found. Please sign in again.');
      }

      await currentUser.linkWithCredential(credential);
      await currentUser.reload();
      final User? refreshed = _auth.currentUser;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'phoneVerified': true,
        'phoneNumber': refreshed?.phoneNumber ?? '',
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        final User? user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'phoneVerified': true,
            'lastSeen': FieldValue.serverTimestamp(),
          });
        }
        return;
      }
      if (e.code == 'credential-already-in-use' ||
          e.code == 'account-exists-with-different-credential') {
        throw 'This phone number is already connected to an account.';
      }
      throw _handleAuthException(e);
    }
  }

  // ─── Get User from Firestore ─────────────────────────────────────────────
  Future<UserModel?> getUser(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // ─── Presence Tracking ───────────────────────────────────────────────────
  Future<void> _updateOnlineStatus(String uid, bool isOnline) async {
    await _firestore.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ─── Error Handler ───────────────────────────────────────────────────────
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-verification-code':
        return 'Incorrect OTP code. Please try again.';
      case 'invalid-phone-number':
        return 'Please enter a valid phone number with country code.';
      case 'provider-already-linked':
        return 'This phone number is already linked to your account.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      case 'session-expired':
        return 'OTP session expired. Please request a new code.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'billing-not-enabled':
        return 'Phone auth requires billing to be enabled.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      case 'missing-client-identifier':
        return 'App verification failed. Check SHA fingerprint config.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}