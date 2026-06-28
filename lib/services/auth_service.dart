import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleSignInInitialization;

  Stream<User?> get user => _auth.authStateChanges();

  Future<void> _initializeGoogleSignIn() {
    return _googleSignInInitialization ??= _googleSignIn.initialize();
  }

  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> register(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> signInWithGoogle() async {
    await _initializeGoogleSignIn();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);

    return result.user;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = _auth.currentUser;
    final email = currentUser?.email;

    if (currentUser == null || email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user is available.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await currentUser.reauthenticateWithCredential(credential);
    await currentUser.updatePassword(newPassword);
  }

  Future<void> updateProfile({
    required String displayName,
    required String photoUrl,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user is available.',
      );
    }

    await currentUser.updateDisplayName(displayName);
    await currentUser.updatePhotoURL(photoUrl.isEmpty ? null : photoUrl);
    await currentUser.reload();
  }

  Future<void> signOut() async {
    try {
      await _initializeGoogleSignIn();
      await _googleSignIn.signOut();
    } catch (_) {
      // Firebase is the source of truth for app auth state; still sign out there.
    }

    await _auth.signOut();
  }
}
