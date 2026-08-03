/// `backup_import.dart` is the entire "restore on a new phone" path — a bug
/// here means a lawyer's only copy of their case data (zero-knowledge: there
/// is no server-side copy) becomes unreadable. It had zero test coverage
/// before this file. These tests build a synthetic `munshi-vault-backup-v1`
/// file using the real crypto primitives (no mocking) and exercise the same
/// unwrap-then-decrypt pipeline `VaultStore.importAndUnlockBackup` calls.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:munshi_mobile/crypto/backup_import.dart';
import 'package:munshi_mobile/crypto/vault_crypto.dart';

/// Builds a real, self-consistent backup file: derives password + recovery
/// wrapping keys from the same salt (exactly like VaultSession.initOnSignup),
/// wraps one data key under both, and encrypts one case payload with it.
Future<Map<String, dynamic>> _buildSyntheticBackup({
  required String password,
  required String recoveryKeyHex,
  required Map<String, dynamic> casePayload,
}) async {
  final salt = Uint8List.fromList(List.generate(16, (i) => i + 1));
  final pwKey = await VaultCrypto.deriveWrappingKey(password, salt);
  final recKey = await VaultCrypto.deriveWrappingKey(recoveryKeyHex, salt);
  final dataKey = await VaultCrypto.generateDataKey();
  final wrappedPw = await VaultCrypto.wrapDataKey(dataKey, pwKey);
  final wrappedRec = await VaultCrypto.wrapDataKey(dataKey, recKey);
  final blob = await VaultCrypto.encryptJson(casePayload, dataKey);

  return {
    'format': PwaBackup.expectedFormat,
    'tables': {
      'meta': [
        {'key': 'salt', 'value': base64Encode(salt)},
        {'key': 'wrappedKey', 'value': wrappedPw.toJson()},
        {'key': 'wrappedKeyRecovery', 'value': wrappedRec.toJson()},
      ],
      'cases': [
        {'id': 'case-1', 'caseNumber': 'A/123', 'encryptedBlob': blob.toJson()},
      ],
      'hearings': [],
      'documents': [],
    },
  };
}

void main() {
  group('PwaBackup.parse', () {
    test('accepts the expected format', () {
      final backup = PwaBackup.parse({
        'format': 'munshi-vault-backup-v1',
        'tables': {'meta': [], 'cases': []},
      });
      expect(backup.metaRows, isEmpty);
      expect(backup.caseRows, isEmpty);
    });

    test('rejects an unrecognized format with a clear message', () {
      expect(
        () => PwaBackup.parse({'format': 'some-other-format', 'tables': {}}),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Unrecognized backup format'),
        )),
      );
    });
  });

  group('unwrapDataKeyFromBackup + decryptAllCases (full restore pipeline)', () {
    const password = 'correct horse battery staple';
    const recoveryKeyHex = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd';
    final casePayload = {'parties': 'Restored vs Backup', 'caseNo': 'A/123', 'fee': {'agreed': 25000}};

    test('unwraps with the correct password and decrypts the case', () async {
      final json = await _buildSyntheticBackup(
        password: password,
        recoveryKeyHex: recoveryKeyHex,
        casePayload: casePayload,
      );
      final backup = PwaBackup.parse(json);

      final dataKey = await unwrapDataKeyFromBackup(
        backup: backup,
        passwordOrRecoveryKey: password,
        isRecoveryKey: false,
      );
      final cases = await decryptAllCases(backup, dataKey);

      expect(cases, hasLength(1));
      expect(cases.single.id, 'case-1');
      expect(cases.single.caseNumber, 'A/123');
      expect(cases.single.decryptedPayload['parties'], 'Restored vs Backup');
      expect((cases.single.decryptedPayload['fee'] as Map)['agreed'], 25000);
    });

    test('unwraps with the recovery key when the password is unknown', () async {
      final json = await _buildSyntheticBackup(
        password: password,
        recoveryKeyHex: recoveryKeyHex,
        casePayload: casePayload,
      );
      final backup = PwaBackup.parse(json);

      final dataKey = await unwrapDataKeyFromBackup(
        backup: backup,
        passwordOrRecoveryKey: recoveryKeyHex,
        isRecoveryKey: true,
      );
      final cases = await decryptAllCases(backup, dataKey);

      expect(cases.single.decryptedPayload['parties'], 'Restored vs Backup');
    });

    test('a wrong password fails to unwrap instead of silently returning garbage', () async {
      final json = await _buildSyntheticBackup(
        password: password,
        recoveryKeyHex: recoveryKeyHex,
        casePayload: casePayload,
      );
      final backup = PwaBackup.parse(json);

      expect(
        () => unwrapDataKeyFromBackup(
          backup: backup,
          passwordOrRecoveryKey: 'the wrong password entirely',
          isRecoveryKey: false,
        ),
        throwsA(anything),
      );
    });

    test('a wrong recovery key fails to unwrap', () async {
      final json = await _buildSyntheticBackup(
        password: password,
        recoveryKeyHex: recoveryKeyHex,
        casePayload: casePayload,
      );
      final backup = PwaBackup.parse(json);

      expect(
        () => unwrapDataKeyFromBackup(
          backup: backup,
          passwordOrRecoveryKey: 'f' * 64,
          isRecoveryKey: true,
        ),
        throwsA(anything),
      );
    });

    test('missing salt/wrappedKey in meta throws FormatException', () {
      final backup = PwaBackup.parse({
        'format': 'munshi-vault-backup-v1',
        'tables': {
          'meta': [
            {'key': 'salt', 'value': base64Encode(Uint8List(16))},
            // wrappedKey deliberately omitted
          ],
          'cases': [],
        },
      });

      expect(
        () => unwrapDataKeyFromBackup(backup: backup, passwordOrRecoveryKey: 'x', isRecoveryKey: false),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
