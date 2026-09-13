import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:netcalc_app/services/transaction_db.dart';

class DataRepository {
  DataRepository._();
  static final DataRepository instance = DataRepository._();

  late SharedPreferences _prefs;
  bool _useSupabase = false;
  bool _supabaseInitialized = false;

  bool get useSupabase => _useSupabase;
  String get backend =>
      _useSupabase ? 'supabase' : 'sqlite';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await TransactionDb.instance.open();
    if (_prefs.getString('storage_backend') == 'supabase') {
      try {
        await _initSupabase();
        _useSupabase = true;
      } catch (_) {
        _useSupabase = false;
      }
    }
  }

  Future<bool> setBackend(String backend) async {
    await _prefs.setString('storage_backend', backend);
    if (backend == 'supabase') {
      try {
        await _initSupabase();
        _useSupabase = true;
        return true;
      } catch (_) {
        _useSupabase = false;
        await _prefs.setString('storage_backend', 'sqlite');
        return false;
      }
    }
    _useSupabase = false;
    return true;
  }

  Future<void> _initSupabase() async {
    final url = _prefs.getString('supabase_url');
    final key = _prefs.getString('supabase_anon_key');
    if (url == null ||
        url.isEmpty ||
        key == null ||
        key.isEmpty) {
      throw StateError('Supabase credentials not configured');
    }
    if (!_supabaseInitialized) {
      await Supabase.initialize(url: url, anonKey: key);
      _supabaseInitialized = true;
    }
  }

  Future<List<Map<String, dynamic>>> list() async {
    if (_useSupabase) {
      final rows = await Supabase.instance.client
          .from('transactions')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    }
    return TransactionDb.instance.list();
  }

  Future<void> insert(Map<String, dynamic> row) async {
    if (_useSupabase) {
      await Supabase.instance.client.from('transactions').insert(row);
    } else {
      await TransactionDb.instance.insert(row);
    }
  }

  Future<void> delete(int id) async {
    if (_useSupabase) {
      await Supabase.instance.client
          .from('transactions')
          .delete()
          .eq('id', id);
    } else {
      await TransactionDb.instance.delete(id);
    }
  }
}
