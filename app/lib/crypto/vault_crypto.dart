/// Mirrors munshi-ui/vault.js's crypto scheme exactly — same KDF, same
/// iteration count, same cipher, same envelope-encryption shape for the data
/// key. This is a deliberate consistency choice, not the scale-up brief's
/// looser "Argon2id/PBKDF2" wording: switching KDFs would break compatibility
/// with the existing recovery-key model and the `munshi-vault-backup-v1`
/// export format (vault.js:778-822) that Phase B's "import from PWA backup"
/// depends on.
///
/// Reference constants (vault.js:8, 35-47, 57-68, 70-99, 105-108):
///   PBKDF2-SHA256, 250,000 iterations, 16-byte random salt -> AES-GCM-256
///   wrapping key. A separate random AES-GCM-256 "data key" is generated once
///   per account and wrapped (envelope-encrypted) under the wrapping key —
///   once for the password, once independently for the recovery key, same
///   salt for both. Bulk cipher: AES-GCM-256, random 12-byte IV per op,
///   {iv, data} base64 JSON packets.
///
/// NOT compiled/tested in this environment (no Dart/Flutter SDK) — verify
/// with `flutter test` once installed, ideally with a cross-check against a
/// vault.js-produced envelope to confirm the encodings actually interop.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

const int pbkdf2Iterations = 250000; // must match vault.js's PBKDF2_ITERS exactly
const int saltLengthBytes = 16;
const int gcmIvLengthBytes = 12;
const int keyLengthBits = 256;

final _random = Random.secure();

Uint8List randomBytes(int length) {
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = _random.nextInt(256);
  }
  return bytes;
}

/// A ciphertext envelope, wire-compatible with vault.js's `{iv, data}` shape.
class CipherEnvelope {
  final Uint8List iv;
  final Uint8List data;
  const CipherEnvelope(this.iv, this.data);

  Map<String, String> toJson() => {
        'iv': base64Encode(iv),
        'data': base64Encode(data),
      };

  static CipherEnvelope fromJson(Map<String, dynamic> json) => CipherEnvelope(
        base64Decode(json['iv'] as String),
        base64Decode(json['data'] as String),
      );
}

class VaultCrypto {
  static final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: pbkdf2Iterations,
    bits: keyLengthBits,
  );
  static final _aesGcm = AesGcm.with256bits();

  /// PBKDF2-SHA256(password, salt, 250_000) -> AES-GCM-256 wrapping key.
  /// Called with the account password OR the recovery key — same derivation,
  /// same salt, exactly like `deriveKey()` in vault.js.
  static Future<SecretKey> deriveWrappingKey(String secret, Uint8List salt) {
    return _pbkdf2.deriveKeyFromPassword(password: secret, nonce: salt);
  }

  static Future<SecretKey> generateDataKey() => _aesGcm.newSecretKey();

  /// 256-bit random value, shown to the lawyer once as 64 hex chars —
  /// "Bitwarden-style" recovery key (vault.js:105-108). Losing both the
  /// password and this key is unrecoverable by design; there is no
  /// server-side escrow.
  static String generateRecoveryKeyHex() => hex.encode(randomBytes(32));

  static Future<CipherEnvelope> wrapDataKey(SecretKey dataKey, SecretKey wrappingKey) async {
    final raw = await dataKey.extractBytes();
    return _encryptBytes(Uint8List.fromList(raw), wrappingKey);
  }

  static Future<SecretKey> unwrapDataKey(CipherEnvelope envelope, SecretKey wrappingKey) async {
    final raw = await _decryptBytes(envelope, wrappingKey);
    return SecretKey(raw);
  }

  static Future<CipherEnvelope> encryptJson(Map<String, dynamic> value, SecretKey dataKey) {
    return _encryptBytes(Uint8List.fromList(utf8.encode(jsonEncode(value))), dataKey);
  }

  static Future<Map<String, dynamic>> decryptJson(CipherEnvelope envelope, SecretKey dataKey) async {
    final bytes = await _decryptBytes(envelope, dataKey);
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  static Future<CipherEnvelope> _encryptBytes(Uint8List plaintext, SecretKey key) async {
    final iv = randomBytes(gcmIvLengthBytes);
    final box = await _aesGcm.encrypt(plaintext, secretKey: key, nonce: iv);
    // vault.js concatenates ciphertext+tag into one `data` field — match that.
    return CipherEnvelope(iv, Uint8List.fromList(box.cipherText + box.mac.bytes));
  }

  static Future<Uint8List> _decryptBytes(CipherEnvelope envelope, SecretKey key) async {
    const macLength = 16; // AES-GCM tag length in bytes
    final cipherText = envelope.data.sublist(0, envelope.data.length - macLength);
    final mac = Mac(envelope.data.sublist(envelope.data.length - macLength));
    final box = SecretBox(cipherText, nonce: envelope.iv, mac: mac);
    final clear = await _aesGcm.decrypt(box, secretKey: key);
    return Uint8List.fromList(clear);
  }
}

/// Minimal hex codec so this file has no extra dependency beyond `cryptography`.
class hex {
  static String encode(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
