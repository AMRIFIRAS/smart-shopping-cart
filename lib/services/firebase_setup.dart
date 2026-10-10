import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'auth_service.dart';

/// Supply the Firebase web configuration through --dart-define-from-file.
/// Public web config is not an Admin SDK credential. Never bundle private keys.
Future<AuthService> initializeAuthentication() async {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  if (apiKey.isEmpty || appId.isEmpty || projectId.isEmpty) {
    return GuestAuthService();
  }
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        projectId: projectId,
        messagingSenderId: String.fromEnvironment(
          'FIREBASE_MESSAGING_SENDER_ID',
        ),
        authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      ),
    );
    return FirebaseAuthService(FirebaseAuth.instance);
  } catch (_) {
    return GuestAuthService();
  }
}
