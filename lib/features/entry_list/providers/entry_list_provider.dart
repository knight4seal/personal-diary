import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_diary/data/database/app_database.dart';
import 'package:personal_diary/data/repositories/diary_repository.dart';
import 'package:personal_diary/core/extensions/date_extensions.dart';
import 'package:personal_diary/services/drive_sync_service.dart';

enum ViewMode { daily, weekly, monthly, yearly }

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden at app startup');
});

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DiaryRepository(db);
});

final driveSyncServiceProvider = Provider<DriveSyncService>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  return DriveSyncService(repo);
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final viewModeProvider = StateProvider<ViewMode>((ref) {
  return ViewMode.daily;
});

final dailyEntriesProvider = StreamProvider<List<DiaryEntry>>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.watchEntriesForDate(date);
});

final weeklyEntriesProvider = StreamProvider<List<DiaryEntry>>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  final start = date.startOfWeek;
  final end = date.endOfWeek;
  return repo.watchEntriesForDateRange(start, end);
});

final monthlyEntriesProvider = StreamProvider<List<DiaryEntry>>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  final start = date.startOfMonth;
  final end = date.endOfMonth;
  return repo.watchEntriesForDateRange(start, end);
});

final yearlyCountsProvider = FutureProvider<Map<int, int>>((ref) async {
  final repo = ref.watch(diaryRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.getEntryCountsByMonth(date.year);
});
