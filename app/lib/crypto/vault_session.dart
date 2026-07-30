library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'backup_import.dart';
import 'vault_crypto.dart';

class VaultInitResult {
  const VaultInitResult({
    required this.recoveryKeyHex,
    required this.wrappedKey,
    required this.wrappedKeyRecovery,
  });
  final String recoveryKeyHex;
  final CipherEnvelope wrappedKey;
  final CipherEnvelope wrappedKeyRecovery;
}

/// Crypto + meta operations aligned with munshi-ui/vault.js.
class VaultSession {
  SecretKey? _dataKey;
  String? userId;
  String? email;
  String? saltB64;

  bool get isUnlocked => _dataKey != null;

  Future<VaultInitResult> initOnSignup({
    required String userId,
    required String email,
    required String password,
    required String saltB64,
  }) async {
    final salt = base64Decode(saltB64);
    final pwKey = await VaultCrypto.deriveWrappingKey(password, salt);
    final dataKey = await VaultCrypto.generateDataKey();
    final recoveryHex = VaultCrypto.generateRecoveryKeyHex();
    final recKey = await VaultCrypto.deriveWrappingKey(recoveryHex, salt);

    final wrappedPw = await VaultCrypto.wrapDataKey(dataKey, pwKey);
    final wrappedRec = await VaultCrypto.wrapDataKey(dataKey, recKey);

    _dataKey = dataKey;
    this.userId = userId;
    this.email = email;
    this.saltB64 = saltB64;

    return VaultInitResult(
      recoveryKeyHex: recoveryHex,
      wrappedKey: wrappedPw,
      wrappedKeyRecovery: wrappedRec,
    );
  }

  Future<void> unlockWithPassword(String password, VaultMeta meta) async {
    if (meta.saltB64 == null || meta.wrappedKey == null) {
      throw StateError('No vault on this device — create an account first');
    }
    final salt = base64Decode(meta.saltB64!);
    try {
      final pwKey = await VaultCrypto.deriveWrappingKey(password, salt);
      _dataKey = await VaultCrypto.unwrapDataKey(meta.wrappedKey!, pwKey);
    } catch (_) {
      throw StateError('Wrong password for cases saved on this device');
    }
    userId = meta.userId;
    email = meta.email;
    saltB64 = meta.saltB64;
  }

  Future<void> unlockWithRecovery(String recoveryKey, VaultMeta meta) async {
    if (meta.saltB64 == null || meta.wrappedKeyRecovery == null) {
      throw StateError('No recovery key on this device');
    }
    final salt = base64Decode(meta.saltB64!);
    final recKey = await VaultCrypto.deriveWrappingKey(recoveryKey.trim(), salt);
    _dataKey = await VaultCrypto.unwrapDataKey(meta.wrappedKeyRecovery!, recKey);
    userId = meta.userId;
    email = meta.email;
    saltB64 = meta.saltB64;
  }

  void adoptUnlockedKey(SecretKey key, {required String uid, String? mail, String? salt}) {
    _dataKey = key;
    userId = uid;
    email = mail;
    saltB64 = salt;
  }

  void lock() {
    _dataKey = null;
  }

  SecretKey requireKey() {
    final k = _dataKey;
    if (k == null) throw StateError('Vault locked');
    return k;
  }

  Future<CipherEnvelope> encryptCasePayload(Map<String, dynamic> payload) {
    return VaultCrypto.encryptJson(payload, requireKey());
  }

  Future<Map<String, dynamic>> decryptCasePayload(CipherEnvelope envelope) {
    return VaultCrypto.decryptJson(envelope, requireKey());
  }

  Future<CipherEnvelope> encryptProfile(Map<String, dynamic> profile) {
    return VaultCrypto.encryptJson(profile, requireKey());
  }

  Future<Map<String, dynamic>> decryptProfile(CipherEnvelope envelope) {
    return VaultCrypto.decryptJson(envelope, requireKey());
  }

  VaultMeta buildMetaForPersist({
    required CipherEnvelope wrappedKey,
    required CipherEnvelope wrappedKeyRecovery,
    Map<String, dynamic>? extraMeta,
  }) {
    return VaultMeta(
      userId: userId,
      email: email,
      saltB64: saltB64,
      wrappedKey: wrappedKey,
      wrappedKeyRecovery: wrappedKeyRecovery,
      extra: extraMeta ?? {},
    );
  }
}

/// Meta fields stored like Dexie `meta` table (+ wrapped keys from init).
class VaultMeta {
  VaultMeta({
    this.userId,
    this.email,
    this.saltB64,
    this.wrappedKey,
    this.wrappedKeyRecovery,
    this.profileEnvelope,
    this.extra = const {},
  });

  String? userId;
  String? email;
  String? saltB64;
  CipherEnvelope? wrappedKey;
  CipherEnvelope? wrappedKeyRecovery;
  CipherEnvelope? profileEnvelope;
  Map<String, dynamic> extra;

  bool get hasVault => saltB64 != null && wrappedKey != null;

  List<Map<String, dynamic>> toMetaRows() {
    final rows = <Map<String, dynamic>>[];
    void put(String key, dynamic value) => rows.add({'key': key, 'value': value});

    if (userId != null) put('userId', userId);
    if (email != null) put('email', email);
    if (saltB64 != null) put('salt', saltB64);
    if (wrappedKey != null) put('wrappedKey', wrappedKey!.toJson());
    if (wrappedKeyRecovery != null) put('wrappedKeyRecovery', wrappedKeyRecovery!.toJson());
    if (profileEnvelope != null) put('profile', profileEnvelope!.toJson());
    for (final e in extra.entries) {
      put(e.key, e.value);
    }
    return rows;
  }

  static VaultMeta fromMetaRows(List<Map<String, dynamic>> rows) {
    final meta = VaultMeta();
    for (final row in rows) {
      final key = row['key'] as String?;
      final value = row['value'];
      if (key == null) continue;
      switch (key) {
        case 'userId':
          meta.userId = value as String?;
        case 'email':
          meta.email = value as String?;
        case 'salt':
          meta.saltB64 = value as String?;
        case 'wrappedKey':
          meta.wrappedKey = CipherEnvelope.fromJson(Map<String, dynamic>.from(value as Map));
        case 'wrappedKeyRecovery':
          meta.wrappedKeyRecovery = CipherEnvelope.fromJson(Map<String, dynamic>.from(value as Map));
        case 'profile':
          meta.profileEnvelope = CipherEnvelope.fromJson(Map<String, dynamic>.from(value as Map));
        default:
          meta.extra[key] = value;
      }
    }
    return meta;
  }
}

Future<SecretKey> unwrapBackupDataKey({
  required PwaBackup backup,
  required String passwordOrRecovery,
  required bool isRecoveryKey,
}) {
  dynamic metaValue(String key) {
    for (final row in backup.metaRows) {
      if (row['key'] == key) return row['value'];
    }
    return null;
  }

  final saltB64 = metaValue('salt') as String?;
  final field = isRecoveryKey ? 'wrappedKeyRecovery' : 'wrappedKey';
  final wrapped = metaValue(field);
  if (saltB64 == null || wrapped == null) {
    throw FormatException('Backup missing salt or $field');
  }
  final salt = Uint8List.fromList(base64Decode(saltB64));
  return VaultCrypto.deriveWrappingKey(passwordOrRecovery, salt).then((wrapKey) async {
    final env = CipherEnvelope.fromJson(Map<String, dynamic>.from(wrapped as Map));
    return VaultCrypto.unwrapDataKey(env, wrapKey);
  });
}

Future<bool> vaultSelfTest() async {
  try {
    final salt = randomBytes(16);
    const password = 'self-test-password';
    final pwKey = await VaultCrypto.deriveWrappingKey(password, salt);
    final dataKey = await VaultCrypto.generateDataKey();
    final wrapped = await VaultCrypto.wrapDataKey(dataKey, pwKey);
    final unwrapped = await VaultCrypto.unwrapDataKey(wrapped, pwKey);
    final sample = await VaultCrypto.encryptJson({'ok': true}, unwrapped);
    final back = await VaultCrypto.decryptJson(sample, unwrapped);
    return back['ok'] == true;
  } catch (_) {
    return false;
  }
}
