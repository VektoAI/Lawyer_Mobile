library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../crypto/vault_session.dart';
import '../providers/app_providers.dart';
import '../router_refresh.dart';
import '../services/bootstrap_service.dart';
import '../utils/dates.dart';
import '../utils/error_text.dart';

Future<void> exportVaultBackup(BuildContext context, WidgetRef ref) async {
  final vault = ref.read(vaultStoreProvider);
  try {
    final backup = await vault.exportPwaBackup();
    final json = const JsonEncoder.withIndent('  ').convert(backup);
    final name = 'case-vault-backup-$todayIso.json';
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], text: 'Encrypted vault backup');
    } else {
      await Share.share(json, subject: name);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Encrypted backup ready to save/share')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create the backup: ${friendlyError(e)}')));
    }
  }
}

Future<void> importVaultBackup(BuildContext context, WidgetRef ref) async {
  final pick = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
  if (pick == null || pick.files.single.path == null) return;
  final text = await File(pick.files.single.path!).readAsString();
  final json = jsonDecode(text) as Map<String, dynamic>;

  if (!context.mounted) return;
  final password = await _promptPassword(context, title: 'Unlock backup', hint: 'Account password or recovery key');
  if (password == null || password.isEmpty) return;

  if (!context.mounted) return;
  final useRecovery = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Recovery key?'),
      content: const Text('Did you enter your 64-character recovery key (not your login password)?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Password')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Recovery key')),
      ],
    ),
  );
  if (useRecovery == null) return;

  try {
    await ref.read(vaultStoreProvider).importAndUnlockBackup(
          json: json,
          passwordOrRecovery: password,
          isRecoveryKey: useRecovery,
        );
    notifyRouterVaultChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored')));
      // Router redirect will send to /cases if unlocked
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not restore this backup: ${friendlyError(e)}')));
    }
  }
}

Future<void> showVaultVerifySheet(BuildContext context) async {
  final cryptoOk = await vaultSelfTest();
  final api = await fetchBootstrapStatus();
  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vault verify', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            _checkRow('Crypto round-trip (PBKDF2 + AES-GCM)', cryptoOk),
            _checkRow('Auth API ${api.ok ? "(${api.mode})" : ""}', api.ok, warn: !api.ok),
            const SizedBox(height: 8),
            Text(
              api.message,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Court live ingest runs on the server (DRT adapters). This app stores cases encrypted on device; causelist sync ships when the relay is wired.',
              style: TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _checkRow(String label, bool pass, {bool warn = false}) {
  final icon = pass ? Icons.check_circle : (warn ? Icons.warning : Icons.cancel);
  final color = pass ? Colors.green.shade700 : (warn ? Colors.orange : Colors.red);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

Future<String?> _promptPassword(BuildContext context, {required String title, required String hint}) async {
  final ctrl = TextEditingController();
  final v = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        obscureText: true,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Continue')),
      ],
    ),
  );
  ctrl.dispose();
  return v;
}

Future<void> showRecoveryKeyDialog(BuildContext context, String recoveryHex) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Save recovery key'),
      content: SelectableText(
        'Shown once. If you lose your password and this key, your cases cannot be recovered.\n\n$recoveryHex',
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('I saved it')),
      ],
    ),
  );
}
