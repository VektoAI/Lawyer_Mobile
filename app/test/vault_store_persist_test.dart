/// Regression test for VaultStore's Phase 3 incremental-persist optimization
/// (see data/vault_store.dart's `_encryptedRowCache`/`_dirtyCaseIds`): editing
/// one case must never lose or corrupt another case's data, and a fresh
/// VaultStore reloading the same on-disk file must see exactly what was last
/// written — the whole point of this test is to catch a dirty-tracking bug
/// that would otherwise show up only as silent data loss on a real device.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munshi_mobile/data/vault_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.dir);
  final Directory dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Map<String, String> secureStorageBackingMap;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('munshi_vault_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);

    secureStorageBackingMap = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall call) async {
        switch (call.method) {
          case 'read':
            return secureStorageBackingMap[call.arguments['key']];
          case 'write':
            secureStorageBackingMap[call.arguments['key'] as String] = call.arguments['value'] as String;
            return null;
          case 'delete':
            secureStorageBackingMap.remove(call.arguments['key']);
            return null;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('editing one case does not lose or corrupt other cases after reload', () async {
    final store = VaultStore();
    await store.initNewVault(uid: 'u1', email: 'a@b.com', password: 'pw', saltB64: 'AAAAAAAAAAAAAAAAAAAAAA==');

    final caseA = await store.upsertCase(court: 'Court A', caseNo: 'A/1', parties: 'Alice vs Bob');
    final caseB = await store.upsertCase(court: 'Court B', caseNo: 'B/1', parties: 'Carol vs Dave');
    final caseC = await store.upsertCase(court: 'Court C', caseNo: 'C/1', parties: 'Eve vs Frank');

    // Only touch case B — A and C's cached encrypted rows should be reused
    // as-is (see _persistEncrypted), never re-derived from scratch.
    await store.togglePin(caseB.id);
    await store.addNote(caseB.id, 'a note only on B');

    // Simulate an app restart: fresh VaultStore instance, load from disk,
    // unlock with the same password — must not depend on any in-memory
    // cache from the `store` instance above.
    final reloaded = VaultStore();
    await reloaded.loadFromDisk();
    await reloaded.unlockWithPassword('pw');

    final reloadedA = reloaded.getCase(caseA.id);
    final reloadedB = reloaded.getCase(caseB.id);
    final reloadedC = reloaded.getCase(caseC.id);

    expect(reloadedA, isNotNull);
    expect(reloadedA!.parties, 'Alice vs Bob');
    expect(reloadedA.caseNo, 'A/1');
    expect(reloadedA.pinned, isFalse);

    expect(reloadedC, isNotNull);
    expect(reloadedC!.parties, 'Eve vs Frank');
    expect(reloadedC.caseNo, 'C/1');

    expect(reloadedB, isNotNull);
    expect(reloadedB!.pinned, isTrue);
    expect(reloadedB.updates.any((u) => u.text == 'a note only on B'), isTrue);
  });

  test('deleting a case removes it and leaves others intact after reload', () async {
    final store = VaultStore();
    await store.initNewVault(uid: 'u2', email: 'c@d.com', password: 'pw2', saltB64: 'AAAAAAAAAAAAAAAAAAAAAA==');

    final caseA = await store.upsertCase(court: 'Court A', caseNo: 'A/1', parties: 'Alice vs Bob');
    final caseB = await store.upsertCase(court: 'Court B', caseNo: 'B/1', parties: 'Carol vs Dave');

    await store.deleteCase(caseA.id);
    await store.addPayment(caseB.id, amount: 5000, mode: 'UPI', note: 'part payment', date: '2026-01-01');

    final reloaded = VaultStore();
    await reloaded.loadFromDisk();
    await reloaded.unlockWithPassword('pw2');

    expect(reloaded.getCase(caseA.id), isNull);
    final reloadedB = reloaded.getCase(caseB.id);
    expect(reloadedB, isNotNull);
    expect(reloadedB!.payments.single.amount, 5000);
  });

  test('a stored document decrypts back to its exact original bytes after reload', () async {
    final store = VaultStore();
    await store.initNewVault(uid: 'u3', email: 'e@f.com', password: 'pw3', saltB64: 'AAAAAAAAAAAAAAAAAAAAAA==');
    final theCase = await store.upsertCase(court: 'Court A', caseNo: 'A/1', parties: 'Alice vs Bob');

    final originalBytes = Uint8List.fromList(List.generate(256, (i) => i % 256));
    final doc = await store.addDocumentFile(theCase.id, name: 'evidence.pdf', bytes: originalBytes, pdf: true);

    // Simulate an app restart before the document is ever opened.
    final reloaded = VaultStore();
    await reloaded.loadFromDisk();
    await reloaded.unlockWithPassword('pw3');

    final reloadedCase = reloaded.getCase(theCase.id);
    expect(reloadedCase, isNotNull);
    final reloadedDoc = reloadedCase!.docs.singleWhere((d) => d.id == doc.id);
    expect(reloadedDoc.name, 'evidence.pdf');

    final decrypted = await reloaded.decryptDocumentBytes(reloadedDoc);
    expect(decrypted, originalBytes);
  });
}
