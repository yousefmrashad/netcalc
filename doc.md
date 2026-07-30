Welcome to Flutter! It is a fantastic framework for building beautiful, natively compiled applications for mobile, web, desktop, and embedded devices from a single
codebase.

Your application, NetCalc, is a personal finance tracker that allows you to calculate savings, record transactions, dynamically convert between USD and EGP (using either
an external exchange rate API or a manually set rate), evaluate mathematical expressions directly in the input (e.g., entering  150 * 3  as the amount), cache data
locally, and sync data in real-time with a Supabase database backend.
──────
### Table of Contents

1. External Libraries & Packages (Overview)
2. 1. Database Service Layer:  supabase_service.dart
3. 2. Application Entry Point:  main.dart
4. 3. The Entry Input Component:  new_entry_form.dart
5. 4. The Core Screen:  home_page.dart
──────
### External Libraries & Packages

To help you understand the code, here are the external packages defined in your pubspec.yaml:

•  supabase_flutter : The official client library for interacting with Supabase (an open-source Firebase alternative) to store/retrieve transaction records.
•  flutter_dotenv : Loads configuration values (like API keys and URLs) from a local  .env  file, keeping keys out of your source code.
•  http : Used to send HTTP requests to fetch currency exchange rates.
•  intl : Standard package for formatting dates, times, and currencies (e.g., rendering numbers like  $1,250.00 ).
•  math_expressions : A parser that parses and evaluates mathematical expression strings (e.g., parsing the string  "100 * 2.5"  and calculating  250.0 ).
•  dynamic_color : Integrates with Android's Material You dynamic theming, generating a color palette that matches the user's system wallpaper.
•  shared_preferences : A local storage system that saves settings (like manual exchange rates) and caches transactions so the app can load instantly even when offline.
──────
### 1. Database Service Layer: supabase_service.dart

This file sets up a single, globally accessible instance of the Supabase Client.

1: import 'package:supabase_flutter/supabase_flutter.dart';
2:
3: // Neutral, global instance of Supabase Client to break circular dependencies
4: final supabase = Supabase.instance.client;

• Line 1: Imports the  supabase_flutter  library so the code can use Supabase objects.
• Line 4: Declares a global variable named  supabase  that exposes the active client instance. By exporting this globally, any widget or screen can write  supabase.
from('transactions')...  directly without needing to initialize or pass the client down through the widget tree.
──────
### 2. Application Entry Point: main.dart

This is where the entire Flutter application starts running.

1: import 'package:flutter/material.dart';
2: import 'package:supabase_flutter/supabase_flutter.dart';
3: import 'package:flutter_dotenv/flutter_dotenv.dart';
4: import 'package:dynamic_color/dynamic_color.dart';
5: import 'package:netcalc_app/screens/home_page.dart';

• Line 1: Imports Flutter's standard Material Design widgets (buttons, text fields, layouts).
• Lines 2–4: Import libraries for database operations, reading environmental configurations, and dynamic color palettes.
• Line 5: Imports the home_page.dart screen which acts as the main UI.

#### The  main()  Function

7: Future<void> main() async {
8:   WidgetsFlutterBinding.ensureInitialized();
9:   await dotenv.load(fileName: ".env");
10:
11:   await Supabase.initialize(
12:     url: dotenv.get('SUPABASE_URL'),
13:     anonKey: dotenv.get('SUPABASE_ANON_KEY'),
14:   );
15:
16:   runApp(const MyApp());
17: }

• Line 7: Every Dart program begins execution at  main() .  Future<void>  and  async  denote that this function performs asynchronous setup tasks.
• Line 8: Ensures that the Flutter engine binding is fully ready. This is required before calling any asynchronous initialization code (like loading assets or databases)
in the main method.
• Line 9: Asynchronously loads keys from the project's root  .env  file.
• Lines 11–14: Initializes the database client. It reads the Supabase database URL and anonymous access key from the environment variables.
• Line 16: Invokes  runApp() , which takes the root widget of your application ( MyApp ) and attaches it to the screen.

#### The Root Widget:  MyApp

19: class MyApp extends StatelessWidget {
20:   const MyApp({super.key});
21:
22:   @override
23:   Widget build(BuildContext context) {
24:     return DynamicColorBuilder(
25:       builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
26:         // Fallback colors if the device doesn't support dynamic theming
27:         ColorScheme lightColorScheme;
28:         ColorScheme darkColorScheme;
29:
30:         if (lightDynamic != null && darkDynamic != null) {
31:           lightColorScheme = lightDynamic.harmonized();
32:           darkColorScheme = darkDynamic.harmonized();
33:         } else {
34:           lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light);
35:           darkColorScheme = ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark);
36:         }

• Line 19:  MyApp  is a  StatelessWidget . This means its properties cannot change dynamically over time; it is static layout container code.
• Line 20: The constructor accepts a unique identifier key ( super.key ) for debugging and widget-tree management.
• Line 23: The standard  build  method. It is called by the framework to construct the UI layout.
• Line 24: Wraps the app in a  DynamicColorBuilder , which looks up the wallpaper color scheme on Android devices.
• Lines 27–36: Sets up variables to hold the color schemes. If the device supports dynamic coloring, it harmonizes the device colors. Otherwise, it falls back to a
custom Teal scheme (light and dark mode variations).

38:         return MaterialApp(
39:           title: 'Savings Tracker',
40:           debugShowCheckedModeBanner: false,
41:           themeMode: ThemeMode.system, // Automatically uses device's Light/Dark mode
42:           theme: _buildTheme(lightColorScheme),
43:           darkTheme: _buildTheme(darkColorScheme),
44:           home: const HomePage(),
45:         );
46:       },
47:     );
48:   }

• Line 38: Returns a  MaterialApp  widget, which configures core app behaviors like routing, styling, titles, and localized languages.
• Line 40: Hides the "Debug" banner in the top-right corner of the app screen.
• Line 41: Tells the app to follow the system's preferences (Light/Dark mode) automatically.
• Lines 42–43: Loads custom themes utilizing the helper method defined below.
• Line 44: Specifies that when the app opens, the home page should render the custom  HomePage  widget.

51:   ThemeData _buildTheme(ColorScheme colorScheme) {
52:     return ThemeData(
53:       useMaterial3: true,
54:       colorScheme: colorScheme,
55:       scaffoldBackgroundColor: colorScheme.surface,
56:       cardTheme: CardThemeData(
57:         color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
58:         elevation: 0,
59:         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
60:       ),
61:       inputDecorationTheme: InputDecorationTheme(
62:         filled: true,
63:         fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
64:         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
65:         focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary)),
66:       ),
67:     );
68:   }

• Lines 51–68: A helper method that creates a uniform visual style (ThemeData) for both light and dark modes:
  • Line 53: Opts into Material 3 styling patterns.
  • Line 55: Sets the global background color.
  • Lines 56–60: Customizes Cards to have rounded corners and translucent backgrounds.
  • Lines 61–67: Formats the text entry inputs (filling them with a translucent dark overlay, eliminating default borders, and adding primary-colored borders when
  focused).

──────
### 3. The Entry Input Component: new_entry_form.dart

This form handles entering a description, evaluating mathematical calculations for the amount, and saving transactions.

6: class NewEntryForm extends StatefulWidget {
7:   final double rate;
8:   final VoidCallback onSuccess;
9:   const NewEntryForm({super.key, required this.rate, required this.onSuccess});
10:
11:   @override
12:   State<NewEntryForm> createState() => _NewEntryFormState();
13: }

• Line 6: Unlike  MyApp ,  NewEntryForm  is a  StatefulWidget . This means its state is dynamic and can change in response to user text input, checkbox changes, or
loading states.
• Lines 7–8: This widget requires two inputs from its parent:  rate  (the current USD/EGP exchange rate) and  onSuccess  (a callback function to run when saving finishes,
reloading history).
• Line 12: Creates the mutable state object  _NewEntryFormState .

#### The Form State Class:  _NewEntryFormState

15: class _NewEntryFormState extends State<NewEntryForm> {
16:   final _formKey = GlobalKey<FormState>();
17:   final _descController = TextEditingController();
18:   final _amountController = TextEditingController();
19:   Set<String> _currencySelection = {'USD'};
20:   bool _isSaving = false;

• Line 16: Creates a global key that uniquely identifies the HTML-like  <form>  element. This is used to run validation (e.g., making sure text fields aren't empty).
• Lines 17–18: Controllers manage the text value inside text boxes and allow you to clear or read the input value.
• Line 19: Tracks which currency is selected. It starts with  'USD' .
• Line 20: A boolean flag that shows a loading indicator while a save operation is in progress.

#### Submitting and Saving:  _submitForm()

22:   Future<void> _submitForm() async {
23:     if (_formKey.currentState!.validate()) {
24:       setState(() => _isSaving = true);
25:       try {
26:         final p = ShuntingYardParser();
27:         final exp = p.parse(_amountController.text);
28:         final double amountVal = exp.evaluate(EvaluationType.REAL, ContextModel());

• Line 23: Validates the input form. If validators pass, code execution continues.
• Line 24:  setState  tells Flutter to redraw the widget, updating the saving flag to  true  (making a spinner appear and disabling the button).
• Lines 26–28: This is where mathematical expressions are solved!
  •  ShuntingYardParser  parses a string representation of a mathematical equation (like  "(50 + 20) * 1.5" ).
  •  exp.evaluate()  calculates the actual numerical value ( 105.0 ) dynamically.


30:         double finalAmount = _currencySelection.first == 'EGP' ? amountVal / widget.rate : amountVal;

• Line 30: If the user selected 'EGP', we divide the amount by the exchange rate to convert it to USD. If they selected 'USD', it remains unchanged. The database stores
all base figures in USD.

32:         final dateStr = DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.now());
33:         await supabase.from('transactions').insert({
34:           'description': _descController.text,
35:           'amount': finalAmount,
36:           'rate': widget.rate,
37:           'date': dateStr,
38:         });

• Line 32: Formats the current time into a clean string (e.g.,  Jun 07, 2026 • 16:12 ).
• Lines 33–38: Interacts with the global Supabase client. It inserts a new row into the  transactions  table with the description, calculated amount, current exchange
rate, and date string.

40:         if (mounted) {
41:           _descController.clear();
42:           _amountController.clear();
43:           widget.onSuccess();
44:         }

• Line 40:  mounted  is a safety check to ensure this widget is still visible on the user's screen before updating its layout.
• Lines 41–42: Clears the text fields so the form is ready for a new entry.
• Line 43: Calls the parent screen's success callback, which triggers a reload of the transaction history from Supabase.

45:       } catch (e) {
46:         if (mounted) {
47:           ScaffoldMessenger.of(context).showSnackBar(
48:             const SnackBar(content: Text('Failed to add transaction. Please check your internet connection.')),
50:           );
51:         }
52:       } finally {
53:         if (mounted) setState(() => _isSaving = false);
54:       }
55:     }
56:   }

• Lines 45–51: If there's an error (e.g., network disconnect or invalid math formula syntax), it catches the exception and displays an overlay toast notification
(SnackBar) to the user.
• Line 53: The  finally  block runs regardless of success or failure, resetting  _isSaving  to  false  so the user can interact with the submit button again.

58:   @override
59:   void dispose() {
60:     _descController.dispose();
61:     _amountController.dispose();
62:     super.dispose();
63:   }

• Lines 58–63: The  dispose  method is called when the widget is permanently removed from the widget tree. It cleans up the text controllers to prevent memory leaks.

#### Building the Form UI

65:   @override
66:   Widget build(BuildContext context) {
67:     final colorScheme = Theme.of(context).colorScheme;
68:
69:     return Container(
70:       padding: const EdgeInsets.all(20),
71:       decoration: BoxDecoration(
72:         color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
73:         borderRadius: BorderRadius.circular(24),
74:         border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
75:       ),

• Lines 68–75: Renders a card container styled with curved corners, spacing padding, and a translucent border.

75:       child: Form(
76:         key: _formKey,
77:         child: Column(
78:           children: [
79:             TextFormField(
80:               controller: _descController,
81:               decoration: const InputDecoration(hintText: 'What did you add? (e.g. Salary)'),
82:               validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
83:             ),

• Lines 75–83: An input field where the user enters the transaction description. It has a validation check to ensure the field isn't empty.

84:             const SizedBox(height: 12),
85:             Row(
86:               children: [
87:                 Expanded(
88:                   child: TextFormField(
89:                     controller: _amountController,
90:                     keyboardType: TextInputType.text,
91:                     decoration: const InputDecoration(hintText: 'Amount (100*2)'),
92:                     validator: (value) {
93:                       if (value == null || value.isEmpty) return 'Required';
94:                       try { ShuntingYardParser().parse(value); return null; } catch (e) { return 'Error'; }
95:                     },
96:                   ),
97:                 ),

• Line 87:  Expanded  tells the layout to let this input field take up all available horizontal space in the Row.
• Line 90: Sets  keyboardType  to regular text rather than only numbers, enabling calculations like  + ,  - ,  * ,  / .
• Lines 92–95: Validates the input by attempting to parse it as math. If it fails, it displays  'Error' .

98:                 const SizedBox(width: 12),
99:                 SegmentedButton<String>(
100:                   showSelectedIcon: false,
101:                   segments: const [
102:                     ButtonSegment(value: 'USD', label: Text('USD')),
103:                     ButtonSegment(value: 'EGP', label: Text('EGP')),
104:                   ],
105:                   selected: _currencySelection,
106:                   onSelectionChanged: (s) => setState(() => _currencySelection = s),
107:                 )
108:               ],
109:             ),

• Lines 99–107: A segmented selector button that lets users toggle between USD and EGP currencies. Clicking an option updates  _currencySelection  and updates the UI.

110:             const SizedBox(height: 16),
111:             SizedBox(
112:               width: double.infinity,
113:               height: 50,
114:               child: ElevatedButton(
115:                 onPressed: _isSaving ? null : _submitForm,
116:                 style: ElevatedButton.styleFrom(
117:                   backgroundColor: colorScheme.primary,
118:                   foregroundColor: colorScheme.onPrimary,
119:                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
120:                 ),
121:                 child: _isSaving
122:                   ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
123:                   : const Text('Add to Balance', style: TextStyle(fontWeight: FontWeight.bold)),
124:               ),
125:             )

• Lines 111–125: Displays the submit button.
  • Line 115: If  _isSaving  is true, the button is disabled (set to  null ).
  • Lines 121–123: If saving, it shows a  CircularProgressIndicator  spinner; otherwise, it shows the text "Add to Balance".

──────
### 4. The Core Screen: home_page.dart

This is the central view of the app. It manages fetching backend data, offline storage caching, dynamic layout variations, searching, and exporting.

11: class HomePage extends StatefulWidget {
12:   const HomePage({super.key});
13:
14:   @override
15:   State<HomePage> createState() => _HomePageState();
16: }

• Line 11: Declares the main  HomePage  class as a  StatefulWidget .

#### Core Variables & State

18: class _HomePageState extends State<HomePage> {
19:   bool _isInitialLoading = true;
20:   bool _isBackgroundLoading = false;
21:   double? _rate;
22:   List<dynamic> _transactions = [];
23:   double _totalUsd = 0.0;
24:   String? _error;

• Line 19:  _isInitialLoading  is set to  true  when the app is opening for the very first time and has no cached values to show yet.
• Line 20:  _isBackgroundLoading  is set to  true  during silent updates while the user is already interacting with older/cached database values.
• Line 21: Stores the active exchange conversion rate.
• Line 22: Stores the transaction records list fetched from the database.
• Line 23: Stores the total calculated value of all transactions combined.
• Line 24: Tracks errors (like network disconnects) so they can be shown in the UI.

26:   final _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
27:   final _egpFormat = NumberFormat.currency(locale: 'en_US', symbol: 'EGP ');
28:
29:   final _searchController = TextEditingController();
30:   String _searchQuery = '';
31:
32:   late SharedPreferences _prefs;
33:   bool _prefsInitialized = false;
34:   bool _useManualRate = false;
35:   double _manualRate = 50.0;

• Lines 26–27: Pre-configured currency formatting tools.
• Lines 29–30: Used to control and track the search input field query.
• Lines 32–35: Objects and parameters to configure the local settings and persistent cache ( shared_preferences ).

38:   @override
39:   void initState() {
40:     super.initState();
41:     _fetchInitialData();
42:   }

• Lines 38–42:  initState  is run exactly once when the page is first initialized. It immediately calls  _fetchInitialData()  to fetch the exchange rate and transaction
list.

44:   @override
45:   void dispose() {
46:     _searchController.dispose();
47:     super.dispose();
48:   }

• Lines 44–48: Cleans up resources when the page is destroyed.

#### Search Filtering Logic

49:   List<dynamic> get _filteredTransactions {
50:     if (_searchQuery.isEmpty) return _transactions;
51:     final query = _searchQuery.toLowerCase();
52:     return _transactions.where((trx) {
53:       final desc = (trx['description'] as String?)?.toLowerCase() ?? '';
54:       final date = (trx['date'] as String?)?.toLowerCase() ?? '';
55:       final amount = trx['amount']?.toString() ?? '';
56:       return desc.contains(query) || date.contains(query) || amount.contains(query);
57:     }).toList();
58:   }

• Lines 49–58: A custom getter that filters the transactions list dynamically. If a search query is entered, it filters list results down to entries containing that
search query in the description, date, or amount fields.

#### Searching Widget Builder

60:   Widget _buildSearchBar(ColorScheme colorScheme) {
61:     return TextField(
...
68:       decoration: InputDecoration(
69:         hintText: 'Search history...',
70:         prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
71:         suffixIcon: _searchQuery.isNotEmpty
72:             ? IconButton(
73:                 icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
74:                 onPressed: () {
75:                   _searchController.clear();
76:                   setState(() {
77:                     _searchQuery = '';
78:                   });
79:                 },
80:               )
81:             : null,
...
85:     );
86:   }

• Lines 60–86: Renders the search text input.
  • Line 71: If search text is present, a "Clear" ( X ) button is shown in the text field. Pressing this button resets the search input.


#### Exchange Rate Settings Dialog

87:   void _showExchangeRateDialog() {
...
92:     showDialog(
...
97:             return AlertDialog(
98:               title: const Text('Exchange Rate Settings'),
99:               content: Column(
...
103:                   SegmentedButton<bool>(
104:                     showSelectedIcon: false,
105:                     segments: const [
106:                       ButtonSegment(value: false, label: Text('Auto (API)')),
107:                       ButtonSegment(value: true, label: Text('Manual')),
108:                     ],
109:                     selected: {useManual},
110:                     onSelectionChanged: (s) {
111:                       setDialogState(() {
112:                         useManual = s.first;
113:                       });
114:                     },
115:                   ),
...

• Lines 87–169: Renders an alert dialog that allows users to override the conversion rate.
  • Lines 103–115: A segmented selector to switch between API exchange rates and manual override settings.
  • Lines 142–162: When the user clicks Save, it writes the configurations (manual rate value and manual mode setting) to  shared_preferences  local storage and re-
  fetches the transactions.


#### CSV Exporter

171:   void _exportToCsv() {
172:     try {
173:       final buffer = StringBuffer();
174:       buffer.writeln('Date,Description,Amount (USD),Exchange Rate');
175:       for (final trx in _transactions) {
...
183:         buffer.writeln('date,desc,amount,rate');
184:       }
185:
186:       Clipboard.setData(ClipboardData(text: buffer.toString()));
187:
188:       ScaffoldMessenger.of(context).showSnackBar(
189:         const SnackBar(content: Text('Calculation history copied to clipboard as CSV!')),
190:       );
...

• Lines 171–196: Formats the local transactions list into CSV format (comma-separated values).
  • Line 186: Copies the text payload to the user's OS clipboard.
  • Line 188: Shows a toast popup confirming it was copied.


#### Fetching & Caching:  _fetchInitialData()

This method loads cached data instantly to display the screen immediately, then loads remote values in the background to ensure data consistency.

198:   Future<void> _fetchInitialData() async {
199:     if (!mounted) return;
200:
201:     if (!_prefsInitialized) {
202:       try {
203:         _prefs = await SharedPreferences.getInstance();
204:         _useManualRate = _prefs.getBool('use_manual_rate') ?? false;
205:         _manualRate = _prefs.getDouble('manual_rate') ?? 50.0;
206:
207:         final cachedJson = _prefs.getString('cached_transactions');
208:         if (cachedJson != null) {
209:           final List<dynamic> cachedList = jsonDecode(cachedJson);
210:           setState(() {
211:             _transactions = cachedList;
212:             _totalUsd = _calculateTotalUsd(cachedList);
213:             _isInitialLoading = false;
214:           });
215:         }
216:         _prefsInitialized = true;
217:       } catch (_) {}
218:     }

• Lines 201–218: First run checks:
  • Instantiates local shared preferences storage.
  • Reads previously saved manual exchange rate preferences.
  • Decodes cached JSON transaction histories. If found, it displays them immediately to eliminate loading states for offline users.


220:     setState(() {
221:       if (_transactions.isEmpty) {
222:         _isInitialLoading = true;
223:       }
224:       _isBackgroundLoading = true;
225:       _error = null;
226:     });

• Lines 220–226: Starts background queries. If there's no cache, it shows a full-screen loading spinner.

228:     try {
229:       final results = await Future.wait([_getExchangeRate(), _loadTransactions()]);
230:       final double rate = results[0] as double;
231:       final List<dynamic> transactions = results[1] as List<dynamic>;
232:
233:       if (_prefsInitialized) {
234:         await _prefs.setString('cached_transactions', jsonEncode(transactions));
235:       }
236:
237:       if (!mounted) return;
238:       setState(() {
239:         _rate = _useManualRate ? _manualRate : rate;
240:         _transactions = transactions;
241:         _totalUsd = _calculateTotalUsd(transactions);
242:         _isInitialLoading = false;
243:         _isBackgroundLoading = false;
244:       });

• Line 229:  Future.wait  fires two requests concurrently: fetching exchange rates from the API and fetching transaction logs from Supabase.
• Line 234: Caches the updated transaction records back to local storage.
• Lines 238–244: Updates the screen with the fetched values.

245:     } catch (e) {
246:       if (!mounted) return;
247:       setState(() {
248:         _rate = _useManualRate ? _manualRate : (_rate ?? 50.0);
249:         _error = _transactions.isNotEmpty
250:             ? "Offline mode. Showing cached data."
251:             : "Connection issue. Pull to retry.";
252:         _isInitialLoading = false;
253:         _isBackgroundLoading = false;
254:       });
255:     }
256:   }

• Lines 245–255: If offline or blocked by a firewall, it catches the error and presents a message while letting the user view their cached data.

#### Fetching Rates:  _getExchangeRate()

258:   Future<double> _getExchangeRate() async {
259:     final apiKey = dotenv.get('EXCHANGE_RATE_API_KEY', fallback: 'FREE');
260:     if (apiKey == 'FREE') return 50.0;
261:
262:     try {
263:       final response = await http.get(Uri.parse('https://v6.exchangerate-api.com/v6/$apiKey/latest/USD'));
264:       if (response.statusCode == 200) {
265:         return (jsonDecode(response.body)['conversion_rates']['EGP'] as num).toDouble();
266:       }
267:     } catch (_) {}
268:     return 50.0;
269:   }

• Line 259: Loads the API key from environment variables. If it is set to  'FREE' , it returns a default rate of  50.0 .
• Lines 262–266: Makes an HTTP GET request to retrieve the conversion rate. If the response is successful, it returns the conversion rate for EGP.

#### Database Operations: Deleting and Loading

271:   Future<void> _deleteEntry(int id) async {
272:     setState(() {
273:       _transactions.removeWhere((t) => t['id'] == id);
274:       _totalUsd = _calculateTotalUsd(_transactions);
275:     });
276:
277:     try {
278:       await supabase.from('transactions').delete().eq('id', id);
279:       if (_prefsInitialized) {
280:         await _prefs.setString('cached_transactions', jsonEncode(_transactions));
281:       }
282:     } catch (e) {
283:       _fetchInitialData();
284:     }
285:   }

• Lines 271–285: Deletes a transaction from the database.
  • Lines 272–275: Updates the local state immediately (optimistic UI update) so the app feels fast.
  • Line 278: Sends the delete request to Supabase.


287:   Future<List<dynamic>> _loadTransactions() async {
288:     return await supabase.from('transactions').select().order('created_at', ascending: false);
289:   }

• Lines 287–289: Fetches transaction records from Supabase, ordered with the newest entries first.

291:   double _calculateTotalUsd(List<dynamic> transactions) {
292:     return transactions.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
293:   }

• Lines 291–293: Calculates the total savings in USD by summing the transaction amounts.

#### Responsive UI Layout Build

296:   @override
297:   Widget build(BuildContext context) {
298:     final colorScheme = Theme.of(context).colorScheme;
299:     final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

• Line 299: Detects the screen orientation to adapt the layout.

300:     if (_isInitialLoading) {
301:       return Scaffold(
302:         body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
303:       );
304:     }

• Lines 300–304: Renders a full-screen loading spinner if the app is launching for the first time with no cached data.

306:     if (isLandscape) {
307:       return Scaffold(
308:         body: SafeArea(
309:           child: Row(
310:             crossAxisAlignment: CrossAxisAlignment.start,
311:             children: [
312:               Expanded(
313:                 flex: 5,
314:                 child: SingleChildScrollView(
...
324:                       _buildSummaryCard(colorScheme),
325:                       const SizedBox(height: 24),
326:                       NewEntryForm(rate: _rate ?? 50.0, onSuccess: _fetchInitialData),
...
332:               Expanded(
333:                 flex: 6,
334:                 child: RefreshIndicator(
335:                   onRefresh: _fetchInitialData,
...
337:                   child: CustomScrollView(
...
374:                       _buildTransactionList(colorScheme),
...

• Lines 306–384: Landscape Layout. It renders a side-by-side view with a form on the left ( flex: 5 ) and the transaction list on the right ( flex: 6 ).

386:     return Scaffold(
387:       body: RefreshIndicator(
388:         onRefresh: _fetchInitialData,
...
391:         child: CustomScrollView(
392:           physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
393:           slivers: [
394:             _buildAppBar(colorScheme),
395:             SliverToBoxAdapter(
396:               child: Padding(
...
406:                     NewEntryForm(rate: _rate ?? 50.0, onSuccess: _fetchInitialData),
407:                     const SizedBox(height: 24),
...
437:             _buildTransactionList(colorScheme),
438:           ],
439:         ),
440:       ),
441:     );
442:   }

• Lines 386–442: Portrait Layout. Displays items vertically:
  • Line 387: Wraps content in a  RefreshIndicator  to support pull-to-refresh.
  • Line 391: Uses a  CustomScrollView  with custom scrolling effects (slivers).
  • Line 394: Displays a collapsible app bar.
  • Line 406: Renders the entry form input.
  • Line 437: Lists the transaction history.


#### Summary Widgets

444:   Widget _buildSummaryContent(ColorScheme colorScheme) {
445:     final totalEgp = _totalUsd * (_rate ?? 50.0);
446:     return Column(
447:       mainAxisAlignment: MainAxisAlignment.center,
448:       children: [
449:         Text('Total Savings', style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 16)),
450:         const SizedBox(height: 8),
451:         FittedBox(
452:           fit: BoxFit.scaleDown,
453:           child: Text(_usdFormat.format(_totalUsd), style: TextStyle(color: colorScheme.onSurface, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1)),
454:         ),
455:         Text(_egpFormat.format(totalEgp), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 18)),
...

• Lines 444–478: Formats and displays total savings in USD and EGP, along with a link to open the rate settings dialog.

480:   Widget _buildSummaryCard(ColorScheme colorScheme) {
...
496:   Widget _buildAppBar(ColorScheme colorScheme) {
...

• Lines 480–518: Adapts the summary display based on orientation (card vs collapsible header).

#### Transaction List Builder

521:   Widget _buildTransactionList(ColorScheme colorScheme) {
522:     if (_transactions.isEmpty) {
523:       return SliverFillRemaining(
524:         hasScrollBody: false,
525:         child: Center(child: Text("No transactions yet", style: TextStyle(color: colorScheme.onSurfaceVariant))),
526:       );
527:     }
...

• Lines 521–551: Handles empty states when there are no transactions or no search matches are found.

553:     return SliverPadding(
554:       padding: const EdgeInsets.symmetric(horizontal: 16),
555:       sliver: SliverList(
556:         delegate: SliverChildBuilderDelegate(
557:           (context, index) {
558:             final trx = filtered[index];
559:             return Padding(
560:               padding: const EdgeInsets.only(bottom: 8.0),
561:               child: Dismissible(
562:                 key: ValueKey(trx['id']),
563:                 direction: DismissDirection.endToStart,
564:                 confirmDismiss: (direction) async {
565:                   return await showDialog(
566:                     context: context,
567:                     builder: (context) => AlertDialog(
568:                       title: const Text('Delete Entry'),
569:                       content: const Text('Are you sure you want to delete this entry?'),
...
586:                 onDismissed: (_) => _deleteEntry(trx['id'] as int),
587:                 background: Container(
588:                   decoration: BoxDecoration(color: colorScheme.error, borderRadius: BorderRadius.circular(16)),
589:                   alignment: Alignment.centerRight,
590:                   padding: const EdgeInsets.only(right: 20),
591:                   child: Icon(Icons.delete_outline, color: colorScheme.onError),
592:                 ),
593:                 child: Card(
594:                   child: ListTile(
595:                     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
596:                     title: Text(trx['description'], style: const TextStyle(fontWeight: FontWeight.w600)),
597:                     subtitle: Text(
598:                       '${trx['date']}  •  @ ${(trx['rate'] as num?)?.toStringAsFixed(2) ?? '50.00'} EGP',
599:                       style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
600:                     ),
601:                     trailing: Text(
602:                       _usdFormat.format(trx['amount']),
603:                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)
604:                     ),
...

• Lines 553–614: Renders the dynamic transaction list.
  • Line 561: Wraps each item in a  Dismissible  widget to support swipe-to-delete.
  • Lines 564–585: Shows a confirmation dialog when a user swipes to delete an item.
  • Lines 593–606: Displays the transaction card with its description, timestamp, rate, and amount.
