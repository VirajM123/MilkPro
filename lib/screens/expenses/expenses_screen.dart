import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/app_widgets.dart';
import '../common/simple_screen_widgets.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final List<_ExpenseEntry> _expenses = <_ExpenseEntry>[];
  String _category = 'Fuel';
  String _mode = 'Cash';

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _total => _expenses.fold(0, (sum, item) => sum + item.amount);

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _expenses.insert(
        0,
        _ExpenseEntry(
          category: _category,
          amount: double.parse(_amountController.text),
          mode: _mode,
          note: _noteController.text.trim(),
        ),
      );
      _amountController.clear();
      _noteController.clear();
    });
    showSavedMessage(context, 'Expense added successfully.');
  }

  @override
  Widget build(BuildContext context) {
    return SimpleModuleScaffold(
      title: 'Expenses',
      subtitle: 'Record daily distribution expenses in a few quick fields.',
      children: <Widget>[
        Row(
          children: <Widget>[
            SimpleStat(
              label: 'Today',
              value: '₹${_total.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet_outlined,
              color: moduleOrange,
            ),
            const SizedBox(width: 10),
            SimpleStat(
              label: 'This Month',
              value: '₹${_total.toStringAsFixed(0)}',
              icon: Icons.calendar_month_outlined,
              color: modulePrimary,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SimpleSection(
          title: 'Add expense',
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: simpleInput('Category', Icons.category_outlined),
                  items:
                      const <String>[
                            'Fuel',
                            'Vehicle',
                            'Loading',
                            'Food',
                            'Other',
                          ]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => _category = value ?? _category,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: simpleInput(
                    'Amount',
                    Icons.currency_rupee_rounded,
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    return amount == null || amount <= 0
                        ? 'Enter amount'
                        : null;
                  },
                ),
                const SizedBox(height: 11),
                DropdownButtonFormField<String>(
                  initialValue: _mode,
                  decoration: simpleInput('Paid by', Icons.payments_outlined),
                  items: const <String>['Cash', 'UPI', 'Bank']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) => _mode = value ?? _mode,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: simpleInput(
                    'Note (optional)',
                    Icons.notes_rounded,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Expense'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Recent expenses',
          style: TextStyle(
            color: moduleDark,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        if (_expenses.isEmpty)
          const Card(
            child: AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Expenses',
              message: 'New expense entries will appear here.',
            ),
          )
        else
          ..._expenses.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SimpleSection(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: moduleOrange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.category,
                            style: const TextStyle(
                              color: moduleDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            item.note.isEmpty
                                ? item.mode
                                : '${item.mode} • ${item.note}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: moduleMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${item.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: moduleOrange,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ExpenseEntry {
  const _ExpenseEntry({
    required this.category,
    required this.amount,
    required this.mode,
    required this.note,
  });
  final String category;
  final double amount;
  final String mode;
  final String note;
}
