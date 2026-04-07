import 'package:drift/drift.dart';

class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get title => text().nullable()();
  TextColumn get content => text()();
  BoolColumn get isVoiceTranscribed =>
      boolean().withDefault(const Constant(false))();
  TextColumn get audioFilePath => text().nullable()();
  DateTimeColumn get audioCreatedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
