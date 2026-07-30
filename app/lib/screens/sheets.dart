library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/courts.dart';
import '../models/case_models.dart';
import '../providers/app_providers.dart';
import '../services/account_service.dart';
import '../services/court_lookup_service.dart';
import '../utils/dates.dart';

Future<void> showAddCaseSheet(BuildContext context, WidgetRef ref) async {
  final partiesCtrl = TextEditingController();
  final caseNoCtrl = TextEditingController();
  var court = kCourts.first.name;
  var courtId = kCourts.first.id;
  DateTime? nextDate;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom, left: 16, right: 16, top: 16),
      child: StatefulBuilder(
        builder: (ctx, setSt) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add case', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: courtId,
              items: [for (final c in kCourts) DropdownMenuItem(value: c.id, child: Text(c.name))],
              onChanged: (v) => setSt(() {
                courtId = v ?? courtId;
                court = kCourts.firstWhere((c) => c.id == courtId).name;
              }),
              decoration: const InputDecoration(labelText: 'Court'),
            ),
            TextField(controller: caseNoCtrl, decoration: const InputDecoration(labelText: 'Case number')),
            TextField(controller: partiesCtrl, decoration: const InputDecoration(labelText: 'Parties')),
            ListTile(
              title: Text(nextDate == null ? 'Next hearing (optional)' : 'Next: ${nextDate!.toIso8601String().substring(0, 10)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(context: ctx, firstDate: DateTime(2020), lastDate: DateTime(2035), initialDate: DateTime.now());
                if (picked != null) setSt(() => nextDate = picked);
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final partiesInput = partiesCtrl.text.trim();
                final caseNo = caseNoCtrl.text.trim();
                if (caseNo.isEmpty) return;
                var parties = partiesInput.isNotEmpty ? partiesInput : 'New matter · $caseNo';
                var stage = 'From your diary';
                var nextDetail = nextDate != null ? 'From your diary' : 'Add a hearing date when you know it';
                final iso = nextDate != null ? nextDate!.toIso8601String().substring(0, 10) : null;

                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(const SnackBar(content: Text('Checking court list…')));

                try {
                  final hit = await lookupCaseOnCourt(
                    api: ref.read(apiClientProvider),
                    courtId: courtId,
                    caseNo: caseNo,
                    listDate: iso,
                  );
                  if (hit.found) {
                    if (hit.parties != null && hit.parties!.isNotEmpty) parties = hit.parties!;
                    if (hit.stage != null) stage = hit.stage!;
                    if (hit.nextDetail != null) nextDetail = hit.nextDetail!;
                    messenger.showSnackBar(const SnackBar(content: Text('Matched on court cause list')));
                  } else if (hit.warning != null) {
                    messenger.showSnackBar(SnackBar(content: Text('⚠️ ${hit.warning}')));
                  }
                } catch (_) {
                  messenger.showSnackBar(const SnackBar(content: Text('⚠️ Could not verify court — saving locally')));
                }

                final c = await ref.read(vaultStoreProvider).upsertCase(
                      court: court,
                      caseNo: caseNo,
                      parties: parties,
                      nextDate: iso,
                    );
                final updated = MunshiCase.fromJson(c.toJson());
                updated.stage = stage;
                updated.nextDetail = nextDetail;
                await ref.read(vaultStoreProvider).updateCaseFields(c.id, updated);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) context.push('/cases/${c.id}');
              },
              child: const Text('Add & start tracking'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

Future<void> showPaymentSheet(BuildContext context, WidgetRef ref, {String? caseId}) async {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  var mode = 'UPI';
  var selectedCase = caseId;
  final vault = ref.read(vaultStoreProvider);
  final cases = vault.listCases();
  if (selectedCase == null && cases.isNotEmpty) selectedCase = cases.first.id;
  var date = todayIso;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom, left: 16, right: 16, top: 16),
      child: StatefulBuilder(
        builder: (ctx, setSt) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Record payment', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Integer rupees · saved on this device only'),
            if (caseId == null)
              DropdownButtonFormField<String>(
                value: selectedCase,
                items: [for (final c in cases) DropdownMenuItem(value: c.id, child: Text(c.parties, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setSt(() => selectedCase = v),
                decoration: const InputDecoration(labelText: 'Case'),
              ),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)')),
            DropdownButtonFormField<String>(
              value: mode,
              items: const [
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Bank transfer', child: Text('Bank transfer')),
                DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
              ],
              onChanged: (v) => setSt(() => mode = v ?? mode),
              decoration: const InputDecoration(labelText: 'Mode'),
            ),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note')),
            FilledButton(
              onPressed: () async {
                final cid = selectedCase;
                if (cid == null) return;
                final amt = int.tryParse(amountCtrl.text.trim());
                if (amt == null || amt < 1) return;
                await vault.addPayment(cid, amount: amt, mode: mode, note: noteCtrl.text.trim(), date: date);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save payment'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

Future<void> showEditCaseSheet(BuildContext context, WidgetRef ref, MunshiCase c) async {
  final parties = TextEditingController(text: c.parties);
  final caseNo = TextEditingController(text: c.caseNo);
  final court = TextEditingController(text: c.court);
  final stage = TextEditingController(text: c.stage);
  final detail = TextEditingController(text: c.nextDetail);
  final clientName = TextEditingController(text: c.client.name);
  final clientPhone = TextEditingController(text: c.client.phone);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit case', style: Theme.of(ctx).textTheme.titleLarge),
            TextField(controller: parties, decoration: const InputDecoration(labelText: 'Parties')),
            TextField(controller: caseNo, decoration: const InputDecoration(labelText: 'Case number')),
            TextField(controller: court, decoration: const InputDecoration(labelText: 'Court')),
            TextField(controller: stage, decoration: const InputDecoration(labelText: 'Stage')),
            TextField(controller: detail, decoration: const InputDecoration(labelText: 'Next detail')),
            TextField(controller: clientName, decoration: const InputDecoration(labelText: 'Client name')),
            TextField(controller: clientPhone, decoration: const InputDecoration(labelText: 'Client phone')),
            FilledButton(
              onPressed: () async {
                final updated = MunshiCase.fromJson(c.toJson());
                updated.parties = parties.text.trim();
                updated.caseNo = caseNo.text.trim();
                updated.court = court.text.trim();
                updated.stage = stage.text.trim();
                updated.nextDetail = detail.text.trim();
                updated.client = ClientInfo(name: clientName.text.trim(), phone: clientPhone.text.trim());
                await ref.read(vaultStoreProvider).updateCaseFields(c.id, updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save changes'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

Future<void> showFeeAgreedSheet(BuildContext context, WidgetRef ref, String caseId) async {
  final ctrl = TextEditingController();
  await showModalBottomSheet(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Fee agreed', style: Theme.of(ctx).textTheme.titleLarge),
          TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)')),
          FilledButton(
            onPressed: () async {
              final v = int.tryParse(ctrl.text.trim());
              if (v == null) return;
              await ref.read(vaultStoreProvider).setFeeAgreed(caseId, v);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showProfileEditSheet(BuildContext context, WidgetRef ref) async {
  final vault = ref.read(vaultStoreProvider);
  final p = vault.profile;
  final name = TextEditingController(text: p.name);
  final enrol = TextEditingController(text: p.enrolment);
  final bar = TextEditingController(text: p.barCouncil);
  final chamber = TextEditingController(text: p.chamber);
  final phone = TextEditingController(text: p.phone);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Chamber profile', style: Theme.of(ctx).textTheme.titleLarge),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: enrol, decoration: const InputDecoration(labelText: 'Enrolment no.')),
          TextField(controller: bar, decoration: const InputDecoration(labelText: 'Bar council')),
          TextField(controller: chamber, decoration: const InputDecoration(labelText: 'Chamber address')),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Your mobile (WhatsApp)')),
          FilledButton(
            onPressed: () async {
              final n = name.text.trim();
              final initials = n.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();
              final updated = ChamberProfile(
                name: n,
                enrolment: enrol.text.trim(),
                barCouncil: bar.text.trim(),
                chamber: chamber.text.trim(),
                phone: phone.text.trim(),
                initials: initials,
              );
              await vault.putProfile(updated);
              try {
                await patchAccountProfile(
                  ref.read(apiClientProvider),
                  displayName: updated.name,
                  enrolment: updated.enrolment,
                  barCouncil: updated.barCouncil,
                  chamber: updated.chamber,
                  phone: updated.phone,
                );
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save profile'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

Future<void> showReferencesSheet(BuildContext context, WidgetRef ref, String caseId) async {
  final vault = ref.read(vaultStoreProvider);
  final c = vault.getCase(caseId);
  if (c == null) return;
  final ctrl = TextEditingController(text: c.references);
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Statutes & case references', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Sections, citations, points to argue — encrypted on this device.', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'e.g. S. 138 NI Act; Sec 482 CrPC; Priya Sharma v. State…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              await vault.updateReferences(caseId, text);
              if (text.isNotEmpty) {
                await vault.addEvent(
                  caseId,
                  CaseUpdate(date: todayIso, side: 'lawyer', kind: 'reference', time: 'Now', text: 'References updated', sub: text.length > 100 ? '${text.substring(0, 100)}…' : text),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save references'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

Future<void> showAttachSheet(BuildContext context, WidgetRef ref, String caseId) async {
  await showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.task_alt),
            title: const Text('Task / reminder'),
            onTap: () async {
              Navigator.pop(ctx);
              await ref.read(vaultStoreProvider).addEvent(
                    caseId,
                    CaseUpdate(date: todayIso, side: 'lawyer', kind: 'task', time: 'Now', text: 'Task logged', sub: 'Due date — set in calendar'),
                  );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Document'),
            onTap: () {
              Navigator.pop(ctx);
              showAddDocToCaseSheet(context, ref, caseId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.currency_rupee),
            title: const Text('Record a fee payment'),
            onTap: () {
              Navigator.pop(ctx);
              showPaymentSheet(context, ref, caseId: caseId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Statutes & case references'),
            onTap: () {
              Navigator.pop(ctx);
              showReferencesSheet(context, ref, caseId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups),
            title: const Text('Client meeting / call'),
            onTap: () async {
              Navigator.pop(ctx);
              await ref.read(vaultStoreProvider).addEvent(
                    caseId,
                    CaseUpdate(date: todayIso, side: 'lawyer', kind: 'client', time: 'Now', text: 'Client meeting logged'),
                  );
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> showAddDocToCaseSheet(BuildContext context, WidgetRef ref, String caseId) async {
  final nameCtrl = TextEditingController();
  await showModalBottomSheet(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Document name')),
          FilledButton(
            onPressed: () async {
              final n = nameCtrl.text.trim();
              if (n.isEmpty) return;
              await ref.read(vaultStoreProvider).addDocumentMeta(caseId, n);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add to case file'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showUploadDocSheet(BuildContext context, WidgetRef ref) async {
  final vault = ref.read(vaultStoreProvider);
  final cases = vault.listCases();
  if (cases.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a case first')));
    return;
  }
  var caseId = cases.first.id;
  final nameCtrl = TextEditingController();
  await showModalBottomSheet(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: caseId,
              items: [for (final c in cases) DropdownMenuItem(value: c.id, child: Text(c.parties, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setSt(() => caseId = v ?? caseId),
              decoration: const InputDecoration(labelText: 'Case'),
            ),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'File name')),
            FilledButton(
              onPressed: () async {
                final n = nameCtrl.text.trim();
                if (n.isEmpty) return;
                await vault.addDocumentMeta(caseId, n);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    ),
  );
}
