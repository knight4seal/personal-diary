import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/diary_entries.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [DiaryEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  static AppDatabase open() {
    return AppDatabase(
      driftDatabase(
        name: 'diary',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.dart.js'),
        ),
      ),
    );
  }

  // --- CRUD Operations ---

  Future<List<DiaryEntry>> getEntriesForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return (select(diaryEntries)
          ..where((e) => e.entryDate.isBetweenValues(start, end))
          ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
        .get();
  }

  Stream<List<DiaryEntry>> watchEntriesForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return (select(diaryEntries)
          ..where((e) => e.entryDate.isBetweenValues(start, end))
          ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
        .watch();
  }

  Stream<List<DiaryEntry>> watchEntriesForDateRange(
      DateTime start, DateTime end) {
    return (select(diaryEntries)
          ..where((e) => e.entryDate.isBetweenValues(start, end))
          ..orderBy([
            (e) => OrderingTerm.asc(e.entryDate),
            (e) => OrderingTerm.asc(e.createdAt),
          ]))
        .watch();
  }

  Future<Map<int, int>> getEntryCountsByMonth(int year) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31, 23, 59, 59, 999);
    final entries = await (select(diaryEntries)
          ..where((e) => e.entryDate.isBetweenValues(start, end)))
        .get();

    final counts = <int, int>{};
    for (final entry in entries) {
      final month = entry.entryDate.month;
      counts[month] = (counts[month] ?? 0) + 1;
    }
    return counts;
  }

  Future<List<DiaryEntry>> searchEntries(String query,
      {DateTime? startDate, DateTime? endDate}) {
    return (select(diaryEntries)
          ..where((e) {
            var condition =
                e.content.like('%$query%') | e.title.like('%$query%');
            if (startDate != null) {
              condition =
                  condition & e.entryDate.isBiggerOrEqualValue(startDate);
            }
            if (endDate != null) {
              condition =
                  condition & e.entryDate.isSmallerOrEqualValue(endDate);
            }
            return condition;
          })
          ..orderBy([(e) => OrderingTerm.desc(e.entryDate)]))
        .get();
  }

  Future<int> insertDiaryEntry(DiaryEntriesCompanion entry) {
    return into(diaryEntries).insert(entry);
  }

  Future<bool> updateDiaryEntry(DiaryEntriesCompanion entry) {
    return update(diaryEntries).replace(entry);
  }

  Future<int> deleteDiaryEntry(int id) {
    return (delete(diaryEntries)..where((e) => e.id.equals(id))).go();
  }

  Future<DiaryEntry?> getDiaryEntry(int id) {
    return (select(diaryEntries)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<DiaryEntry>> getEntriesWithExpiredAudio() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return (select(diaryEntries)
          ..where((e) =>
              e.audioFilePath.isNotNull() &
              e.audioCreatedAt.isSmallerOrEqualValue(cutoff)))
        .get();
  }

  Future<void> clearAudioPath(int id) async {
    await (update(diaryEntries)..where((e) => e.id.equals(id))).write(
      DiaryEntriesCompanion(
        audioFilePath: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
