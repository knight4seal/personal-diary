import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_diary/data/database/app_database.dart';
import 'package:personal_diary/data/repositories/diary_repository.dart';
import 'package:personal_diary/features/entry_list/providers/entry_list_provider.dart';

final editorEntryIdProvider = StateProvider<int?>((ref) => null);

final editorDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final editorTitleProvider = StateProvider<String?>((ref) => null);

final editorContentProvider = StateProvider<String>((ref) => '');

final saveEntryProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final repo = ref.read(diaryRepositoryProvider);
    final entryId = ref.read(editorEntryIdProvider);
    final date = ref.read(editorDateProvider);
    final title = ref.read(editorTitleProvider);
    final content = ref.read(editorContentProvider);

    if (entryId != null) {
      await repo.updateEntry(
        id: entryId,
        entryDate: date,
        title: title,
        content: content,
      );
    } else {
      await repo.createEntry(
        entryDate: date,
        title: title,
        content: content,
      );
    }
  };
});
