import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/app_session.dart';
import 'services/firebase_setup.dart';
import 'services/local_store.dart';
import 'services/web_routing.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureWebRouting();
  LocalStore store;
  try {
    store = PreferencesStore(await SharedPreferences.getInstance());
  } catch (_) {
    store = MemoryStore();
  }
  final session = AppSession(
    store: store,
    auth: await initializeAuthentication(),
  );
  runApp(SmartShoppingApp(session: session));
}
