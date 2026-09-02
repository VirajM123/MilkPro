import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/customer_provider.dart';
import '../../widgets/app_widgets.dart';
import '../common/simple_screen_widgets.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final List<_PaymentEntry> _payments = <_PaymentEntry>[];
  String? _customer;
  String _mode = 'Cash';

  @override
  void initState() {
    super.initState();
    if (CustomerStore.customers.isNotEmpty) {
      _customer = CustomerStore.customers.first.name;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  double get _total => _payments.fold(0, (sum, item) => sum + item.amount);

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false) || _customer == null) {
      return;
    }
    setState(() {
      _payments.insert(
        0,
        _PaymentEntry(
          customer: _customer!,
          amount: double.parse(_amountController.text),
          mode: _mode,
          reference: _referenceController.text.trim(),
        ),
      );
      _amountController.clear();
      _referenceController.clear();
    });
    showSavedMessage(context, 'Payment recorded successfully.');
  }

  @override
  Widget build(BuildContext context) {
    final names = CustomerStore.customers.map((item) => item.name).toList();
    return SimpleModuleScaffold(
      title: 'Payments',
      subtitle: 'Record customer receipts with only the essential details.',
      children: <Widget>[
        Row(
          children: <Widget>[
            SimpleStat(
              label: 'Received today',
              value: '₹${_total.toStringAsFixed(0)}',
              icon: Icons.south_west_rounded,
              color: moduleGreen,
            ),
            const SizedBox(width: 10),
            SimpleStat(
              label: 'Transactions',
              value: '${_payments.length}',
              icon: Icons.receipt_long_outlined,
              color: modulePrimary,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SimpleSection(
          title: 'Receive payment',
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _customer,
                  decoration: simpleInput('Customer', Icons.person_outline),
                  items: names
                      .map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      )
                      .toList(),
                  onChanged: (value) => _customer = value,
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
                  decoration: simpleInput(
                    'Payment mode',
                    Icons.payments_outlined,
                  ),
                  items:
                      const <String>['Cash', 'UPI', 'Bank Transfer', 'Cheque']
                          .map(
                            (mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => _mode = value ?? _mode,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: _referenceController,
                  decoration: simpleInput(
                    'Reference (optional)',
                    Icons.tag_rounded,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Payment'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Recent payments',
          style: TextStyle(
            color: moduleDark,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        if (_payments.isEmpty)
          const Card(
            child: AppEmptyState(
              icon: Icons.payments_outlined,
              title: 'No Payments',
              message: 'Recorded customer payments will appear here.',
            ),
          )
        else
          ..._payments.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SimpleSection(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.check_circle_rounded, color: moduleGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.customer,
                            style: const TextStyle(
                              color: moduleDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            item.reference.isEmpty
                                ? item.mode
                                : '${item.mode} • ${item.reference}',
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
                        color: moduleGreen,
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

class _PaymentEntry {
  const _PaymentEntry({
    required this.customer,
    required this.amount,
    required this.mode,
    required this.reference,
  });
  final String customer;
  final double amount;
  final String mode;
  final String reference;
}
