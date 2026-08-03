/// Event-log data model — the target schema from
/// docs/Munshi_Scale_Up_Architecture.html §04, replacing the PWA's current
/// one-encrypted-blob-per-case shape. `CaseEvents` mirrors CLAUDE.md invariant
/// 1: append-only, never UPDATE/DELETE; corrections are new rows.
///
/// The whole database file is opened through SQLCipher (see `openConnection`)
/// so encryption is at the storage-engine layer, not per-column — case/note/
/// fee/document fields are stored as plain columns inside an encrypted DB
/// file, unlike vault.js's per-blob AES-GCM. Money is integer rupees
/// (invariant 6) — never a REAL/float column.
///
/// Not wired into the running app (see CLAUDE.md) and, as of this comment,
/// will not compile even in isolation: `pubspec.yaml` does not declare
/// `drift`, `sqlite3`, or `sqlcipher_flutter_libs`, all imported below.
/// Before building on this schema, add those dependencies, then regenerate
/// `app_database.g.dart` with:
///   dart run build_runner build --delete-conflicting-outputs
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

part 'app_database.g.dart';

/// One indexed row per case — the "list" query target (scale-up doc §04:
/// `SELECT ... FROM case_summary ORDER BY next_date LIMIT 20`).
class CaseSummaries extends Table {
  TextColumn get id => text()(); // client-generated UUID
  TextColumn get caseNumber => text()();
  TextColumn get court => text()();
  TextColumn get courtType => text().nullable()();
  TextColumn get stage => text().nullable()();
  DateTimeColumn get nextDate => dateTime().nullable()();
  TextColumn get nextDetail => text().nullable()();
  TextColumn get parties => text().nullable()();
  TextColumn get clientName => text().nullable()();
  TextColumn get clientPhone => text().nullable()();
  IntColumn get feeAgreedRupees => integer().nullable()(); // integer rupees only — invariant 6
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get urgent => boolean().withDefault(const Constant(false))();
  BoolColumn get disposed => boolean().withDefault(const Constant(false))();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Append-only log — one row per note/payment/hearing/court update. This is
/// the chat log; the UI is a rendering of it (invariant 1). `dedupKey` is what
/// makes a retried sync push a no-op (invariant 2), same field name as the
/// server's `sync_events.dedup_key` (mobile/backend/app/db.py).
class CaseEvents extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get caseId => text().references(CaseSummaries, #id)();
  TextColumn get eventId => text()(); // client-generated UUID
  TextColumn get dedupKey => text().unique()();
  TextColumn get side => text()(); // 'court' | 'lawyer' — left/right bubble
  TextColumn get kind => text()(); // causelist|hearing|order|note|task|payment|doc|client|system
  TextColumn get payloadJson => text()(); // canonical event payload, plaintext at rest inside the SQLCipher-encrypted file
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localId};
}

class DocumentRows extends Table {
  TextColumn get id => text()();
  TextColumn get caseId => text().references(CaseSummaries, #id)();
  TextColumn get name => text()();
  TextColumn get localPath => text()(); // encrypted file on disk, bytes never in the DB row
  TextColumn get sha256 => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get uploadedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [CaseSummaries, CaseEvents, DocumentRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

/// Opens the SQLCipher-encrypted database file. [passphrase] is the raw
/// vault data-key (see crypto/vault_crypto.dart) hex/base64-encoded — never a
/// hardcoded value, never logged.
LazyDatabase openConnection(String passphrase) {
  return LazyDatabase(() async {
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'munshi_vault.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$passphrase';");
      },
    );
  });
}
