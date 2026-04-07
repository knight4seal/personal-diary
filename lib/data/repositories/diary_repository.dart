import 'dart:convert';
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
      lastEditedAt: Value(now),
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
      lastEditedAt: Value(DateTime.now()),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
    ));
  }

  bool isEditable(DiaryEntry entry) {
    return DateTime.now().difference(entry.lastEditedAt).inHours < 72;
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
      buffer.write('"lastEditedAt":"${e.lastEditedAt.toIso8601String()}",');
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

  /// Imports entries from a JSON array string.
  /// Inserts new entries and updates existing ones only if the imported
  /// version is newer (by updatedAt / lastEditedAt).
  /// Returns the number of entries imported or updated.
  Future<int> importFromJson(String jsonString) async {
    final List<dynamic> entries = jsonDecode(jsonString) as List<dynamic>;
    int count = 0;

    for (final raw in entries) {
      final map = raw as Map<String, dynamic>;
      final id = map['id'] as int;
      final entryDate = DateTime.parse(map['entryDate'] as String);
      final title = map['title'] as String?;
      final content = map['content'] as String;
      final isVoiceTranscribed = map['isVoiceTranscribed'] as bool? ?? false;
      final createdAt = DateTime.parse(map['createdAt'] as String);
      final updatedAt = DateTime.parse(map['updatedAt'] as String);
      // lastEditedAt may or may not be present; fall back to updatedAt
      final lastEditedAt = map['lastEditedAt'] != null
          ? DateTime.parse(map['lastEditedAt'] as String)
          : updatedAt;

      final existing = await _db.getDiaryEntry(id);

      if (existing == null) {
        // Insert new entry
        await _db.into(_db.diaryEntries).insert(DiaryEntriesCompanion(
              id: Value(id),
              entryDate: Value(entryDate),
              title: Value(title),
              content: Value(content),
              isVoiceTranscribed: Value(isVoiceTranscribed),
              lastEditedAt: Value(lastEditedAt),
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
            ));
        count++;
      } else {
        // Update only if imported version is newer
        if (updatedAt.isAfter(existing.updatedAt)) {
          await _db.updateDiaryEntry(DiaryEntriesCompanion(
            id: Value(id),
            entryDate: Value(entryDate),
            title: Value(title),
            content: Value(content),
            isVoiceTranscribed: Value(isVoiceTranscribed),
            lastEditedAt: Value(lastEditedAt),
            createdAt: Value(createdAt),
            updatedAt: Value(updatedAt),
          ));
          count++;
        }
      }
    }

    return count;
  }
}
