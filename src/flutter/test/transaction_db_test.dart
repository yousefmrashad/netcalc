import 'package:flutter_test/flutter_test.dart';
import 'package:netcalc_app/services/transaction_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('insert -> list -> delete -> list persists across reopen', () async {
    final db = TransactionDb.instance;
    await db.open();

    final id = await db.insert({
      'description': 'test entry',
      'amount': 1.5,
      'rate': 50.0,
      'date': 'Jan 01, 2026',
    });
    expect(id, greaterThan(0));

    var rows = await db.list();
    expect(rows.any((r) => r['id'] == id), isTrue);

    // Regression: list() must return a MUTABLE list. sqflite's raw
    // QueryResultSet is read-only and removeWhere on it throws
    // "Unsupported operation: read-only" (this broke UI deletes).
    rows.removeWhere((r) => r['id'] == id);

    final deleted = await db.delete(id);
    expect(deleted, 1);

    rows = await db.list();
    expect(rows.any((r) => r['id'] == id), isFalse);

    // Reopen a fresh connection and confirm the row is still gone.
    await db.open();
    rows = await db.list();
    expect(rows.any((r) => r['id'] == id), isFalse);

    expect(await db.delete(id), 0);
  });
}
