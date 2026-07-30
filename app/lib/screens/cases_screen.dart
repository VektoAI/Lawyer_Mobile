library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/vault_store.dart';
import '../models/case_models.dart';
import '../router_refresh.dart';
import '../providers/app_providers.dart';
import '../services/hearing_reminder_service.dart';
import '../services/hearing_sync_service.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../widgets/case_widgets.dart';
import '../widgets/munshi_app_bar.dart';
import 'sheets.dart';

enum CaseFilter { all, tomorrow, week, urgent }

class CasesScreen extends ConsumerStatefulWidget {
  const CasesScreen({super.key});

  @override
  ConsumerState<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends ConsumerState<CasesScreen> {
  CaseFilter _filter = CaseFilter.all;
  bool _searching = false;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vault = ref.read(vaultStoreProvider);
      await mergeAccountProfileIntoVault(vault);
      final n = await autoSyncCourtHearings(vault);
      await HearingReminderService.instance.refreshFromVault(vault);
      if (n > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated $n case(s) from court cause lists')),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MunshiCase> _filtered(VaultStore vault) {
    var list = vault.listCases();
    switch (_filter) {
      case CaseFilter.tomorrow:
        list = list.where((c) => isSameIso(c.nextDate, tomorrowIso)).toList();
      case CaseFilter.week:
        list = list.where((c) => c.nextDate != null && daysBetweenIso(c.nextDate!) >= 0 && daysBetweenIso(c.nextDate!) <= 7).toList();
      case CaseFilter.urgent:
        list = list.where((c) => c.urgent).toList();
      case CaseFilter.all:
        break;
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        return c.caseNo.toLowerCase().contains(q) ||
            c.parties.toLowerCase().contains(q) ||
            c.court.toLowerCase().contains(q) ||
            c.cnr.toLowerCase().contains(q) ||
            c.client.name.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  void _startSearch() => setState(() => _searching = true);

  void _stopSearch() {
    _searchController.clear();
    setState(() {
      _searching = false;
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(vaultStoreProvider);
    final cases = _filtered(vault);
    final tomorrowCases = vault.listCases().where((c) => isSameIso(c.nextDate, tomorrowIso)).toList();

    return Scaffold(
      backgroundColor: MunshiColors.ivory,
      appBar: MunshiAppBar(
        title: 'Cases',
        titleWidget: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search case number, parties, court…',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: _searching ? 'Close search' : 'Search cases',
            onPressed: _searching ? _stopSearch : _startSearch,
          ),
          if (!_searching)
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onPressed: () => _homeMenu(context, vault),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: MunshiColors.inkGreen,
            child: InkWell(
              onTap: () => context.go('/calendar?day=$tomorrowIso'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tomorrowCases.isEmpty
                          ? 'No hearings tomorrow'
                          : 'Tomorrow — ${tomorrowCases.length} hearing${tomorrowCases.length > 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Fraunces'),
                    ),
                    Text(
                      '${fmtShort(tomorrowIso)}${tomorrowCases.isNotEmpty ? ' · ${tomorrowCases.map((c) => c.court.split(',').first).toSet().join(' · ')}' : ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _chip('All', CaseFilter.all),
                _chip('Tomorrow', CaseFilter.tomorrow),
                _chip('This week', CaseFilter.week),
                _chip('Urgent', CaseFilter.urgent),
              ],
            ),
          ),
          if (cases.isEmpty && (_query.trim().isNotEmpty || _filter != CaseFilter.all))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  _query.trim().isNotEmpty ? 'No cases match "${_query.trim()}"' : 'No cases match this filter',
                  style: TextStyle(color: MunshiColors.inkGreen.withValues(alpha: 0.6)),
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: cases.length + 1,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i == cases.length) {
                  return ListTile(
                    title: const Text('Archived cases'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/archived'),
                  );
                }
                final c = cases[i];
                return CaseListTile(
                  caseItem: c,
                  onTap: () => context.push('/cases/${c.id}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: vault.readOnly
          ? null
          : FloatingActionButton(
              backgroundColor: MunshiColors.inkGreen,
              onPressed: () => showAddCaseSheet(context, ref),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _chip(String label, CaseFilter f) {
    final selected = _filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = f),
        selectedColor: MunshiColors.inkGreen.withValues(alpha: 0.15),
        checkmarkColor: MunshiColors.inkGreen,
      ),
    );
  }

  void _homeMenu(BuildContext context, VaultStore vault) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!vault.readOnly)
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add case'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddCaseSheet(context, ref);
                },
              ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Tomorrow's cause list"),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/calendar?day=$tomorrowIso');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () {
                Navigator.pop(ctx);
              vault.lock();
              notifyRouterVaultChanged();
              context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
