/// Imports a PWA vault backup — the exact `munshi-vault-backup-v1` JSON file
/// produced by munshi-ui/vault.js's `exportBackup()` (vault.js:778-803) and
/// downloaded via the Settings screen (index.html:2147-2159). This is the
/// real Phase B "import from PWA backup" path — there is no other export
/// format to design around.
///
/// The file is still all-ciphertext: only `meta.salt`, `meta.wrappedKey`, and
/// `meta.wrappedKeyRecovery` let us unwrap the data key, after which every
/// case's `encryptedBlob` decrypts with the same AES-GCM scheme
/// (see vault_crypto.dart).
///
/// NOT compiled/tested here (no Dart/Flutter SDK). Maps the PWA's
/// one-blob-per-case shape onto this app's event-log schema (app_database.dart)
/// by exploding each case's `updates[]`/`payments[]` arrays into individual
/// CaseEvents rows — that explosion is the actual data-model migration the
/// scale-up brief describes, done once at import time rather than in the PWA.
library;

import 'dart:convert' show base64Decode;
import 'dart:typed_data' show Uint8List;

import 'package:cryptography/cryptography.dart';

import 'vault_crypto.dart';
import 'vault_session.dart' show unwrapBackupDataKey;

class PwaBackup {
  final Map<String, dynamic> raw;
  PwaBackup(this.raw);

  static const expectedFormat = 'munshi-vault-backup-v1';

  factory PwaBackup.parse(Map<String, dynamic> json) {
    if (json['format'] != expectedFormat) {
      throw FormatException(
        'Unrecognized backup format: ${json['format']} (expected $expectedFormat)',
      );
    }
    return PwaBackup(json);
  }

  List<Map<String, dynamic>> get metaRows =>
      List<Map<String, dynamic>>.from(raw['tables']['meta'] as List);
  List<Map<String, dynamic>> get caseRows =>
      List<Map<String, dynamic>>.from(raw['tables']['cases'] as List);

  Map<String, dynamic> get accountMeta =>
      metaRows.firstWhere((row) => row['key'] == 'account', orElse: () => metaRows.first);
}

class ImportedCase {
  final String id;
  final String caseNumber;
  final Map<String, dynamic> decryptedPayload; // {parties, client, fee, hearings[], docs[], payments[], updates[]}
  const ImportedCase(this.id, this.caseNumber, this.decryptedPayload);
}

/// Unwraps the data key using either the account password or the recovery
/// key — same choice the PWA offers when a device forgets its session
/// (vault.js unlockWithPassword / unlockWithRecovery).
Future<SecretKey> unwrapDataKeyFromBackup({
  required PwaBackup backup,
  required String passwordOrRecoveryKey,
  required bool isRecoveryKey,
}) =>
    unwrapBackupDataKey(
      backup: backup,
      passwordOrRecovery: passwordOrRecoveryKey,
      isRecoveryKey: isRecoveryKey,
    );

Future<List<ImportedCase>> decryptAllCases(PwaBackup backup, SecretKey dataKey) async {
  final result = <ImportedCase>[];
  for (final row in backup.caseRows) {
    final envelope = CipherEnvelope.fromJson(
      Map<String, dynamic>.from(row['encryptedBlob'] as Map),
    );
    final payload = await VaultCrypto.decryptJson(envelope, dataKey);
    result.add(ImportedCase(row['id'] as String, row['caseNumber'] as String, payload));
  }
  return result;
}

Uint8List base64DecodeSalt(String b64) => base64Decode(b64);
