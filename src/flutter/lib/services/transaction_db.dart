import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TransactionDb {
  TransactionDb._();
  static final TransactionDb instance = TransactionDb._();

  Database? _db;
  Future<Database>? _opening;

  Future<Database> _connect() {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    return getDatabasesPath().then((dir) => openDatabase(
          p.join(dir, 'netcalc.db'),
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE transactions(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                description TEXT NOT NULL,
                amount REAL NOT NULL,
                rate REAL,
                date TEXT NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
            await db.execute(
              'CREATE INDEX idx_transactions_created_at '
              'ON transactions(created_at DESC)',
            );
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_transactions_created_at '
                'ON transactions(created_at DESC)',
              );
            }
          },
        ));
  }

  Future<void> open() async {
    _opening ??= _connect();
    try {
      _db = await _opening;
    } catch (e) {
      _opening = null;
      rethrow;
    }
  }

  Future<List<Map<String, Object?>>> list() async {
    // sqflite returns a read-only QueryResultSet; copy it so callers
    // can mutate the list (e.g. removeWhere after a delete).
    final rows = await _db!.query(
      'transactions',
      orderBy: 'created_at DESC, id DESC',
    );
    return List<Map<String, Object?>>.from(rows);
  }

  Future<int> insert(Map<String, Object?> row) => _db!.insert('transactions', {
        'description': row['description'],
        'amount': row['amount'],
        'rate': row['rate'],
        'date': row['date'],
        'created_at': DateTime.now().toIso8601String(),
      });

  Future<int> delete(int id) =>
      _db!.delete('transactions', where: 'id = ?', whereArgs: [id]);
}
