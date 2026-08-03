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
    final outstanding = cases.where((c) => c.dueRupees > 0).toList();
    final recentShown = recent.take(15).toList();

    // A lawyer with thousands of cases can have thousands of outstanding-due
    // rows here — building them all eagerly (as plain ListView children,
    // regardless of scroll position) is real, avoidable work at that scale.
    // CustomScrollView + SliverList.builder keeps the exact same visual
    // layout (same padding, same widgets, same order) but only builds the
    // rows actually on/near screen.
    return Scaffold(
      backgroundColor: MunshiColors.ivory,
      appBar: const MunshiAppBar(title: 'Fees'),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statCard('Agreed (all cases)', rupee(totalAgreed)),
                      _statCard('Collected', rupee(totalCollected)),
                      _statCard('Outstanding', rupee((totalAgreed - totalCollected).clamp(0, 1 << 31))),
                      const SizedBox(height: 16),
                      Text('Outstanding by case', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                if (outstanding.isEmpty)
                  SliverToBoxAdapter(child: _emptyRow('Nothing outstanding — every recorded fee is paid up.'))
                else
                  SliverList.builder(
                    itemCount: outstanding.length,
                    itemBuilder: (context, i) {
                      final c = outstanding[i];
                      return ListTile(
                        key: ValueKey(c.id),
                        title: Text(c.parties, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(rupee(c.dueRupees), style: const TextStyle(fontWeight: FontWeight.w700)),
                      );
                    },
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
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
                  ),
                ),
                if (recentShown.isEmpty)
                  SliverToBoxAdapter(
                    child: _emptyRow(
                      vault.readOnly ? 'No payments recorded yet.' : 'Record a payment to see it here.',
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: recentShown.length,
                    itemBuilder: (context, i) {
                      final r = recentShown[i];
                      return ListTile(
                        key: ValueKey(r.pay.id),
                        title: Text('${rupee(r.pay.amount)} · ${r.pay.mode}'),
                        subtitle: Text('${r.c.parties} · ${r.pay.note}'),
                        trailing: Text(r.pay.date, style: const TextStyle(fontSize: 12)),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyRow(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: MunshiColors.inkGreen.withValues(alpha: 0.55)),
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
