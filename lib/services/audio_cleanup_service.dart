import 'dart:async';
import 'dart:io';

import 'package:personal_diary/data/database/app_database.dart';
import 'package:drift/drift.dart';

class AudioCleanupService {
  final AppDatabase _db;
  Timer? _timer;

  static const _cleanupInterval = Duration(hours: 1);
  static const _audioMaxAge = Duration(hours: 24);

  AudioCleanupService(this._db);

  void init() {
    _runCleanup();
    _timer = Timer.periodic(_cleanupInterval, (_) => _runCleanup());
  }

  Future<void> _runCleanup() async {
    try {
      final cutoff = DateTime.now().subtract(_audioMaxAge);

      final staleEntries = await (_db.select(_db.diaryEntries)
            ..where((e) => e.audioFilePath.isNotNull())
            ..where((e) => e.audioCreatedAt.isSmallerThanValue(cutoff)))
          .get();

      for (final entry in staleEntries) {
        if (entry.audioFilePath != null) {
          final file = File(entry.audioFilePath!);
          if (await file.exists()) {
            await file.delete();
          }

          await (_db.update(_db.diaryEntries)
                ..where((e) => e.id.equals(entry.id)))
              .write(DiaryEntriesCompanion(
            audioFilePath: const Value(null),
          ));
        }
      }
    } catch (e) {
      // Silently handle cleanup errors; will retry next interval
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
