// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

/// Simple wrapper around Firebase Auth used by the UI.
/// Expand this for email verification, providers, error mapping, etc.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize (placeholder for future work)
  static Future<void> init() async {
    // nothing for now; keep for symmetry with other services
  }

  /// Current user ID or null
  static String? get currentUid => _auth.currentUser?.uid;

  /// Listen to auth state changes
  static void onAuthStateChanged(void Function(User? user) callback) {
    _auth.authStateChanges().listen(callback);
  }

  /// Sign up with email/password and set displayName
  static Future<User?> signUp(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user;
    if (user != null && displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
      await user.reload();
    }
    return _auth.currentUser;
  }

  /// Sign in
  static Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
