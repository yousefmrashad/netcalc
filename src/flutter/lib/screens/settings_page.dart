import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:netcalc_app/services/data_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  bool _backendSupabase = false;
  bool _saving = false;
  bool _loaded = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _apiKeyController.text = _prefs.getString('exchange_rate_api_key') ?? '';
      _urlController.text = _prefs.getString('supabase_url') ?? '';
      _keyController.text = _prefs.getString('supabase_anon_key') ?? '';
      _backendSupabase = DataRepository.instance.useSupabase;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _prefs.setString(
        'exchange_rate_api_key',
        _apiKeyController.text.trim(),
      );
      await _prefs.setString('supabase_url', _urlController.text.trim());
      await _prefs.setString(
        'supabase_anon_key',
        _keyController.text.trim(),
      );
      final ok = await DataRepository.instance.setBackend(
        _backendSupabase ? 'supabase' : 'sqlite',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Settings saved.'
                : 'Could not connect to Supabase. Using local SQLite instead.',
          ),
        ),
      );
      if (ok) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surface,
      ),
      body: !_loaded
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Exchange Rate',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'ExchangeRate-API Key',
                    hintText: 'Leave empty to use the free tier',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Storage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose where transactions are saved. Supabase requires a URL and anon key.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'sqlite', label: Text('Local (SQLite)')),
                    ButtonSegment(value: 'supabase', label: Text('Supabase')),
                  ],
                  selected: {_backendSupabase ? 'supabase' : 'sqlite'},
                  onSelectionChanged: (s) {
                    setState(() {
                      _backendSupabase = s.first == 'supabase';
                    });
                  },
                ),
                if (_backendSupabase) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Supabase URL',
                      hintText: 'https://xxxx.supabase.co',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _keyController,
                    decoration: const InputDecoration(
                      labelText: 'Supabase Anon Key',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Note: credential changes take effect after restarting the app.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
