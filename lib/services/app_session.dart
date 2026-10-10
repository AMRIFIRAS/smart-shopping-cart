import 'dart:async';

import 'package:flutter/material.dart';

import '../models/account.dart';
import '../models/order.dart';
import 'auth_service.dart';
import 'document_locale.dart';
import 'local_store.dart';
import 'order_repository.dart';

class AppSession extends ChangeNotifier {
  AppSession({
    required this.store,
    required this.auth,
    OrderRepository? orderRepository,
  }) : ordersRepository = orderRepository ?? LocalOrderRepository(store) {
    locale = Locale(store.read('smartcart.language') == 'ar' ? 'ar' : 'en');
    updateDocumentLocale(locale.languageCode);
    _setAccount(auth.currentAccount, notify: false);
    _subscription = auth.accountChanges.listen(
      _setAccount,
      onError: (Object error) {
        authError = 'Account connection unavailable. Please try again.';
        notifyListeners();
      },
    );
  }
  final LocalStore store;
  final AuthService auth;
  final OrderRepository ordersRepository;
  late final StreamSubscription<Account?> _subscription;
  late Locale locale;
  Account? account;
  List<Order> orders = [];
  String? authError;
  bool get isGuest => account == null;
  Future<void> _pendingWrite = Future.value();
  bool _disposed = false;
  Future<void> get saved => _pendingWrite;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void _setAccount(Account? value, {bool notify = true}) {
    final changedUser = account?.uid != value?.uid;
    account = value;
    if (changedUser) {
      orders = value == null ? [] : ordersRepository.read(value.uid);
    }
    authError = null;
    if (notify) notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    locale = Locale(code == 'ar' ? 'ar' : 'en');
    updateDocumentLocale(locale.languageCode);
    notifyListeners();
    try {
      await store.write('smartcart.language', locale.languageCode);
    } catch (_) {
      authError = 'Preferences could not be saved on this device.';
      notifyListeners();
    }
  }

  void rememberOrder(Order order) {
    final uid = account?.uid;
    if (uid == null) return;
    orders = [order, ...orders];
    final snapshot = List<Order>.of(orders);
    _pendingWrite = _pendingWrite
        .then((_) => ordersRepository.write(uid, snapshot))
        .catchError((Object error) {
          authError = 'Order history could not be saved on this device.';
          notifyListeners();
        });
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    auth.dispose();
    super.dispose();
  }
}

class SessionScope extends InheritedNotifier<AppSession> {
  const SessionScope({
    super.key,
    required AppSession session,
    required super.child,
  }) : super(notifier: session);
  static AppSession of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}
