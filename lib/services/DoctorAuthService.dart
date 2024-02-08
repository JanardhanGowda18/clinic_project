// doctor_auth_service.dart


import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_care/services/auth_provider.dart' as LocalAuthProvider;

class DoctorAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthProvider.AuthProvider _authProvider;

  DoctorAuthService(LocalAuthProvider.AuthProvider authProvider) : _authProvider = authProvider;
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential authResult = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _authProvider?.setLoggedIn(true);

      return authResult.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  void signOut() {
    _authProvider?.setLoggedIn(false);
    _auth.signOut();
  }
}
