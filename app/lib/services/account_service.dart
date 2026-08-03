/// Account profile on Supabase — `/api/me` + PATCH `/api/me/profile`.
library;

import 'court_lookup_service.dart';

class AccountProfile {
  AccountProfile({
    this.displayName = '',
    this.enrolment = '',
    this.barCouncil = '',
    this.chamber = '',
    this.phone = '',
    this.plan = 'free',
  });

  final String displayName;
  final String enrolment;
  final String barCouncil;
  final String chamber;
  final String phone;
  final String plan;

  factory AccountProfile.fromJson(Map<String, dynamic> j) => AccountProfile(
        displayName: j['display_name'] as String? ?? '',
        enrolment: j['enrolment'] as String? ?? '',
        barCouncil: j['bar_council'] as String? ?? '',
        chamber: j['chamber'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        plan: j['plan'] as String? ?? 'free',
      );
}

Future<AccountProfile> fetchAccountProfile(ApiClient api) async {
  final j = await api.get('/me');
  return AccountProfile.fromJson(j);
}

Future<void> patchAccountProfile(
  ApiClient api, {
  String? displayName,
  String? enrolment,
  String? barCouncil,
  String? chamber,
  String? phone,
}) async {
  await api.patch('/me/profile', {
    if (displayName != null) 'display_name': displayName,
    if (enrolment != null) 'enrolment': enrolment,
    if (barCouncil != null) 'bar_council': barCouncil,
    if (chamber != null) 'chamber': chamber,
    if (phone != null) 'phone': phone,
  });
}

/// Permanently deletes the signed-in user's auth account + chamber profile.
/// Case data is device-only and untouched — see DELETE /api/me.
Future<void> deleteAccount(ApiClient api) async {
  await api.delete('/me');
}
