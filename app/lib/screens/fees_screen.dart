library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/case_models.dart';
import '../providers/app_providers.dart';
import '../screens/sheets.dart';
import '../theme.dart';
import '../utils/rupee.dart';
import '../widgets/munshi_app_bar.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultStoreProvider);
    final cases = vault.listCases(includeDisposed: true);
    var totalAgreed = 0;
    var totalCollected = 0;
    final recent = <({CasePayment pay, MunshiCase c})>[];

    for (final c in cases) {
      totalAgreed += c.fee.agreed;
      totalCollected += c.collectedRupees;
      for (final p in c.payments) {
        recent.add((pay: p, c: c));
      }
    }
    recent.sort((a, b) => b.pay.date.compareTo(a.pay.date));

    return Scaffold(
      backgroundColor: MunshiColors.ivory,
      appBar: const MunshiAppBar(title: 'Fees'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statCard('Agreed (all matters)', rupee(totalAgreed)),
          _statCard('Collected', rupee(totalCollected)),
          _statCard('Outstanding', rupee((totalAgreed - totalCollected).clamp(0, 1 << 31))),
          const SizedBox(height: 16),
          Text('Outstanding by case', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...cases.where((c) => c.dueRupees > 0).map(
                (c) => ListTile(
                  title: Text(c.parties, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(rupee(c.dueRupees), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent payments', style: Theme.of(context).textTheme.titleMedium),
              if (!vault.readOnly)
                TextButton(
                  onPressed: () => showPaymentSheet(context, ref),
                  child: const Text('+ Record'),
                ),
            ],
          ),
          ...recent.take(15).map(
                (r) => ListTile(
                  title: Text('${rupee(r.pay.amount)} · ${r.pay.mode}'),
                  subtitle: Text('${r.c.parties} · ${r.pay.note}'),
                  trailing: Text(r.pay.date, style: const TextStyle(fontSize: 12)),
                ),
              ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Fraunces', fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
