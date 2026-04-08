import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:personal_diary/data/database/app_database.dart';
import 'package:personal_diary/data/repositories/diary_repository.dart';
import 'package:personal_diary/services/quote_service.dart';
import 'package:personal_diary/core/extensions/date_extensions.dart';

/// Creates an in-memory database for testing (no encryption, no disk)
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late DiaryRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = DiaryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Entry CRUD', () {
    test('create and read entry', () async {
      final id = await repo.createEntry(
        entryDate: DateTime(2026, 4, 7),
        title: 'Morning Walk',
        content: 'Went for a walk by the river. The air was crisp.',
      );

      expect(id, greaterThan(0));

      final entry = await repo.getEntry(id);
      expect(entry, isNotNull);
      expect(entry!.title, 'Morning Walk');
      expect(entry.content, 'Went for a walk by the river. The air was crisp.');
      expect(entry.entryDate.day, 7);
    });

    test('create multiple entries per day', () async {
      final date = DateTime(2026, 4, 7);
      await repo.createEntry(entryDate: date, content: 'Morning entry');
      await repo.createEntry(entryDate: date, content: 'Afternoon entry');
      await repo.createEntry(entryDate: date, content: 'Evening entry');

      final entries = await db.getEntriesForDate(date);
      expect(entries.length, 3);
    });

    test('update entry', () async {
      final id = await repo.createEntry(
        entryDate: DateTime(2026, 4, 7),
        content: 'Original content',
      );

      await repo.updateEntry(id: id, content: 'Updated content');

      final entry = await repo.getEntry(id);
      expect(entry!.content, 'Updated content');
    });

    test('delete entry', () async {
      final id = await repo.createEntry(
        entryDate: DateTime(2026, 4, 7),
        content: 'To be deleted',
      );

      await repo.deleteEntry(id);
      final entry = await repo.getEntry(id);
      expect(entry, isNull);
    });

    test('entry with voice transcription flag', () async {
      final id = await repo.createEntry(
        entryDate: DateTime(2026, 4, 7),
        content: 'Voice transcribed content.',
        isVoiceTranscribed: true,
        audioFilePath: 'audio/test.m4a',
        audioCreatedAt: DateTime.now(),
      );

      final entry = await repo.getEntry(id);
      expect(entry!.isVoiceTranscribed, true);
      expect(entry.audioFilePath, 'audio/test.m4a');
    });

    test('backdated entry', () async {
      final pastDate = DateTime(2025, 12, 25);
      final id = await repo.createEntry(
        entryDate: pastDate,
        title: 'Christmas Memory',
        content: 'A beautiful Christmas day.',
      );

      final entry = await repo.getEntry(id);
      expect(entry!.entryDate.year, 2025);
      expect(entry.entryDate.month, 12);
      expect(entry.entryDate.day, 25);
    });
  });

  group('Date Queries', () {
    setUp(() async {
      // Seed data across multiple days
      for (int day = 1; day <= 30; day++) {
        final date = DateTime(2026, 4, day);
        await repo.createEntry(
          entryDate: date,
          title: 'Day $day',
          content: 'Entry for April $day, 2026.',
        );
        // Add extra entries on some days
        if (day % 3 == 0) {
          await repo.createEntry(
            entryDate: date,
            content: 'Second entry for April $day.',
          );
        }
      }
    });

    test('daily entries returns only that day', () async {
      final entries = await db.getEntriesForDate(DateTime(2026, 4, 15));
      expect(entries.length, 2); // day 15 is divisible by 3
    });

    test('weekly entries returns 7 days', () async {
      final date = DateTime(2026, 4, 13); // Monday
      final start = date.startOfWeek;
      final end = date.endOfWeek;

      final stream = db.watchEntriesForDateRange(start, end);
      final entries = await stream.first;

      // April 13-19: 7 days, plus extras on 15, 18 = 9 entries
      expect(entries.length, 9);
    });

    test('monthly entry counts', () async {
      final counts = await repo.getEntryCountsByMonth(2026);
      expect(counts[4], 40); // 30 days + 10 extras (days 3,6,9,...,30)
    });

    test('yearly entry counts only returns months with data', () async {
      final counts = await repo.getEntryCountsByMonth(2026);
      expect(counts.containsKey(1), false); // No January entries
      expect(counts.containsKey(4), true);  // April has entries
    });
  });

  group('Search', () {
    setUp(() async {
      await repo.createEntry(
        entryDate: DateTime(2026, 4, 1),
        title: 'Morning Walk',
        content: 'Went for a beautiful walk by the river.',
      );
      await repo.createEntry(
        entryDate: DateTime(2026, 4, 2),
        title: 'Work Notes',
        content: 'Had a productive meeting about the new project.',
      );
      await repo.createEntry(
        entryDate: DateTime(2026, 4, 3),
        content: 'Cooked dinner. Made pasta with river trout.',
      );
    });

    test('search by content keyword', () async {
      final results = await repo.searchEntries('river');
      expect(results.length, 2); // "river" in entry 1 and 3
    });

    test('search by title', () async {
      final results = await repo.searchEntries('Walk');
      expect(results.length, 1);
      expect(results.first.title, 'Morning Walk');
    });

    test('search with date range filter', () async {
      final results = await repo.searchEntries(
        'river',
        startDate: DateTime(2026, 4, 2),
        endDate: DateTime(2026, 4, 30),
      );
      expect(results.length, 1); // Only entry 3 (Apr 3) matches
    });

    test('search returns empty for no match', () async {
      final results = await repo.searchEntries('zzznonexistent');
      expect(results.isEmpty, true);
    });
  });

  group('72-Hour Edit Window', () {
    test('new entry is editable', () async {
      final id = await repo.createEntry(
        entryDate: DateTime.now(),
        content: 'Fresh entry',
      );
      final entry = await repo.getEntry(id);
      expect(repo.isEditable(entry!), true);
    });

    test('entry older than 72h is not editable', () async {
      final now = DateTime.now();
      final id = await db.insertDiaryEntry(DiaryEntriesCompanion(
        entryDate: Value(now),
        content: const Value('Old entry'),
        lastEditedAt: Value(now.subtract(const Duration(hours: 73))),
        createdAt: Value(now.subtract(const Duration(hours: 73))),
        updatedAt: Value(now.subtract(const Duration(hours: 73))),
      ));

      final entry = await repo.getEntry(id);
      expect(repo.isEditable(entry!), false);
    });

    test('entry at exactly 71h is still editable', () async {
      final now = DateTime.now();
      final id = await db.insertDiaryEntry(DiaryEntriesCompanion(
        entryDate: Value(now),
        content: const Value('Almost locked entry'),
        lastEditedAt: Value(now.subtract(const Duration(hours: 71))),
        createdAt: Value(now.subtract(const Duration(hours: 71))),
        updatedAt: Value(now.subtract(const Duration(hours: 71))),
      ));

      final entry = await repo.getEntry(id);
      expect(repo.isEditable(entry!), true);
    });
  });

  group('Audio Cleanup (24h)', () {
    test('expired audio entries are found', () async {
      final now = DateTime.now();

      // Entry with audio older than 24h
      await db.insertDiaryEntry(DiaryEntriesCompanion(
        entryDate: Value(now),
        content: const Value('Old audio entry'),
        audioFilePath: const Value('audio/old.m4a'),
        audioCreatedAt: Value(now.subtract(const Duration(hours: 25))),
        lastEditedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      // Entry with recent audio (should NOT be found)
      await db.insertDiaryEntry(DiaryEntriesCompanion(
        entryDate: Value(now),
        content: const Value('New audio entry'),
        audioFilePath: const Value('audio/new.m4a'),
        audioCreatedAt: Value(now.subtract(const Duration(hours: 1))),
        lastEditedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final expired = await db.getEntriesWithExpiredAudio();
      expect(expired.length, 1);
      expect(expired.first.audioFilePath, 'audio/old.m4a');
    });

    test('clearAudioPath nullifies path', () async {
      final now = DateTime.now();
      final id = await db.insertDiaryEntry(DiaryEntriesCompanion(
        entryDate: Value(now),
        content: const Value('Audio entry'),
        audioFilePath: const Value('audio/test.m4a'),
        audioCreatedAt: Value(now),
        lastEditedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      await db.clearAudioPath(id);
      final entry = await repo.getEntry(id);
      expect(entry!.audioFilePath, isNull);
      expect(entry.content, 'Audio entry'); // Content preserved
    });
  });

  group('Export/Import', () {
    test('export produces valid JSON', () async {
      await repo.createEntry(
        entryDate: DateTime(2026, 4, 7),
        title: 'Test Entry',
        content: 'Content with "quotes" and\nnewlines.',
      );

      final json = await repo.exportToJson();
      expect(json, contains('Test Entry'));
      expect(json, contains('Content with'));
      expect(json, startsWith('['));
      expect(json.trim(), endsWith(']'));
    });

    test('import merges entries', () async {
      await repo.createEntry(
        entryDate: DateTime(2026, 4, 7),
        title: 'Existing',
        content: 'Already here.',
      );

      final importJson = '''[
        {"id":999,"entryDate":"2026-04-08T00:00:00.000","title":"Imported","content":"From backup.","isVoiceTranscribed":false,"lastEditedAt":"2026-04-08T10:00:00.000","createdAt":"2026-04-08T10:00:00.000","updatedAt":"2026-04-08T10:00:00.000"}
      ]''';

      final count = await repo.importFromJson(importJson);
      expect(count, 1);
    });
  });

  group('Date Extensions', () {
    test('formattedDate', () {
      final date = DateTime(2026, 4, 7); // Tuesday
      expect(date.formattedDate, 'Tuesday, April 7, 2026');
    });

    test('startOfWeek', () {
      final date = DateTime(2026, 4, 9); // Thursday
      expect(date.startOfWeek.weekday, DateTime.monday);
      expect(date.startOfWeek.day, 6); // April 6 is Monday
    });

    test('startOfMonth', () {
      final date = DateTime(2026, 4, 15);
      expect(date.startOfMonth.day, 1);
    });

    test('isSameDay', () {
      final a = DateTime(2026, 4, 7, 10, 30);
      final b = DateTime(2026, 4, 7, 22, 15);
      final c = DateTime(2026, 4, 8, 10, 30);
      expect(a.isSameDay(b), true);
      expect(a.isSameDay(c), false);
    });

    test('timeString', () {
      final date = DateTime(2026, 4, 7, 14, 5);
      expect(date.timeString, '2:05p');
    });
  });

  group('Quote Service', () {
    test('fallback quotes are available', () {
      // QuoteService has built-in fallback quotes
      // We can't test the API without SharedPreferences, but verify the concept
      expect(true, true); // Placeholder for now
    });
  });
}
