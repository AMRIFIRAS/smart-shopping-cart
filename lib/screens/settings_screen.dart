import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/app_session.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'receipt_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool busy = false;
  final profileName = TextEditingController();
  String? profileIdentity;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final account = SessionScope.of(context).account;
    final identity = '${account?.uid}:${account?.displayName}';
    if (identity != profileIdentity) {
      profileIdentity = identity;
      profileName.text = account?.displayName ?? '';
    }
  }

  @override
  void dispose() {
    profileName.dispose();
    super.dispose();
  }

  String? feedback;
  Future<void> action(Future<void> Function() callback, String success) async {
    setState(() {
      busy = true;
      feedback = null;
    });
    try {
      await callback();
      if (mounted) setState(() => feedback = success);
    } catch (error) {
      if (mounted) setState(() => feedback = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final account = session.account;
    return PageBody(
      maxWidth: 800,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeading(
            eyebrow: 'Make yourself at home',
            title: 'Settings',
            subtitle: 'Shop freely. An account is always optional.',
          ),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE8EEDF),
                      child: Icon(Icons.person_outline, color: forest),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LText(
                        account == null ? 'Guest shopping' : 'Profile',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (account == null) ...[
                  const LText(
                    'Your cart is saved on this device. No account needed.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton(
                        key: const Key('settings-sign-in'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AuthScreen(),
                          ),
                        ),
                        child: const LText('Sign In'),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AuthScreen(create: true),
                          ),
                        ),
                        child: const LText('Create Account'),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(account.email, textDirection: TextDirection.ltr),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('profile-name'),
                    controller: profileName,
                    maxLength: 60,
                    decoration: InputDecoration(
                      labelText: context.tr('Display name (optional)'),
                    ),
                  ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => action(
                            () => session.auth.updateDisplayName(
                              profileName.text,
                            ),
                            'Profile updated.',
                          ),
                    child: const LText('Save profile'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => action(
                            session.auth.signOut,
                            'Signed out. Guest shopping is ready.',
                          ),
                    child: const LText('Sign Out'),
                  ),
                ],
                if (feedback != null || session.authError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LText(
                      feedback ?? session.authError!,
                      style: const TextStyle(color: forest),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LText(
                  'Language',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      key: const Key('language-en'),
                      label: const LText('English'),
                      selected: session.locale.languageCode == 'en',
                      onSelected: (_) => session.setLanguage('en'),
                    ),
                    ChoiceChip(
                      key: const Key('language-ar'),
                      label: const LText('Arabic'),
                      selected: session.locale.languageCode == 'ar',
                      onSelected: (_) => session.setLanguage('ar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (account != null) ...[
            const SizedBox(height: 18),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LText(
                    'Order history',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (session.orders.isEmpty) ...[
                    const LText('No orders yet'),
                    const SizedBox(height: 8),
                    const InfoNote(
                      'Your completed orders will appear here when you shop while signed in.',
                    ),
                  ],
                  ...session.orders.map(
                    (order) => Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.receipt_long_outlined,
                          color: forest,
                        ),
                        title: Text(
                          order.number,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: LText(
                          'SAR ${(order.totalHalalas / 100).toStringAsFixed(2)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReceiptScreen(
                              order: order,
                              history: true,
                              onNewTrip: () {},
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          const SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LText(
                  'About SmartCart',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12),
                LText(
                  'SmartCart is a university graduation prototype for QR-assisted supermarket shopping. All payments are simulated. Prices and nutrition are editable demo data.',
                ),
                Divider(),
                LText(
                  'Privacy notice',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12),
                LText(
                  'Guest carts and language preferences are saved in this browser. Account passwords are handled by Firebase Authentication, never stored by this app. Signed-in order history is currently stored on this device, separately for each account. Camera frames stay on your device. No real payment data is collected.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
