import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/app_database.dart';

class DiaryRepository {
  final AppDatabase _db;

  DiaryRepository(this._db);

  Stream<List<DiaryEntry>> watchEntriesForDate(DateTime date) =>
      _db.watchEntriesForDate(date);

  Stream<List<DiaryEntry>> watchEntriesForDateRange(
          DateTime start, DateTime end) =>
      _db.watchEntriesForDateRange(start, end);

  Future<Map<int, int>> getEntryCountsByMonth(int year) =>
      _db.getEntryCountsByMonth(year);

  Future<List<DiaryEntry>> searchEntries(String query,
          {DateTime? startDate, DateTime? endDate}) =>
      _db.searchEntries(query, startDate: startDate, endDate: endDate);

  Future<DiaryEntry?> getEntry(int id) => _db.getDiaryEntry(id);

  Future<int> createEntry({
    required DateTime entryDate,
    String? title,
    required String content,
    bool isVoiceTranscribed = false,
    String? audioFilePath,
    DateTime? audioCreatedAt,
  }) {
    final now = DateTime.now();
    return _db.insertDiaryEntry(DiaryEntriesCompanion(
      entryDate: Value(entryDate),
      title: Value(title),
      content: Value(content),
      isVoiceTranscribed: Value(isVoiceTranscribed),
      audioFilePath: Value(audioFilePath),
      audioCreatedAt: Value(audioCreatedAt),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  Future<void> updateEntry({
    required int id,
    DateTime? entryDate,
    String? title,
    String? content,
    bool? isVoiceTranscribed,
    String? audioFilePath,
    DateTime? audioCreatedAt,
  }) async {
    final existing = await _db.getDiaryEntry(id);
    if (existing == null) return;

    await _db.updateDiaryEntry(DiaryEntriesCompanion(
      id: Value(id),
      entryDate: Value(entryDate ?? existing.entryDate),
      title: Value(title ?? existing.title),
      content: Value(content ?? existing.content),
      isVoiceTranscribed:
          Value(isVoiceTranscribed ?? existing.isVoiceTranscribed),
      audioFilePath: Value(audioFilePath ?? existing.audioFilePath),
      audioCreatedAt: Value(audioCreatedAt ?? existing.audioCreatedAt),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> deleteEntry(int id) async {
    final entry = await _db.getDiaryEntry(id);
    if (entry?.audioFilePath != null) {
      await _deleteAudioFile(entry!.audioFilePath!);
    }
    await _db.deleteDiaryEntry(id);
  }

  Future<void> cleanupExpiredAudio() async {
    final entries = await _db.getEntriesWithExpiredAudio();
    for (final entry in entries) {
      if (entry.audioFilePath != null) {
        await _deleteAudioFile(entry.audioFilePath!);
        await _db.clearAudioPath(entry.id);
      }
    }
  }

  Future<void> _deleteAudioFile(String relativePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(appDir.path, relativePath));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<String> exportToJson() async {
    final allEntries = await _db.select(_db.diaryEntries).get();
    final buffer = StringBuffer();
    buffer.writeln('[');
    for (var i = 0; i < allEntries.length; i++) {
      final e = allEntries[i];
      buffer.write('  {');
      buffer.write('"id":${e.id},');
      buffer.write('"entryDate":"${e.entryDate.toIso8601String()}",');
      buffer.write('"title":${e.title != null ? '"${_escape(e.title!)}"' : 'null'},');
      buffer.write('"content":"${_escape(e.content)}",');
      buffer.write('"isVoiceTranscribed":${e.isVoiceTranscribed},');
      buffer.write('"createdAt":"${e.createdAt.toIso8601String()}",');
      buffer.write('"updatedAt":"${e.updatedAt.toIso8601String()}"');
      buffer.write('}');
      if (i < allEntries.length - 1) buffer.write(',');
      buffer.writeln();
    }
    buffer.writeln(']');
    return buffer.toString();
  }

  String _escape(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n');
}
