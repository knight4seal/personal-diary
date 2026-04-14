import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web (browser) database opener. Uses drift's WasmDatabase which runs
/// SQLite compiled to WebAssembly inside a shared web worker, with storage
/// backed by IndexedDB. The sqlite3.wasm and drift_worker.dart.js files
/// must be copied into the web/ folder at build time.
///
/// Note: Web builds don't get SQLCipher encryption at rest because the
/// WASM build of sqlite3 doesn't include the SQLCipher extension. Browser
/// storage is sandboxed per-origin, so security relies on that sandbox
/// plus application-level encryption if needed.
QueryExecutor openDiaryDatabase() {
  return LazyDatabase(() async {
    final db = await WasmDatabase.open(
      databaseName: 'diary',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    return db.resolvedExecutor;
  });
}
