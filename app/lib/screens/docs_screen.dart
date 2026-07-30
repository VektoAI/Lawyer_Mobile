library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../screens/sheets.dart';
import '../theme.dart';
import '../widgets/munshi_app_bar.dart';

class DocsScreen extends ConsumerWidget {
  const DocsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultStoreProvider);
    final rows = <({String caseName, String docName, String size, String caseId})>[];
    for (final c in vault.listCases(includeDisposed: true)) {
      for (final d in c.docs) {
        rows.add((caseName: c.parties, docName: d.name, size: d.size, caseId: c.id));
      }
    }

    return Scaffold(
      backgroundColor: MunshiColors.ivory,
      appBar: MunshiAppBar(
        title: 'Docs',
        actions: [
          if (!vault.readOnly)
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Upload document',
              onPressed: () => showUploadDocSheet(context, ref),
            ),
        ],
      ),
      body: rows.isEmpty
          ? const Center(child: Text('No documents yet'))
          : ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = rows[i];
                return ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(r.docName),
                  subtitle: Text('${r.caseName} · ${r.size}'),
                  onTap: () => context.push('/cases/${r.caseId}'),
                );
              },
            ),
    );
  }
}
