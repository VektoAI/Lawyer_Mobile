/// Every modal bottom sheet used from the case screens, kept in one file
/// because each is a short, self-contained `showModalBottomSheet` call with
/// no shared state between them — there's no natural split boundary, only
/// natural grouping by what they edit. In file order:
///
/// - [showAddCaseSheet] — new case, with a live court cause-list check.
/// - [showPaymentSheet] — record a fee payment.
/// - [showEditCaseSheet] — edit an existing case's core fields.
/// - [showFeeAgreedSheet] — set the agreed fee amount.
/// - [showProfileEditSheet] — edit the chamber profile.
/// - [showReferencesSheet] — edit a case's statutes/references note.
/// - [showAttachSheet] — the "+" menu on a case's Updates tab (task/
///   document/payment/reference/client-meeting), which itself opens several
///   of the sheets above.
/// - [showAddDocToCaseSheet] / [showUploadDocSheet] — add a document to one
///   case, from the case screen or the Docs tab respectively.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/courts.dart';
import '../models/case_models.dart';
import '../providers/app_providers.dart';
import '../services/account_service.dart';
import '../services/court_lookup_service.dart';
import '../utils/dates.dart';
import '../utils/error_text.dart';

Future<void> showAddCaseSheet(BuildContext context, WidgetRef ref) async {
  final partiesCtrl = TextEditingController();
  final caseNoCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var court = kCourts.first.name;
  var courtId = kCourts.first.id;
  DateTime? nextDate;
  var busy = false;

  try {
    await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom, left: 16, right: 16, top: 16),
      child: StatefulBuilder(
        builder: (ctx, setSt) => Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add case', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: courtId,
                items: [for (final c in kCourts) DropdownMenuItem(value: c.id, child: Text(c.name))],
                onChanged: busy
                    ? null
                    : (v) => setSt(() {
                          courtId = v ?? courtId;
                          court = kCourts.firstWhere((c) => c.id == courtId).name;
                        }),
                decoration: const InputDecoration(labelText: 'Court'),
              ),
              TextFormField(
                controller: caseNoCtrl,
                enabled: !busy,
                decoration: const InputDecoration(labelText: 'Case number'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Case number is required' : null,
              ),
              TextFormField(
                controller: partiesCtrl,
                enabled: !busy,
                decoration: const InputDecoration(labelText: 'Parties'),
              ),
              ListTile(
                title: Text(nextDate == null ? 'Next hearing (optional)' : 'Next: ${nextDate!.toIso8601String().substring(0, 10)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: busy
                    ? null
                    : () async {
                        final picked = await showDatePicker(context: ctx, firstDate: DateTime(2020), lastDate: DateTime(2035), initialDate: DateTime.now());
                        if (picked != null) setSt(() => nextDate = picked);
                      },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        setSt(() => busy = true);

                        final partiesInput = partiesCtrl.text.trim();
                        final caseNo = caseNoCtrl.text.trim();
                        var parties = partiesInput.isNotEmpty ? partiesInput : 'New case · $caseNo';
                        var stage = 'From your diary';
                        var nextDetail = nextDate != null ? 'From your diary' : 'Add a hearing date when you know it';
                        final iso = nextDate?.toIso8601String().substring(0, 10);

                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showSnackBar(const SnackBar(content: Text('Checking the court cause list…')));

                        try {
                          final hit = await lookupCaseOnCourt(
                            api: ref.read(apiClientProvider),
                            courtId: courtId,
                            caseNo: caseNo,
                            listDate: iso,
                          );
                          messenger.hideCurrentSnackBar();
                          if (hit.found) {
                            if (hit.parties != null && hit.parties!.isNotEmpty) parties = hit.parties!;
                            if (hit.stage != null) stage = hit.stage!;
                            if (hit.nextDetail != null) nextDetail = hit.nextDetail!;
                            messenger.showSnackBar(const SnackBar(content: Text('Matched on the court cause list')));
                          } else if (hit.warning != null) {
                            messenger.showSnackBar(SnackBar(content: Text('⚠️ ${hit.warning}')));
                          }
                        } catch (_) {
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(const SnackBar(content: Text('⚠️ Could not verify with the court — saving locally')));
                        }

                        try {
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
                        } catch (e) {
                          setSt(() => busy = false);
                          messenger.showSnackBar(SnackBar(content: Text('Could not save this case: ${friendlyError(e)}')));
                        }
                      },
                child: Text(busy ? 'Adding…' : 'Add & start tracking'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
    );
  } finally {
    partiesCtrl.dispose();
    caseNoCtrl.dispose();
  }
}

Future<void> showPaymentSheet(BuildContext context, WidgetRef ref, {String? caseId}) async {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var mode = 'UPI';
  var selectedCase = caseId;
  final vault = ref.read(vaultStoreProvider);
  final cases = vault.listCases();
  if (caseId == null && cases.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a case first')));
    return;
  }
  if (selectedCase == null && cases.isNotEmpty) selectedCase = cases.first.id;
  var date = todayIso;
  var busy = false;

  try {
    await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom, left: 16, right: 16, top: 16),
      child: StatefulBuilder(
        builder: (ctx, setSt) => Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Record payment', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Integer rupees · saved on this device only'),
              if (caseId == null)
                DropdownButtonFormField<String>(
                  initialValue: selectedCase,
                  items: [for (final c in cases) DropdownMenuItem(value: c.id, child: Text(c.parties, overflow: TextOverflow.ellipsis))],
                  onChanged: busy ? null : (v) => setSt(() => selectedCase = v),
                  decoration: const InputDecoration(labelText: 'Case'),
                  validator: (v) => v == null ? 'Choose a case' : null,
                ),
              TextFormField(
                controller: amountCtrl,
                enabled: !busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
                validator: (v) {
                  final amt = int.tryParse((v ?? '').trim());
                  if (amt == null || amt < 1) return 'Enter a valid amount';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: mode,
                items: const [
                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Bank transfer', child: Text('Bank transfer')),
                  DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                ],
                onChanged: busy ? null : (v) => setSt(() => mode = v ?? mode),
                decoration: const InputDecoration(labelText: 'Mode'),
              ),
              TextFormField(controller: noteCtrl, enabled: !busy, decoration: const InputDecoration(labelText: 'Note')),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        final cid = selectedCase;
                        if (cid == null) return;
                        final amt = int.tryParse(amountCtrl.text.trim())!;
                        setSt(() => busy = true);
                        try {
                          await vault.addPayment(cid, amount: amt, mode: mode, note: noteCtrl.text.trim(), date: date);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setSt(() => busy = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Could not save this payment: ${friendlyError(e)}')));
                          }
                        }
                      },
                child: Text(busy ? 'Saving…' : 'Save payment'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
    );
  } finally {
    amountCtrl.dispose();
    noteCtrl.dispose();
  }
}

Future<void> showEditCaseSheet(BuildContext context, WidgetRef ref, MunshiCase c) async {
  final parties = TextEditingController(text: c.parties);
  final caseNo = TextEditingController(text: c.caseNo);
  final court = TextEditingController(text: c.court);
  final stage = TextEditingController(text: c.stage);
  final detail = TextEditingController(text: c.nextDetail);
  final clientName = TextEditingController(text: c.client.name);
  final clientPhone = TextEditingController(text: c.client.phone);
  final formKey = GlobalKey<FormState>();
  var busy = false;

  try {
    await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom, left: 16, right: 16, top: 16),
      child: StatefulBuilder(
        builder: (ctx, setSt) => SingleChildScrollView(
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit case', style: Theme.of(ctx).textTheme.titleLarge),
                TextFormField(controller: parties, enabled: !busy, decoration: const InputDecoration(labelText: 'Parties')),
                TextFormField(
                  controller: caseNo,
                  enabled: !busy,
                  decoration: const InputDecoration(labelText: 'Case number'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Case number is required' : null,
                ),
                TextFormField(controller: court, enabled: !busy, decoration: const InputDecoration(labelText: 'Court')),
                TextFormField(controller: stage, enabled: !busy, decoration: const InputDecoration(labelText: 'Stage')),
                TextFormField(controller: detail, enabled: !busy, decoration: const InputDecoration(labelText: 'Next detail')),
                TextFormField(controller: clientName, enabled: !busy, decoration: const InputDecoration(labelText: 'Client name')),
                TextFormField(controller: clientPhone, enabled: !busy, decoration: const InputDecoration(labelText: 'Client phone')),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          setSt(() => busy = true);
                          final updated = MunshiCase.fromJson(c.toJson());
                          updated.parties = parties.text.trim();
                          updated.caseNo = caseNo.text.trim();
                          updated.court = court.text.trim();
                          updated.stage = stage.text.trim();
                          updated.nextDetail = detail.text.trim();
                          updated.client = ClientInfo(name: clientName.text.trim(), phone: clientPhone.text.trim());
                          try {
                            await ref.read(vaultStoreProvider).updateCaseFields(c.id, updated);
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setSt(() => busy = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Could not save your changes: ${friendlyError(e)}')));
                            }
                          }
                        },
                  child: Text(busy ? 'Saving…' : 'Save changes'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  } finally {
    parties.dispose();
    caseNo.dispose();
    court.dispose();
    stage.dispose();
    detail.dispose();
    clientName.dispose();
    clientPhone.dispose();
  }
}

Future<void> showFeeAgreedSheet(BuildContext context, WidgetRef ref, String caseId) async {
  final ctrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var busy = false;

  try {
    await showModalBottomSheet(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16),
      child: StatefulBuilder(
        builder: (ctx, setSt) => Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Fee agreed', style: Theme.of(ctx).textTheme.titleLarge),
              TextFormField(
                controller: ctrl,
                enabled: !busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        final v = int.parse(ctrl.text.trim());
                        setSt(() => busy = true);
                        try {
                          await ref.read(vaultStoreProvider).setFeeAgreed(caseId, v);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setSt(() => busy = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Could not save the fee amount: ${friendlyError(e)}')));
                          }
                        }
                      },
                child: Text(busy ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  } finally {
    ctrl.dispose();
  }
}

Future<void> showProfileEditSheet(BuildContext context, WidgetRef ref) async {
  final vault = ref.read(vaultStoreProvider);
  final p = vault.profile;
  final name = TextEditingController(text: p.name);
  final enrol = TextEditingController(text: p.enrolment);
  final bar = TextEditingController(text: p.barCouncil);
  final chamber = TextEditingController(text: p.chamber);
  final phone = TextEditingController(text: p.phone);
  final formKey = GlobalKey<FormState>();
  var busy = false;

  try {
    await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom, left: 16, right: 16, top: 16),
      child: StatefulBuilder(
        builder: (ctx, setSt) => Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Chamber profile', style: Theme.of(ctx).textTheme.titleLarge),
              TextFormField(
                controller: name,
                enabled: !busy,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              TextFormField(controller: enrol, enabled: !busy, decoration: const InputDecoration(labelText: 'Enrolment no.')),
              TextFormField(controller: bar, enabled: !busy, decoration: const InputDecoration(labelText: 'Bar council')),
              TextFormField(controller: chamber, enabled: !busy, decoration: const InputDecoration(labelText: 'Chamber address')),
              TextFormField(
                controller: phone,
                enabled: !busy,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Your mobile (WhatsApp)'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        setSt(() => busy = true);
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
                        try {
                          await vault.putProfile(updated);
                        } catch (e) {
                          setSt(() => busy = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Could not save your profile: ${friendlyError(e)}')));
                          }
                          return;
                        }
                        // Best-effort server sync — offline-first: the local save above
                        // already succeeded, so a sync failure here is not shown as an error.
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
                child: Text(busy ? 'Saving…' : 'Save profile'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
    );
  } finally {
    name.dispose();
    enrol.dispose();
    bar.dispose();
    chamber.dispose();
    phone.dispose();
  }
}

Future<void> showReferencesSheet(BuildContext context, WidgetRef ref, String caseId) async {
  final vault = ref.read(vaultStoreProvider);
  final c = vault.getCase(caseId);
  if (c == null) return;
  final ctrl = TextEditingController(text: c.references);
  var busy = false;
  try {
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
            Text('Statutes & case references', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Sections, citations, points to argue — encrypted on this device.', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              enabled: !busy,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'e.g. S. 138 NI Act; Sec 482 CrPC; Priya Sharma v. State…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setSt(() => busy = true);
                      final text = ctrl.text.trim();
                      try {
                        await vault.updateReferences(caseId, text);
                        if (text.isNotEmpty) {
                          await vault.addEvent(
                            caseId,
                            CaseUpdate(date: todayIso, side: 'lawyer', kind: 'reference', time: 'Now', text: 'References updated', sub: text.length > 100 ? '${text.substring(0, 100)}…' : text),
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setSt(() => busy = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Could not save these references: ${friendlyError(e)}')));
                        }
                      }
                    },
              child: Text(busy ? 'Saving…' : 'Save references'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
    );
  } finally {
    ctrl.dispose();
  }
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

/// Shared by both document sheets below: opens the OS file picker with
/// bytes loaded into memory (`withData: true` — works on mobile and web,
/// unlike relying on [PlatformFile.path] which is null on web).
Future<PlatformFile?> _pickDocumentFile() async {
  final result = await FilePicker.platform.pickFiles(withData: true);
  return result?.files.single;
}

Future<void> showAddDocToCaseSheet(BuildContext context, WidgetRef ref, String caseId) async {
  final nameCtrl = TextEditingController();
  PlatformFile? picked;
  String? error;
  var busy = false;

  try {
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
            Text('Add document', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(picked == null ? 'Choose file' : 'Change file'),
              onPressed: () async {
                final file = await _pickDocumentFile();
                if (file == null) return;
                setSt(() {
                  picked = file;
                  error = null;
                  if (nameCtrl.text.trim().isEmpty) nameCtrl.text = file.name;
                });
              },
            ),
            if (picked != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${picked!.name} · ${(picked!.size / 1024).round()} KB', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Document name')),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final n = nameCtrl.text.trim();
                      final file = picked;
                      if (file == null) {
                        setSt(() => error = 'Choose a file first');
                        return;
                      }
                      if (n.isEmpty) {
                        setSt(() => error = 'Document name is required');
                        return;
                      }
                      final bytes = file.bytes;
                      if (bytes == null) {
                        setSt(() => error = 'Could not read that file — try again');
                        return;
                      }
                      setSt(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await ref.read(vaultStoreProvider).addDocumentFile(
                              caseId,
                              name: n,
                              bytes: bytes,
                              pdf: file.name.toLowerCase().endsWith('.pdf'),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setSt(() {
                          busy = false;
                          error = 'Could not save this document: ${friendlyError(e)}';
                        });
                      }
                    },
              child: Text(busy ? 'Saving…' : 'Add to case file'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
    );
  } finally {
    nameCtrl.dispose();
  }
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
  PlatformFile? picked;
  String? error;
  var busy = false;

  try {
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
            Text('Upload document', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: caseId,
              items: [for (final c in cases) DropdownMenuItem(value: c.id, child: Text(c.parties, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setSt(() => caseId = v ?? caseId),
              decoration: const InputDecoration(labelText: 'Case'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(picked == null ? 'Choose file' : 'Change file'),
              onPressed: () async {
                final file = await _pickDocumentFile();
                if (file == null) return;
                setSt(() {
                  picked = file;
                  error = null;
                  if (nameCtrl.text.trim().isEmpty) nameCtrl.text = file.name;
                });
              },
            ),
            if (picked != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${picked!.name} · ${(picked!.size / 1024).round()} KB', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'File name')),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final n = nameCtrl.text.trim();
                      final file = picked;
                      if (file == null) {
                        setSt(() => error = 'Choose a file first');
                        return;
                      }
                      if (n.isEmpty) {
                        setSt(() => error = 'File name is required');
                        return;
                      }
                      final bytes = file.bytes;
                      if (bytes == null) {
                        setSt(() => error = 'Could not read that file — try again');
                        return;
                      }
                      setSt(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await vault.addDocumentFile(
                          caseId,
                          name: n,
                          bytes: bytes,
                          pdf: file.name.toLowerCase().endsWith('.pdf'),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setSt(() {
                          busy = false;
                          error = 'Could not save this document: ${friendlyError(e)}';
                        });
                      }
                    },
              child: Text(busy ? 'Saving…' : 'Upload'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
    );
  } finally {
    nameCtrl.dispose();
  }
}
