import 'package:firebase_auth/firebase_auth.dart';

class AuthHelper {
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> createUser(String email, String password) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return {'state': true, 'id': credential.user?.uid};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return {'state': false, 'error': 'The password provided is too weak.'};
      } else if (e.code == 'email-already-in-use') {
        return {
          'state': false,
          'error': 'The account already exists for that email.'
        };
      }
      return {'state': false, 'error': e.toString()};
    } catch (e) {
      return {'state': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      String? uuid = credential.user?.uid;
      return {'userId': uuid};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
      return {'error': e.toString()};
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  Stream<User?> get authStateChanges => auth.authStateChanges();
  Future<User?> get currentUser async {
    return auth.currentUser;
  }
}

final AuthHelper authHelper = AuthHelper();
