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
        title: 'Documents',
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined, size: 36, color: MunshiColors.inkGreen.withValues(alpha: 0.35)),
                    const SizedBox(height: 14),
                    Text(
                      'No documents yet',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MunshiColors.inkGreen.withValues(alpha: 0.85)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vault.readOnly
                          ? 'Documents uploaded to a case will appear here.'
                          : 'Documents you upload to a case — pleadings, orders, evidence — appear here, encrypted on this device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, height: 1.4, color: MunshiColors.inkGreen.withValues(alpha: 0.6)),
                    ),
                    if (!vault.readOnly) ...[
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => showUploadDocSheet(context, ref),
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Upload a document'),
                      ),
                    ],
                  ],
                ),
              ),
            )
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
