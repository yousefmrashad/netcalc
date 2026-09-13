import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:netcalc_app/services/data_repository.dart';

class NewEntryForm extends StatefulWidget {
  final double rate;
  final VoidCallback onSuccess;
  const NewEntryForm({super.key, required this.rate, required this.onSuccess});

  @override
  State<NewEntryForm> createState() => _NewEntryFormState();
}

class _NewEntryFormState extends State<NewEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  Set<String> _currencySelection = {'USD'};
  DateTime? _selectedDateTime;
  bool _isSaving = false;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _selectedDateTime ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return;
    if (!mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final p = ShuntingYardParser();
        final exp = p.parse(_amountController.text);
        final double amountVal = exp.evaluate(
          EvaluationType.REAL,
          ContextModel(),
        );

        double finalAmount = _currencySelection.first == 'EGP'
            ? amountVal / widget.rate
            : amountVal;

        final targetDate = _selectedDateTime ?? DateTime.now();
        final dateStr = DateFormat(
          'MMM dd, yyyy • HH:mm',
        ).format(targetDate);

        await DataRepository.instance.insert({
          'description': _descController.text,
          'amount': finalAmount,
          'rate': widget.rate,
          'date': dateStr,
        });

        if (mounted) {
          _descController.clear();
          _amountController.clear();
          setState(() {
            _selectedDateTime = null;
          });
          widget.onSuccess();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to add transaction. Please check your internet connection.',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'What did you add? (e.g. Salary)',
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      hintText: 'Amount (100*2)',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      try {
                        ShuntingYardParser().parse(value);
                        return null;
                      } catch (e) {
                        return 'Error';
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'USD', label: Text('USD')),
                    ButtonSegment(value: 'EGP', label: Text('EGP')),
                  ],
                  selected: _currencySelection,
                  onSelectionChanged: (s) =>
                      setState(() => _currencySelection = s),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: _selectedDateTime != null
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedDateTime == null
                            ? 'Date & Time: Now (Default)'
                            : DateFormat(
                                'MMM dd, yyyy • HH:mm',
                              ).format(_selectedDateTime!),
                        style: TextStyle(
                          color: _selectedDateTime != null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: _selectedDateTime != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_selectedDateTime != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            setState(() => _selectedDateTime = null),
                        tooltip: 'Reset to Now',
                      )
                    else
                      Text(
                        'Tap to change',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Text(
                        'Add to Balance',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
