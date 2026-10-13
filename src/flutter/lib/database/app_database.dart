import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

part 'app_database.g.dart';

// Same shape as the old CREATE TABLE in transaction_db.dart:
// id INTEGER PRIMARY KEY AUTOINCREMENT, description TEXT NOT NULL,
// amount REAL NOT NULL, rate REAL (nullable), date TEXT NOT NULL,
// created_at TEXT NOT NULL.
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  // Nullable: NULL allowed, matching the old `rate REAL` column.
  RealColumn get rate => real().nullable()();
  TextColumn get date => text()();
  // Dart name createdAt maps to column name created_at automatically.
  TextColumn get createdAt => text()();
}

@DriftDatabase(tables: [Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  // Matches the old sqflite `version: 2`, so existing netcalc.db files
  // open without running any migration.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_created_at '
            'ON transactions (created_at DESC)',
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_created_at '
              'ON transactions (created_at DESC)',
            );
          }
        },
      );
}

LazyDatabase _open() => LazyDatabase(() async {
      // Same file the old code used, so existing users keep their data.
      final dir = await getDatabasesPath();
      final file = File(p.join(dir, 'netcalc.db'));
      return NativeDatabase.createInBackground(file);
    });
