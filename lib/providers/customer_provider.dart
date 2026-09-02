import '../models/customer_model.dart';

class CustomerStore {
  CustomerStore._();

  static final List<CustomerModel> customers = <CustomerModel>[
    const CustomerModel(
      name: 'Anita Patil',
      mobile: '9876543210',
      route: 'Route A',
      balance: 1250,
    ),
    const CustomerModel(
      name: 'Rahul Stores',
      mobile: '9822012345',
      route: 'Route A',
      balance: 760,
    ),
    const CustomerModel(
      name: 'Shree Cafe',
      mobile: '9765432108',
      route: 'Route B',
      balance: 2100,
    ),
  ];

  static void add(CustomerModel customer) => customers.insert(0, customer);
}
