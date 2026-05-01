import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexchat_real_time_messaging_app/core/models/user_model.dart';
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
    required String username,   // ← already added
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
        username: username.trim().toLowerCase(),  // ← already added
        photoUrl: '',
        isOnline: true,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(newUser.toMap());

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
      final UserCredential credential = await _auth
          .signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = credential.user;
      if (user == null) return null;

      await _updateOnlineStatus(user.uid, true);
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
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─── SMS OTP — Send Code ─────────────────────────────────────────────────
  //
  // FIX: The old implementation used a Completer that resolved on the FIRST
  // callback fired. On Android, `verificationCompleted` can fire before
  // `codeSent`, causing the Completer to complete before we have a
  // verificationId — so the OTP screen receives null/stale verificationId
  // and every code entry fails.
  //
  // NEW behaviour:
  //  • verificationCompleted  → auto-link silently, call onAutoVerified so
  //                             the caller can skip the OTP screen entirely.
  //  • codeSent               → store verificationId, call onCodeSent.
  //  • verificationFailed     → surface the error via onError.
  //  • codeAutoRetrievalTimeout → ignored (do NOT overwrite verificationId).
  //
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function()? onAutoVerified, // called when Android auto-resolves
  }) async {


    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,

      verificationCompleted: (PhoneAuthCredential credential) async {

        try {
          await _linkPhoneToAccount(credential);
          onAutoVerified?.call();
        } catch (e) {
          // Don't surface this — the user can still enter manually
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        onError(_handleAuthException(e));
      },

      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },

      // FIX: Do NOT call onCodeSent here. The timeout just means SMS
      // auto-retrieval gave up — the verificationId from codeSent is
      // still valid for manual entry. Overwriting it caused wrong-OTP errors.
      codeAutoRetrievalTimeout: (String verificationId) {

      },

      timeout: const Duration(seconds: 60),
    );
  }

  // ─── SMS OTP — Verify Code ───────────────────────────────────────────────
  Future<void> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      await _linkPhoneToAccount(credential);
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw _handleAuthException(e);
      }
      rethrow;
    }
  }

  // ─── Link Phone to Existing Account ─────────────────────────────────────
  Future<void> _linkPhoneToAccount(PhoneAuthCredential credential) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw 'No authenticated user found. Please sign in again.';
    }

    try {
      await user.linkWithCredential(credential);
      await _createOrUpdateUserDoc(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        await _createOrUpdateUserDoc(user);
        return;
      }
      throw _handleAuthException(e);
    }
  }

  Future<void> _createOrUpdateUserDoc(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'phoneNumber': user.phoneNumber ?? '',
        'displayName': 'User ${user.uid.substring(0, 5)}',
        'photoURL': '',
        'bio': '',
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  // ─── Get User from Firestore ─────────────────────────────────────────────
  Future<UserModel?> getUser(String uid) async {
    try {
      final DocumentSnapshot doc =
      await _firestore.collection('users').doc(uid).get();
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
      case 'session-expired':
        return 'OTP session expired. Please request a new code.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}