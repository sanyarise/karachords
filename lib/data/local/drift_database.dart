import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'drift_database.g.dart';

class Songs extends Table {
  TextColumn get id => text().withLength(min: 1, max: 128)();
  TextColumn get title => text().withLength(min: 1, max: 256)();
  TextColumn get artist => text().withLength(min: 1, max: 256)();
  IntColumn get bpm => integer().nullable()();
  TextColumn get jsonContent => text()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer().withDefault(Constant(DateTime.now().millisecondsSinceEpoch))();

  @override
  Set<Column> get primaryKey => {id};
}

class Settings extends Table {
  TextColumn get key => text().withLength(min: 1, max: 128)();
  TextColumn get jsonValue => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Songs, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'karachords_database');
  }
}
