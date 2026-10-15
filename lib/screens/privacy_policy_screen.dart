import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <(String, String)>[
    (
      'Information we collect',
      'We collect the account details you provide (name and email), the '
          'device identifier used to bind your account, and the verification '
          'data you capture, which can include address details, GPS '
          'coordinates and photos.',
    ),
    (
      'How we use it',
      'Your data is used solely to run and sync residence verifications. '
          'Verification records are associated with your account and are not '
          'shared with third parties outside your organisation.',
    ),
    (
      'Device binding',
      'To protect your account, sign-in is restricted to the device used at '
          'registration. Signing in from another device is blocked.',
    ),
    (
      'Permissions',
      'Camera and location permissions are used only while you are '
          'capturing verification evidence. You can revoke them any time from '
          'your device settings.',
    ),
    (
      'Data retention',
      'Verification data is retained while your account remains active. You '
          'can request deletion of your account and associated data at any '
          'time.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Your privacy matters',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Last updated: September 2026',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            for (final section in _sections) ...[
              Text(
                section.$1,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(section.$2, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}
