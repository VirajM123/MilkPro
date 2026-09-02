import 'package:flutter/material.dart';

import '../../providers/customer_provider.dart';
import '../common/simple_screen_widgets.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  String? _customer;

  @override
  void initState() {
    super.initState();
    if (CustomerStore.customers.isNotEmpty) {
      _customer = CustomerStore.customers.first.name;
    }
  }

  double get _balance {
    for (final customer in CustomerStore.customers) {
      if (customer.name == _customer) return customer.balance;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final names = CustomerStore.customers.map((item) => item.name).toList();
    return SimpleModuleScaffold(
      title: 'Ledger',
      subtitle: 'View a simple debit and credit history for each customer.',
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: _customer,
          decoration: simpleInput('Customer', Icons.person_outline),
          items: names
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
          onChanged: (value) => setState(() => _customer = value),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            const SimpleStat(
              label: 'Total sales',
              value: '₹4,850',
              icon: Icons.shopping_cart_outlined,
              color: modulePrimary,
            ),
            const SizedBox(width: 10),
            SimpleStat(
              label: 'Balance due',
              value: '₹${_balance.toStringAsFixed(0)}',
              icon: Icons.schedule_rounded,
              color: moduleOrange,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Transactions',
          style: TextStyle(
            color: moduleDark,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        _entry('Milk sale', '20 Aug 2026', 1450, true),
        _entry('Payment received', '19 Aug 2026', 1000, false),
        _entry('Milk sale', '19 Aug 2026', 800, true),
      ],
    );
  }

  Widget _entry(String title, String date, double amount, bool debit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SimpleSection(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: debit
                    ? const Color(0xFFFFF3E8)
                    : const Color(0xFFEAF8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                debit ? Icons.north_east_rounded : Icons.south_west_rounded,
                color: debit ? moduleOrange : moduleGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: moduleDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: moduleMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
            Text(
              '${debit ? '+' : '-'} ₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: debit ? moduleOrange : moduleGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
