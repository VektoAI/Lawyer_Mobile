library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../theme.dart';
import '../widgets/case_widgets.dart';
import '../widgets/munshi_app_bar.dart';

class ArchivedScreen extends ConsumerWidget {
  const ArchivedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(disposedCasesProvider);
    return Scaffold(
      backgroundColor: MunshiColors.ivory,
      appBar: MunshiAppBar.withBack(context, title: 'Archived'),
      body: cases.isEmpty
          ? const Center(child: Text('No archived cases yet'))
          : ListView.separated(
              itemCount: cases.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => CaseListTile(
                caseItem: cases[i],
                onTap: () => context.push('/cases/${cases[i].id}'),
              ),
            ),
    );
  }
}
