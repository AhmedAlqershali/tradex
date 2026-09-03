import 'package:firebase_auth/firebase_auth.dart';

class FirebaseEmailVerificationService {
  FirebaseEmailVerificationService._();
  static final instance = FirebaseEmailVerificationService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<bool> registerAndSend({
    required String email,
    required String password,
  }) async {
    late final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (_) {
      rethrow;
    }
    await credential.user!.sendEmailVerification();
    return true;
  }

  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
    await _auth.signOut();
  }

  Future<void> resend() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No Firebase verification user.');
    await user.sendEmailVerification();
  }

  Future<String?> refreshAndGetIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null || !refreshedUser.emailVerified) return null;
    return refreshedUser.getIdToken(true);
  }

  Future<void> signOut() => _auth.signOut();
}