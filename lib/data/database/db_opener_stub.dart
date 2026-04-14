import 'package:drift/drift.dart';

/// Fallback opener used when neither dart:io nor dart:html is available.
/// This path should never execute in practice — conditional imports
/// always pick one of the real implementations.
QueryExecutor openDiaryDatabase() {
  throw UnsupportedError(
    'No database backend available for this platform.',
  );
}
