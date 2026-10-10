import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'browser_session.dart';

/// Isolated live acceptance test. Deletes its temporary account in finally.
/// Password-reset codes stay in memory; no email is sent to another person.
Future<void> main() async {
  final config = jsonDecode(await File('firebase-config.json').readAsString());
  final origin = config['PUBLIC_SITE_URL'] as String;
  final key = config['FIREBASE_API_KEY'] as String;
  final project = config['FIREBASE_PROJECT_ID'] as String;
  final admin = Platform.environment['SMARTCART_TEST_ADMIN_TOKEN'];
  if (admin == null) {
    throw StateError('Supply the temporary admin token via environment.');
  }
  final random = Random.secure();
  final suffix = List.generate(
    12,
    (_) => random.nextInt(16).toRadixString(16),
  ).join();
  final email = 'smartcart-test-$suffix@example.com';
  var password = 'Sc!$suffix-A9';
  final http = HttpClient();
  final browser = await BrowserSession.connect();
  String? uid;
  Future<Map<String, dynamic>> api(
    String path,
    Map<String, dynamic> body, {
    bool privileged = false,
  }) async {
    final request = await http.postUrl(
      Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/$path${privileged ? '' : '?key=$key'}',
      ),
    );
    request.headers.contentType = ContentType.json;
    if (privileged) request.headers.set('Authorization', 'Bearer $admin');
    request.write(jsonEncode(body));
    final response = await request.close();
    final data = jsonDecode(
      await utf8.decoder.bind(response).join(),
    ) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw StateError('Auth API $path: ${data['error']?['message']}');
    }
    return data;
  }

  Future<void> signIn() async {
    await browser.button('Sign In');
    await browser.enter(email);
    await browser.enter(password, index: 1);
    await browser.button('Sign In');
    await browser.waitText('Profile');
  }

  try {
    await browser.clearStorage(origin);
    await browser.viewport(390, 844);
    await browser.load(origin);
    await browser.nav(3);
    await browser.button('Create Account');
    await browser.enter('SmartCart Test');
    await browser.enter(email, index: 1);
    await browser.enter(password, index: 2);
    await browser.button('Create Account');
    // Resolve the exact test UID for cleanup, including if UI navigation fails.
    await browser.settle(2500);
    final signed = await api('accounts:signInWithPassword', {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    });
    uid = signed['localId'] as String;
    await browser.waitText('Profile');
    await browser.expectText(email);
    await browser.enter('Updated Test Profile');
    await browser.button('Save profile');
    await browser.waitText('Profile updated.');
    await browser.button('Sign Out');
    await browser.waitText('Guest shopping');
    await signIn();
    await browser.load('$origin/product/P003');
    await browser.button('Add to cart');
    await browser.button('Cart');
    await browser.button('Continue to checkout');
    await browser.button('Complete demo checkout');
    await browser.button('Start New Shopping Trip');
    await browser.nav(3);
    await browser.expectText('Order history');
    await browser.expectText('No orders yet', present: false);
    await browser.expectText('SAR 1.00');
    await browser.load(origin);
    await browser.nav(3);
    await browser.expectText('No orders yet', present: false);
    await browser.button('Sign Out');
    await browser.waitText('Guest shopping');
    final reset = await api('projects/$project/accounts:sendOobCode', {
      'requestType': 'PASSWORD_RESET',
      'email': email,
      'returnOobLink': true,
    }, privileged: true);
    final code = Uri.parse(reset['oobLink'] as String)
        .queryParameters['oobCode'];
    password = '$password-reset';
    await api('accounts:resetPassword', {
      'oobCode': code,
      'newPassword': password,
    });
    await signIn();
    await browser.button('Sign Out');
    if (browser.errors.isNotEmpty) {
      throw StateError('Browser runtime errors: ${browser.errors.length}');
    }
    stdout.writeln(
      'PASS live account creation, profile, sign-out/in, persisted history and password reset; no email sent.',
    );
  } finally {
    try {
      if (uid == null) {
        final lookup = await api('projects/$project/accounts:lookup', {
          'email': [email],
        }, privileged: true);
        final users = lookup['users'] as List?;
        if (users != null && users.isNotEmpty) {
          uid = users.first['localId'] as String;
        }
      }
      if (uid != null) {
        await api('projects/$project/accounts:delete', {
          'localId': uid,
        }, privileged: true);
        stdout.writeln('Removed temporary Firebase acceptance-test account.');
      }
    } finally {
      await browser.clearStorage(origin);
      await browser.close();
      http.close();
    }
  }
  await File('build/verification/live-auth.json').writeAsString(
    jsonEncode({
      'passed': true,
      'origin': origin,
      'createSignInOutProfile': true,
      'localOrderHistory': true,
      'passwordResetViaGeneratedLink': true,
      'emailDeliveryTested': false,
      'temporaryAccountRemoved': true,
    }),
  );
}
