library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/vault_store.dart';
import '../providers/app_providers.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../widgets/munshi_app_bar.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.initialDay});

  final String? initialDay;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;
  late String _selectedIso;

  @override
  void initState() {
    super.initState();
    _month = DateTime.now();
    _selectedIso = widget.initialDay ?? todayIso;
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(vaultStoreProvider);
    final agenda = vault.listCases().where((c) => c.nextDate == _selectedIso).toList();

    return Scaffold(
      backgroundColor: MunshiColors.ivory,
      appBar: const MunshiAppBar(title: 'Calendar'),
      body: Column(
        children: [
          _monthHeader(),
          _grid(vault),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${fmtShort(_selectedIso)}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (agenda.isEmpty)
                  const Text('No hearings on this day')
                else
                  ...agenda.map(
                    (c) => ListTile(
                      title: Text(c.parties),
                      subtitle: Text('${c.caseNo} · ${c.nextDetail}'),
                      onTap: () => context.push('/cases/${c.id}'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${_months[_month.month - 1]} ${_month.year}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          IconButton(
            tooltip: 'Next month',
            onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _grid(VaultStore vault) {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = first.weekday % 7;
    final cells = <Widget>[];
    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final iso = dayOffsetIsoFrom(_month.year, _month.month, d);
      final dayCases = vault.listCases().where((c) => c.nextDate == iso);
      final hasHearing = dayCases.isNotEmpty;
      final hasUrgentHearing = dayCases.any((c) => c.urgent);
      final selected = iso == _selectedIso;
      final label = StringBuffer('${_months[_month.month - 1]} $d');
      if (hasUrgentHearing) {
        label.write(', urgent hearing');
      } else if (hasHearing) {
        label.write(', has a hearing');
      }
      cells.add(
        Semantics(
          label: label.toString(),
          selected: selected,
          button: true,
          child: InkWell(
            onTap: () => setState(() => _selectedIso = iso),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                // Brass gold marks an urgent day only (CLAUDE.md invariant 13); an
                // ordinary hearing day gets a neutral ink-green tint, not the
                // attention color.
                color: selected
                    ? MunshiColors.inkGreen
                    : hasUrgentHearing
                        ? MunshiColors.brassGold.withValues(alpha: 0.25)
                        : hasHearing
                            ? MunshiColors.inkGreen.withValues(alpha: 0.08)
                            : null,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$d',
                style: TextStyle(
                  fontWeight: hasHearing ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.white : MunshiColors.inkGreen,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(shrinkWrap: true, crossAxisCount: 7, children: cells),
    );
  }

  String dayOffsetIsoFrom(int y, int m, int d) =>
      '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
}
