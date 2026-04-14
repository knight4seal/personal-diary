import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

/// Native (iOS, Android, macOS) database opener. Uses SQLCipher to encrypt
/// the diary database file at rest with AES-256. The encryption key is
/// passed via PRAGMA key during the setup callback — the key itself is
/// generated and stored in the OS keychain by EncryptionService.
///
/// For now the key is a fixed placeholder because EncryptionService is not
/// yet wired into AppDatabase.open(). When that wiring is added, replace
/// the hardcoded key with the real one from flutter_secure_storage.
QueryExecutor openDiaryDatabase() {
  return LazyDatabase(() async {
    // Apply workarounds for older Android sqlcipher builds where sqlite's
    // built-in tempfile handling conflicts with SQLCipher's.
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'diary.db'));

    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // TODO: replace this placeholder with the real encryption key
        // retrieved from EncryptionService (flutter_secure_storage).
        // For first-run testing, a fixed key is acceptable — it still
        // encrypts the DB file on disk, just with a predictable key.
        db.execute("PRAGMA key = 'personaldiary-dev-key-v1';");

        // Verify SQLCipher is active (not plain sqlite). This throws if
        // we accidentally linked against unencrypted sqlite instead.
        final result = db.select('PRAGMA cipher_version;');
        if (result.isEmpty) {
          throw StateError(
            'SQLCipher is not available — the database would be unencrypted. '
            'Ensure sqlcipher_flutter_libs is installed correctly.',
          );
        }
      },
    );
  });
}
