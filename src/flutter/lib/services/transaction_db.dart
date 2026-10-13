import 'package:drift/drift.dart';

import 'package:netcalc_app/database/app_database.dart';

class TransactionDb {
  TransactionDb._();
  static final TransactionDb instance = TransactionDb._();

  AppDatabase? _db;

  Future<void> open() async {
    _db ??= AppDatabase();
    // Probe query: forces the lazy connection open now (same as before),
    // so errors surface here instead of on first list/insert.
    // ignore: avoid_redundant_async
    await _db!.customSelect('SELECT 1').get();
  }

  AppDatabase get _ready {
    final db = _db;
    if (db == null) {
      throw StateError('TransactionDb.open() must be called first');
    }
    return db;
  }

  Future<List<Map<String, Object?>>> list() async {
    final rows = await (_ready.select(_ready.transactions)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
    // Keep the old Map-based shape so callers are untouched.
    // The list is a plain growable List, safe for removeWhere.
    return rows
        .map((t) => <String, Object?>{
              'id': t.id,
              'description': t.description,
              'amount': t.amount,
              'rate': t.rate,
              'date': t.date,
              'created_at': t.createdAt,
            })
        .toList();
  }

  Future<int> insert(Map<String, Object?> row) =>
      _ready.into(_ready.transactions).insert(
            TransactionsCompanion.insert(
              description: row['description'] as String,
              amount: (row['amount'] as num).toDouble(),
              rate: Value((row['rate'] as num?)?.toDouble()),
              date: row['date'] as String,
              createdAt: DateTime.now().toIso8601String(),
            ),
          );

  Future<int> delete(int id) =>
      (_ready.delete(_ready.transactions)..where((t) => t.id.equals(id))).go();
}
