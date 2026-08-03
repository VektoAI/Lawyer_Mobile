library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router_refresh.dart';
import '../data/vault_store.dart';
import '../providers/app_providers.dart';
import 'sheets.dart';
import 'vault_backup_ui.dart';
import '../services/account_service.dart';
import '../services/auth_service.dart';
import '../services/hearing_reminder_service.dart';
import '../services/hearing_sync_service.dart';
import '../copy/product_copy.dart';
import '../theme.dart';
import '../utils/error_text.dart';
import '../widgets/munshi_app_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _deletingAccount = false;

  @override
  Widget build(BuildContext context) {
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
          _sectionHeader('Vault & sync'),
          _tile('Vault status', '$active active case(s) on this device'),
          _tile('Sync', vault.lastSyncLabel),
          if (vault.isDemo) _tile('Account type', ProductCopy.guestAccountType),
          _sectionHeader('Notifications'),
          ListTile(
            title: const Text('Hearing alerts'),
            subtitle: const Text('~7 PM (tomorrow) & ~7:30 AM (today) — local notifications'),
            onTap: () async {
              final svc = HearingReminderService.instance;
              final on = await svc.isEnabled();
              if (on) {
                await svc.setEnabled(false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hearing alerts turned off')));
                }
              } else {
                await svc.setEnabled(true);
                await svc.refreshFromVault(vault);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hearing alerts turned on')));
                }
              }
            },
          ),
          ListTile(
            title: const Text('Refresh court hearing dates'),
            subtitle: const Text('Checks DRT cause lists for your tracked cases'),
            onTap: () async {
              final n = await autoSyncCourtHearings(vault);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(n > 0 ? 'Updated $n case(s) from the court cause list' : 'No new hearing dates on the current cause list')),
                );
              }
            },
          ),
          _sectionHeader('Security & backup'),
          ListTile(
            title: const Text('Vault verify'),
            subtitle: const Text('Confirms encryption is working and the API is reachable'),
            onTap: () => showVaultVerifySheet(context),
          ),
          ListTile(
            title: const Text('Export encrypted backup'),
            subtitle: Text(vault.lastBackupAt != null ? 'Last backed up ${vault.lastBackupAt!.substring(0, 16)}' : 'Save an encrypted copy — compatible with the web app'),
            onTap: () => exportVaultBackup(context, ref),
          ),
          ListTile(
            title: const Text('Restore from backup'),
            subtitle: const Text('Import from the web app or another phone'),
            onTap: () => importVaultBackup(context, ref),
          ),
          _sectionHeader('Privacy & legal'),
          ListTile(
            title: const Text('Privacy Policy'),
            onTap: () => context.push('/privacy'),
          ),
          _sectionHeader('Account'),
          if (!vault.isDemo)
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete account', style: TextStyle(color: Colors.red)),
              subtitle: Text(_deletingAccount ? 'Deleting…' : 'Permanently deletes your sign-in account'),
              onTap: _deletingAccount ? null : () => _deleteAccount(context, ref, vault),
            ),
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

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: MunshiColors.inkGreen.withValues(alpha: 0.55),
          ),
        ),
      );

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref, VaultStore vault) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your sign-in account and chamber profile '
          'from our servers. It cannot be undone.\n\n'
          'Case data stored on this device is not affected by this action — '
          'export a backup first from Profile if you want to keep it.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete account', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deletingAccount = true);

    // Only this call can fail with "could not delete account" — once it
    // succeeds, the account is already gone server-side, so nothing after
    // this point should ever be reported back as a deletion failure.
    try {
      await deleteAccount(ref.read(apiClientProvider));
    } on AuthException catch (e) {
      if (mounted) setState(() => _deletingAccount = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete your account: ${e.message}')));
      }
      return;
    } catch (e) {
      if (mounted) setState(() => _deletingAccount = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete your account: ${friendlyError(e)}')));
      }
      return;
    }

    vault.lock();
    await ref.read(authServiceProvider).clearSession();
    notifyRouterVaultChanged();
    if (context.mounted) context.go('/login');
  }
}
