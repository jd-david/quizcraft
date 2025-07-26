import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception("An unexpected error occurred during sign in.");
    }
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password, String fullName) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(fullName);
        await user.reload();
        user = _firebaseAuth.currentUser;
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception("An unexpected error occurred during sign up.");
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
