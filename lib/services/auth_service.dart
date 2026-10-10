import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/account.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.code);
  final String code;
}

abstract class AuthService {
  bool get isConfigured;
  Account? get currentAccount;
  Stream<Account?> get accountChanges;
  Future<void> createAccount(String email, String password, String displayName);
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> updateDisplayName(String name);
  void dispose();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this.auth);
  final FirebaseAuth auth;
  Account? _account(User? user) => user == null
      ? null
      : Account(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
        );
  @override
  bool get isConfigured => true;
  @override
  Account? get currentAccount => _account(auth.currentUser);
  @override
  Stream<Account?> get accountChanges => auth.userChanges().map(_account);
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(error.code);
    }
  }

  @override
  Future<void> createAccount(
    String email,
    String password,
    String displayName,
  ) => _run(() async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName.trim().isNotEmpty) {
      await credential.user!.updateDisplayName(displayName.trim());
    }
  });
  @override
  Future<void> signIn(String email, String password) => _run(() async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  });
  @override
  Future<void> signOut() => _run(auth.signOut);
  @override
  Future<void> resetPassword(String email) =>
      _run(() => auth.sendPasswordResetEmail(email: email.trim()));
  @override
  Future<void> updateDisplayName(String name) => _run(() async {
    await auth.currentUser?.updateDisplayName(name.trim());
  });
  @override
  void dispose() {}
}

/// Honest guest mode until real Firebase configuration is supplied. No fake users.
class GuestAuthService implements AuthService {
  @override
  bool get isConfigured => false;
  @override
  Account? get currentAccount => null;
  @override
  Stream<Account?> get accountChanges => const Stream.empty();
  @override
  Future<void> createAccount(
    String email,
    String password,
    String displayName,
  ) async => throw const AuthFailure('not-configured');
  @override
  Future<void> signIn(String email, String password) async =>
      throw const AuthFailure('not-configured');
  @override
  Future<void> resetPassword(String email) async =>
      throw const AuthFailure('not-configured');
  @override
  Future<void> updateDisplayName(String name) async =>
      throw const AuthFailure('not-configured');
  @override
  Future<void> signOut() async {}
  @override
  void dispose() {}
}
