import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:munshi_mobile/crypto/vault_crypto.dart';

void main() {
  test('AES-GCM envelope matches vault.js wire shape', () async {
    const password = 'test-password-123';
    final salt = Uint8List.fromList(List.generate(16, (i) => i + 1));
    final wrapKey = await VaultCrypto.deriveWrappingKey(password, salt);
    final dataKey = await VaultCrypto.generateDataKey();
    final wrapped = await VaultCrypto.wrapDataKey(dataKey, wrapKey);
    expect(wrapped.toJson()['iv'], isNotEmpty);
    expect(wrapped.toJson()['data'], isNotEmpty);

    final unwrapped = await VaultCrypto.unwrapDataKey(wrapped, wrapKey);
    final payload = {'parties': 'A vs B', 'caseNo': '1/2026'};
    final env = await VaultCrypto.encryptJson(payload, unwrapped);
    final back = await VaultCrypto.decryptJson(env, unwrapped);
    expect(back['caseNo'], '1/2026');

    // Stable JSON keys for backup interop
    expect(jsonEncode(env.toJson()).contains('"iv"'), isTrue);
  });
}
