import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:netcalc_app/services/supabase_service.dart'; // Global supabase client reference
import 'package:netcalc_app/widgets/new_entry_form.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isInitialLoading = true;
  bool _isBackgroundLoading = false;
  double? _rate;
  List<dynamic> _transactions = [];
  double _totalUsd = 0.0;
  String? _error;

  final _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  final _egpFormat = NumberFormat.currency(locale: 'en_US', symbol: 'EGP ');

  final _searchController = TextEditingController();
  String _searchQuery = '';

  late SharedPreferences _prefs;
  bool _prefsInitialized = false;
  bool _useManualRate = false;
  double _manualRate = 50.0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredTransactions {
    if (_searchQuery.isEmpty) return _transactions;
    final query = _searchQuery.toLowerCase();
    return _transactions.where((trx) {
      final desc = (trx['description'] as String?)?.toLowerCase() ?? '';
      final date = (trx['date'] as String?)?.toLowerCase() ?? '';
      final amount = trx['amount']?.toString() ?? '';
      return desc.contains(query) || date.contains(query) || amount.contains(query);
    }).toList();
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search history...',
        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showExchangeRateDialog() {
    final controller = TextEditingController(text: _manualRate.toStringAsFixed(2));
    bool useManual = _useManualRate;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Exchange Rate Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('Auto (API)')),
                      ButtonSegment(value: true, label: Text('Manual')),
                    ],
                    selected: {useManual},
                    onSelectionChanged: (s) {
                      setDialogState(() {
                        useManual = s.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (useManual)
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Manual EGP Rate',
                        hintText: 'e.g. 50.0',
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'API rate will be fetched dynamically from ExchangeRate-API.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final newRate = double.tryParse(controller.text) ?? _manualRate;
                    setState(() {
                      _useManualRate = useManual;
                      if (useManual) {
                        _manualRate = newRate;
                        _rate = newRate;
                      }
                    });
                    if (_prefsInitialized) {
                      await _prefs.setBool('use_manual_rate', useManual);
                      await _prefs.setDouble('manual_rate', newRate);
                    }
                    if (!useManual) {
                      _fetchInitialData();
                    }
                    navigator.pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _exportToCsv() {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Date,Description,Amount (USD),Exchange Rate');
      for (final trx in _transactions) {
        final date = trx['date'] ?? '';
        String desc = trx['description'] ?? '';
        if (desc.contains(',')) {
          desc = '"$desc"';
        }
        final amount = trx['amount'] ?? 0.0;
        final rate = trx['rate'] ?? _rate ?? 50.0;
        buffer.writeln('$date,$desc,$amount,$rate');
      }

      Clipboard.setData(ClipboardData(text: buffer.toString()));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calculation history copied to clipboard as CSV!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export history.')),
      );
    }
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;

    if (!_prefsInitialized) {
      try {
        _prefs = await SharedPreferences.getInstance();
        _useManualRate = _prefs.getBool('use_manual_rate') ?? false;
        _manualRate = _prefs.getDouble('manual_rate') ?? 50.0;

        final cachedJson = _prefs.getString('cached_transactions');
        if (cachedJson != null) {
          final List<dynamic> cachedList = jsonDecode(cachedJson);
          setState(() {
            _transactions = cachedList;
            _totalUsd = _calculateTotalUsd(cachedList);
            _isInitialLoading = false;
          });
        }
        _prefsInitialized = true;
      } catch (_) {}
    }

    setState(() {
      if (_transactions.isEmpty) {
        _isInitialLoading = true;
      }
      _isBackgroundLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([_getExchangeRate(), _loadTransactions()]);
      final double rate = results[0] as double;
      final List<dynamic> transactions = results[1] as List<dynamic>;

      if (_prefsInitialized) {
        await _prefs.setString('cached_transactions', jsonEncode(transactions));
      }

      if (!mounted) return;
      setState(() {
        _rate = _useManualRate ? _manualRate : rate;
        _transactions = transactions;
        _totalUsd = _calculateTotalUsd(transactions);
        _isInitialLoading = false;
        _isBackgroundLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rate = _useManualRate ? _manualRate : (_rate ?? 50.0);
        _error = _transactions.isNotEmpty
            ? "Offline mode. Showing cached data."
            : "Connection issue. Pull to retry.";
        _isInitialLoading = false;
        _isBackgroundLoading = false;
      });
    }
  }

  Future<double> _getExchangeRate() async {
    final apiKey = dotenv.get('EXCHANGE_RATE_API_KEY', fallback: 'FREE');
    if (apiKey == 'FREE') return 50.0;
    
    try {
      final response = await http.get(Uri.parse('https://v6.exchangerate-api.com/v6/$apiKey/latest/USD'));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body)['conversion_rates']['EGP'] as num).toDouble();
      }
    } catch (_) {}
    return 50.0; 
  }

  Future<void> _deleteEntry(int id) async {
    setState(() {
      _transactions.removeWhere((t) => t['id'] == id);
      _totalUsd = _calculateTotalUsd(_transactions);
    });

    try {
      await supabase.from('transactions').delete().eq('id', id);
      if (_prefsInitialized) {
        await _prefs.setString('cached_transactions', jsonEncode(_transactions));
      }
    } catch (e) {
      _fetchInitialData();
    }
  }

  Future<List<dynamic>> _loadTransactions() async {
    return await supabase.from('transactions').select().order('created_at', ascending: false);
  }

  double _calculateTotalUsd(List<dynamic> transactions) {
    return transactions.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (_isInitialLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    if (isLandscape) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(_error!, style: TextStyle(color: colorScheme.error)),
                        ),
                      _buildSummaryCard(colorScheme),
                      const SizedBox(height: 24),
                      NewEntryForm(rate: _rate ?? 50.0, onSuccess: _fetchInitialData),
                    ],
                  ),
                ),
              ),
              VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              Expanded(
                flex: 6,
                child: RefreshIndicator(
                  onRefresh: _fetchInitialData,
                  color: colorScheme.primary,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Recent History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      if (_transactions.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.copy_all),
                                          tooltip: 'Export CSV',
                                          onPressed: _exportToCsv,
                                        ),
                                      if (_isBackgroundLoading) ...[
                                        const SizedBox(width: 8),
                                        SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              if (_transactions.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildSearchBar(colorScheme),
                              ],
                            ],
                          ),
                        ),
                      ),
                      _buildTransactionList(colorScheme),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchInitialData,
        color: colorScheme.primary,
        edgeOffset: 100,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildAppBar(colorScheme),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_error!, style: TextStyle(color: colorScheme.error)),
                      ),
                    NewEntryForm(rate: _rate ?? 50.0, onSuccess: _fetchInitialData),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            if (_transactions.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.copy_all),
                                tooltip: 'Export CSV',
                                onPressed: _exportToCsv,
                              ),
                            if (_isBackgroundLoading) ...[
                              const SizedBox(width: 8),
                              SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (_transactions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildSearchBar(colorScheme),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildTransactionList(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryContent(ColorScheme colorScheme) {
    final totalEgp = _totalUsd * (_rate ?? 50.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Total Savings', style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 16)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_usdFormat.format(_totalUsd), style: TextStyle(color: colorScheme.onSurface, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1)),
        ),
        Text(_egpFormat.format(totalEgp), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 18)),
        const SizedBox(height: 8),
        if (_rate != null)
          TextButton.icon(
            onPressed: _showExchangeRateDialog,
            icon: Icon(Icons.edit, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            label: Text(
              '1 USD = ${_rate!.toStringAsFixed(2)} EGP ${_useManualRate ? "(Manual)" : ""}',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
                decoration: TextDecoration.underline,
                decorationColor: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primaryContainer, colorScheme.surface],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: _buildSummaryContent(colorScheme),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primaryContainer, colorScheme.surface],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: _buildSummaryContent(colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(ColorScheme colorScheme) {
    if (_transactions.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text("No transactions yet", style: TextStyle(color: colorScheme.onSurfaceVariant))),
      );
    }

    final filtered = _filteredTransactions;
    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  "No matches found for '$_searchQuery'",
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final trx = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Dismissible(
                key: ValueKey(trx['id']),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Entry'),
                      content: const Text('Are you sure you want to delete this entry?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) => _deleteEntry(trx['id'] as int),
                background: Container(
                  decoration: BoxDecoration(color: colorScheme.error, borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete_outline, color: colorScheme.onError),
                ),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(trx['description'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${trx['date']}  •  @ ${(trx['rate'] as num?)?.toStringAsFixed(2) ?? '50.00'} EGP',
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    trailing: Text(
                      _usdFormat.format(trx['amount']), 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: filtered.length,
        ),
      ),
    );
  }
}
