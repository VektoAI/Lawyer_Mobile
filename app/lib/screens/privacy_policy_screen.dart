library;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/munshi_app_bar.dart';

/// Static in-app privacy policy — no network fetch, no CMS. Content describes
/// this app's actual data handling (see backend/app/config.py, deps.py,
/// routers/*.py and app/lib/data/vault_store.dart for what it's grounded in);
/// keep it in sync if either side of that changes.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = '2 August 2026';

  // TODO: replace with the developer's real support/privacy contact address
  // before this ships to either app store.
  static const _contactEmail = 'privacy@example.com';

  @override
  Widget build(BuildContext context) {
    final heading = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: MunshiColors.inkGreen,
        );
    const body = TextStyle(fontSize: 14, height: 1.5);

    Widget section(String title, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: heading),
              const SizedBox(height: 6),
              Text(text, style: body),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: MunshiColors.ivory,
      appBar: MunshiAppBar.withBack(context, title: 'Privacy Policy'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Last updated: $_lastUpdated',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          section(
            'What stays on your device',
            'Case details, client information, notes, hearing history, fees, '
                'payments, and documents are encrypted on this device with a key '
                'derived from your account password. That encrypted data is never '
                'sent to our servers, in any form — we could not read it even if '
                'compelled to.',
          ),
          section(
            'What we do collect',
            'To create and secure your account, we collect your email address, '
                'a password (stored by our authentication provider, never in '
                'plain text), and the chamber-profile details you choose to enter '
                '(display name, enrolment number, bar council, chamber address, '
                'phone). These are used only to run your account and are never '
                'used to reconstruct or access your case data.',
          ),
          section(
            'Court lookups',
            'When you look up a case on a public court cause list, the case '
                'number and court you searched are sent to our server so it can '
                'check the public list on your behalf. This is limited to public '
                'court-listing data — no case notes, client details, or documents '
                'are included in that request.',
          ),
          section(
            'Notifications',
            'Hearing reminders are scheduled entirely on your device using the '
                'hearing dates already stored in your local vault. No hearing or '
                'case data is sent anywhere to generate these reminders.',
          ),
          section(
            'Backups you create',
            'When you export an encrypted backup, the file is generated on your '
                'device and only leaves it if you choose to share or save it '
                'yourself. We do not receive a copy.',
          ),
          section(
            'Service providers',
            'We use Supabase to run account authentication and store your '
                'chamber-profile fields, and Render to host our API. Neither '
                'service receives your case data.',
          ),
          section(
            'Your choices',
            'You can edit or clear your chamber-profile details at any time from '
                'Profile, and you can permanently delete your account from '
                'Profile → Delete account. Deleting your account removes your '
                'authentication record and chamber-profile data from our '
                'servers; case data already stored only on this device is not '
                'affected and can be removed by deleting the app or clearing its '
                'storage.',
          ),
          section(
            'Children',
            'Case Vault is a professional tool for practising lawyers and is not '
                'directed at children.',
          ),
          section(
            'Changes to this policy',
            'If this policy changes, we will update the date at the top of this '
                'page.',
          ),
          section(
            'Contact',
            'Questions about this policy or your data can be sent to '
                '$_contactEmail.',
          ),
        ],
      ),
    );
  }
}
