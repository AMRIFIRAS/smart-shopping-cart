import 'dart:async';

import 'package:smart_shopping_cart/models/account.dart';
import 'package:smart_shopping_cart/services/auth_service.dart';

/// Test double only. Production always uses FirebaseAuthService or guest mode.
class FakeAuth implements AuthService {
  final events = StreamController<Account?>.broadcast(sync: true);
  Account? account;
  String? failureCode;
  String? resetEmail;
  @override
  bool get isConfigured => true;
  @override
  Account? get currentAccount => account;
  @override
  Stream<Account?> get accountChanges => events.stream;
  void emit(Account? value) {
    account = value;
    events.add(value);
  }

  void checkFailure() {
    if (failureCode != null) throw AuthFailure(failureCode!);
  }

  @override
  Future<void> createAccount(
    String email,
    String password,
    String displayName,
  ) async {
    checkFailure();
    emit(
      Account(
        uid: email.trim(),
        email: email.trim(),
        displayName: displayName.trim(),
      ),
    );
  }

  @override
  Future<void> signIn(String email, String password) =>
      createAccount(email, password, '');
  @override
  Future<void> signOut() async => emit(null);
  @override
  Future<void> resetPassword(String email) async {
    checkFailure();
    resetEmail = email.trim();
  }

  @override
  Future<void> updateDisplayName(String name) async {
    checkFailure();
    emit(
      Account(
        uid: account!.uid,
        email: account!.email,
        displayName: name.trim(),
      ),
    );
  }

  @override
  void dispose() => events.close();
}
