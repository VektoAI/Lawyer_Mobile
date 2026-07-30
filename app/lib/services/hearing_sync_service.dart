library;

import '../data/courts.dart';
import '../data/vault_store.dart';
import '../models/case_models.dart';
import 'account_service.dart';
import 'auth_service.dart';
import 'court_lookup_service.dart';

/// Pull next-hearing hints from live cause lists into the encrypted vault.
Future<int> autoSyncCourtHearings(VaultStore vault, {bool demoSkip = true}) async {
  if (!vault.isUnlocked || (demoSkip && vault.isDemo)) return 0;
  final auth = AuthService();
  if (!await auth.hasToken()) return 0;

  final api = ApiClient();
  final payload = <Map<String, dynamic>>[];
  for (final c in vault.listCases()) {
    final cid = courtIdForName(c.court);
    if (cid == null || c.caseNo.isEmpty) continue;
    payload.add({'client_case_id': c.id, 'court_id': cid, 'case_no': c.caseNo});
  }
  final advocate = vault.profile.name;
  if (payload.isEmpty && advocate.isEmpty) return 0;

  try {
    final r = await syncCourtHearings(
      api: api,
      cases: payload,
      advocateName: advocate.isNotEmpty ? advocate : null,
      scanCourtIds: const [7, 1],
    );
    final updates = r['updates'] as List<dynamic>? ?? [];
    return vault.applyCourtHearingSync(updates);
  } catch (_) {
    return 0;
  }
}

Future<void> mergeAccountProfileIntoVault(VaultStore vault) async {
  if (!vault.isUnlocked || vault.isDemo) return;
  if (!await AuthService().hasToken()) return;
  try {
    final remote = await fetchAccountProfile(ApiClient());
    final local = vault.profile;
    final name = local.name.isNotEmpty ? local.name : remote.displayName;
    final merged = ChamberProfile(
      name: name,
      enrolment: local.enrolment.isNotEmpty ? local.enrolment : remote.enrolment,
      barCouncil: local.barCouncil.isNotEmpty ? local.barCouncil : remote.barCouncil,
      chamber: local.chamber.isNotEmpty ? local.chamber : remote.chamber,
      phone: local.phone.isNotEmpty ? local.phone : remote.phone,
      initials: local.initials.isNotEmpty
          ? local.initials
          : name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase(),
    );
    if (merged.name != local.name ||
        merged.phone != local.phone ||
        merged.enrolment != local.enrolment ||
        merged.barCouncil != local.barCouncil ||
        merged.chamber != local.chamber) {
      await vault.putProfile(merged);
    }
  } catch (_) {}
}
