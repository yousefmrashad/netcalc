import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TransactionDb {
  TransactionDb._();
  static final TransactionDb instance = TransactionDb._();

  Database? _db;

  Future<void> open() async {
    if (_db != null) return;
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'netcalc.db'),
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          rate REAL,
          date TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      '''),
    );
  }

  Future<List<Map<String, Object?>>> list() =>
      _db!.query('transactions', orderBy: 'id DESC');

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
