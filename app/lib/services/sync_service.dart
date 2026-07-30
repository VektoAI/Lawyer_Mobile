/// Client for mobile/backend's ciphertext relay (POST /sync/push,
/// GET /sync/pull). This app never sends plaintext here — `encPayload` is
/// already the output of VaultCrypto.encryptJson (CLAUDE.md invariant 9).
///
/// NOT compiled/tested in this environment. `baseUrl` currently points at the
/// local dev backend (mobile/backend/README.md); swap for the deployed
/// origin when Phase C ships.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class PendingEvent {
  final String eventId;
  final String dedupKey;
  final String encPayload;
  final DateTime createdAt;
  const PendingEvent({
    required this.eventId,
    required this.dedupKey,
    required this.encPayload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'dedup_key': dedupKey,
        'enc_payload': encPayload,
        'created_at': createdAt.toIso8601String(),
      };

  /// dedup_key = deterministic hash of the event id — retrying a push with
  /// the same event is always a no-op server-side (invariant 2).
  factory PendingEvent.create({required String encPayload}) {
    final id = const Uuid().v4();
    return PendingEvent(
      eventId: id,
      dedupKey: id, // event_id is already client-generated + unique; reuse it
      encPayload: encPayload,
      createdAt: DateTime.now().toUtc(),
    );
  }
}

class SyncPushResult {
  final int accepted;
  final int duplicates;
  const SyncPushResult(this.accepted, this.duplicates);
}

class SyncPulledEvent {
  final int seq;
  final String eventId;
  final String encPayload;
  const SyncPulledEvent(this.seq, this.eventId, this.encPayload);
}

class SyncService {
  final Uri baseUrl;
  final String chamberId;
  final String deviceId;

  const SyncService({
    required this.baseUrl,
    required this.chamberId,
    required this.deviceId,
  });

  Future<SyncPushResult> push(List<PendingEvent> events) async {
    final response = await http.post(
      baseUrl.resolve('/sync/push'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chamber_id': chamberId,
        'device_id': deviceId,
        'events': events.map((e) => e.toJson()).toList(),
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return SyncPushResult(body['accepted'] as int, body['duplicates'] as int);
  }

  /// Pulls events with seq > [sinceSeq] — the client's last_seen_seq cursor,
  /// per ARCHITECTURE.md §7's sync protocol.
  Future<(List<SyncPulledEvent>, int)> pull(int sinceSeq) async {
    final uri = baseUrl.resolve('/sync/pull').replace(queryParameters: {
      'chamber_id': chamberId,
      'since': '$sinceSeq',
    });
    final response = await http.get(uri);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final events = (body['events'] as List)
        .map((e) => SyncPulledEvent(e['seq'] as int, e['event_id'] as String, e['enc_payload'] as String))
        .toList();
    return (events, body['latest_seq'] as int);
  }
}
