library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router_refresh.dart';
import '../providers/app_providers.dart';
import 'sheets.dart';
import 'vault_backup_ui.dart';
import '../services/hearing_reminder_service.dart';
import '../services/hearing_sync_service.dart';
import '../copy/product_copy.dart';
import '../theme.dart';
import '../widgets/munshi_app_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultStoreProvider);
    final p = vault.profile;
    final active = vault.listCases().length;

    return Scaffold(
      backgroundColor: MunshiColors.ivory,
      appBar: MunshiAppBar(
        title: 'Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit chamber profile',
            onPressed: () => showProfileEditSheet(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: MunshiColors.inkGreen,
            child: Text(
              p.initials.isNotEmpty ? p.initials : '?',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontFamily: 'Fraunces'),
            ),
          ),
          const SizedBox(height: 12),
          Text(p.name.isNotEmpty ? p.name : 'Chamber profile', style: Theme.of(context).textTheme.headlineSmall),
          if (p.enrolment.isNotEmpty) Text('Enrolment ${p.enrolment}'),
          if (p.barCouncil.isNotEmpty) Text(p.barCouncil),
          if (p.phone.isNotEmpty) Text('Mobile ${p.phone}'),
          if (p.chamber.isNotEmpty) Text(p.chamber, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 24),
          _tile('Vault status', '$active active case(s) on this device'),
          _tile('Sync', vault.lastSyncLabel),
          if (vault.isDemo) _tile('Account type', ProductCopy.guestAccountType),
          ListTile(
            title: const Text('Hearing alerts'),
            subtitle: const Text('~7 PM (tomorrow) & ~7:30 AM (today) — local notifications'),
            onTap: () async {
              final svc = HearingReminderService.instance;
              final on = await svc.isEnabled();
              if (on) {
                await svc.setEnabled(false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hearing alerts off')));
                }
              } else {
                await svc.setEnabled(true);
                await svc.refreshFromVault(vault);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hearing alerts on')));
                }
              }
            },
          ),
          ListTile(
            title: const Text('Refresh court hearing dates'),
            subtitle: const Text('Auto-checks DRT cause lists for your tracked cases'),
            onTap: () async {
              final n = await autoSyncCourtHearings(vault);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(n > 0 ? 'Updated $n case(s) from court lists' : 'No new dates on checked lists')),
                );
              }
            },
          ),
          ListTile(
            title: const Text('Vault verify'),
            subtitle: const Text('Crypto self-test + API reachability'),
            onTap: () => showVaultVerifySheet(context),
          ),
          ListTile(
            title: const Text('Export encrypted backup'),
            subtitle: Text(vault.lastBackupAt != null ? 'Last · ${vault.lastBackupAt!.substring(0, 16)}' : 'PWA-compatible munshi-vault-backup-v1'),
            onTap: () => exportVaultBackup(context, ref),
          ),
          ListTile(
            title: const Text('Restore from backup'),
            subtitle: const Text('Import from web app or another phone'),
            onTap: () => importVaultBackup(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              vault.lock();
              await ref.read(authServiceProvider).clearSession();
              notifyRouterVaultChanged();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(String title, String sub) => ListTile(title: Text(title), subtitle: Text(sub));
}
