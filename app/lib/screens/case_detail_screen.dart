library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/vault_store.dart';
import '../models/case_models.dart';
import '../providers/app_providers.dart';
import '../copy/product_copy.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../utils/rupee.dart';
import '../widgets/case_widgets.dart';
import '../widgets/munshi_app_bar.dart';
import 'sheets.dart';

class CaseDetailScreen extends ConsumerStatefulWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vaultStoreProvider).clearUnread(widget.caseId);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(vaultStoreProvider);
    final c = vault.getCase(widget.caseId);
    if (c == null) {
      return Scaffold(
        appBar: MunshiAppBar.withBack(context, title: 'Case'),
        body: const Center(child: Text('Case not found')),
      );
    }

    return Scaffold(
      backgroundColor: MunshiColors.ivory,
      appBar: MunshiAppBar.withBack(
        context,
        title: c.caseNo,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Case options',
            onPressed: () => _caseMenu(context, vault, c),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(c.parties, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('${c.court} · ${c.stage}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ),
          if (c.references.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.menu_book, color: MunshiColors.inkGreen),
                  title: const Text('References & statutes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(c.references, maxLines: 3, overflow: TextOverflow.ellipsis),
                  onTap: vault.readOnly ? null : () => showReferencesSheet(context, ref, c.id),
                ),
              ),
            ),
          TabBar(
            controller: _tabs,
            labelColor: MunshiColors.inkGreen,
            tabs: const [Tab(text: 'Updates'), Tab(text: 'Hearings'), Tab(text: 'Docs'), Tab(text: 'Fees')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _updatesTab(vault, c),
                _hearingsTab(c),
                _docsTab(vault, c),
                _feesTab(vault, c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _updatesTab(VaultStore vault, MunshiCase c) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              for (final u in c.updates) ChatBubble(update: u),
            ],
          ),
        ),
        if (!vault.readOnly)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add to case',
                    onPressed: () => showAttachSheet(context, ref, c.id),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Add a note…',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: MunshiColors.inkGreen),
                    tooltip: 'Send note',
                    onPressed: () async {
                      final t = _noteCtrl.text.trim();
                      if (t.isEmpty) return;
                      await vault.addNote(c.id, t);
                      _noteCtrl.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _hearingsTab(MunshiCase c) {
    if (c.hearings.isEmpty) return const Center(child: Text('No hearings logged'));
    return ListView.builder(
      itemCount: c.hearings.length,
      itemBuilder: (_, i) {
        final h = c.hearings[i];
        return ListTile(
          title: Text(fmtShort(h.date)),
          subtitle: Text('${h.purpose}${h.outcome != null ? '\n${h.outcome}' : ''}'),
        );
      },
    );
  }

  Widget _docsTab(VaultStore vault, MunshiCase c) {
    return ListView(
      children: [
        if (!vault.readOnly)
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Add document'),
            onTap: () => showAddDocToCaseSheet(context, ref, c.id),
          ),
        ...c.docs.map(
          (d) => ListTile(
            leading: Icon(d.pdf ? Icons.picture_as_pdf : Icons.table_chart),
            title: Text(d.name),
            subtitle: Text('${d.size} · ${d.date}'),
          ),
        ),
      ],
    );
  }

  Widget _feesTab(VaultStore vault, MunshiCase c) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Agreed ${rupee(c.fee.agreed)} · Collected ${rupee(c.collectedRupees)} · Due ${rupee(c.dueRupees)}'),
        const SizedBox(height: 12),
        if (!vault.readOnly) ...[
          OutlinedButton(onPressed: () => showFeeAgreedSheet(context, ref, c.id), child: const Text('Set fee agreed')),
          OutlinedButton(onPressed: () => showPaymentSheet(context, ref, caseId: c.id), child: const Text('Record payment')),
        ],
        const Divider(),
        ...c.payments.map(
          (p) => ListTile(
            title: Text('${rupee(p.amount)} · ${p.mode}'),
            subtitle: Text(p.note),
            trailing: Text(p.date, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  void _caseMenu(BuildContext context, VaultStore vault, MunshiCase c) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!vault.readOnly) ...[
              ListTile(
                title: const Text('Statutes & references'),
                onTap: () {
                  Navigator.pop(ctx);
                  showReferencesSheet(context, ref, c.id);
                },
              ),
              ListTile(
                title: const Text('Edit case'),
                onTap: () {
                  Navigator.pop(ctx);
                  showEditCaseSheet(context, ref, c);
                },
              ),
              ListTile(title: Text(c.pinned ? 'Unpin' : 'Pin'), onTap: () { Navigator.pop(ctx); vault.togglePin(c.id); }),
              ListTile(title: Text(c.urgent ? 'Clear urgent' : 'Mark urgent'), onTap: () { Navigator.pop(ctx); vault.toggleUrgent(c.id); }),
              ListTile(
                title: const Text('Fee agreed'),
                onTap: () {
                  Navigator.pop(ctx);
                  showFeeAgreedSheet(context, ref, c.id);
                },
              ),
              ListTile(
                // "Archive"/"Restore" everywhere in the UI — c.disposed stays the
                // internal field name only (shared JSON key with the PWA backup
                // format; renaming it would break cross-platform restore).
                title: Text(c.disposed ? 'Restore case' : 'Archive case'),
                onTap: () {
                  Navigator.pop(ctx);
                  vault.toggleDisposed(c.id);
                },
              ),
              ListTile(
                title: const Text('Delete case', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Delete this case?'),
                      content: Text(
                        'This permanently deletes "${c.parties}" and its documents from this device. This cannot be undone.',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  await vault.deleteCase(c.id);
                  if (context.mounted) context.pop();
                },
              ),
            ] else
              const ListTile(title: Text(ProductCopy.guestEditDisabled)),
          ],
        ),
      ),
    );
  }
}
