import '../models/report_model.dart';

abstract final class ReportDemoProvider {
  static ReportData forReport(String title, String description) {
    final content = switch (title) {
      'Current Stock' => _currentStock,
      'Low Stock' => _lowStock,
      'Stock Movement' => _stockMovement,
      'Product-wise Stock' => _productStock,
      'Sales Trend' => _salesTrend,
      'Purchase Trend' => _purchaseTrend,
      'Sales vs Purchase' => _salesVsPurchase,
      'Product Trend' => _productTrend,
      'Salesman-wise Outstanding' => _salesmanOutstanding,
      'Customer / Outlet-wise Outstanding' => _customerOutstanding,
      'Route-wise Outstanding' => _routeOutstanding,
      'Outstanding Ageing' => _outstandingAgeing,
      'Salesman-wise Sales' => _salesmanSales,
      'Customer-wise Sales' => _customerSales,
      'Route-wise Sales' => _routeSales,
      'Product-wise Sales' => _productSales,
      'Date-wise Sales' => _dateSales,
      'Purchase Register' => _purchaseRegister,
      'Supplier-wise Purchase' => _supplierPurchase,
      'Product-wise Purchase' => _productPurchase,
      'Purchase Payment Due' => _purchaseDue,
      'Collection Report' => _collection,
      'Allocation Report' => _allocation,
      'Return Report' => _returns,
      'Expense Report' => _expenses,
      _ => _currentStock,
    };

    return ReportData(
      title: title,
      description: description,
      columns: content.columns,
      rows: content.rows,
      metrics: content.metrics,
    );
  }

  static const _currentStock = _ReportContent(
    columns: [
      'Product',
      'Variant',
      'Category',
      'Stock',
      'Unit',
      'Rate',
      'Value',
    ],
    rows: [
      ['Full Cream Milk', '500 ml pouch', 'Milk', 120, 'Ltr', 32, 3840],
      ['Toned Milk', '500 ml pouch', 'Milk', 95, 'Ltr', 28, 2660],
      ['Buffalo Milk', '500 ml pouch', 'Milk', 80, 'Ltr', 38, 3040],
      ['Ghee', '200 ml jar', 'Dairy', 40, 'Pcs', 180, 7200],
      ['Curd', '200 gm cup', 'Dairy', 60, 'Pcs', 25, 1500],
    ],
    metrics: [
      ReportMetric('Products', '5'),
      ReportMetric('Stock Units', '395'),
      ReportMetric('Stock Value', 'Rs. 18,240'),
    ],
  );

  static const _lowStock = _ReportContent(
    columns: [
      'Product',
      'Current Stock',
      'Minimum Level',
      'Shortage',
      'Unit',
      'Status',
    ],
    rows: [
      ['Ghee', 18, 25, 7, 'Pcs', 'Reorder'],
      ['Curd', 14, 20, 6, 'Pcs', 'Reorder'],
      ['Paneer', 9, 20, 11, 'Pcs', 'Critical'],
      ['Buttermilk', 16, 25, 9, 'Ltr', 'Reorder'],
    ],
    metrics: [
      ReportMetric('Low Stock Items', '4'),
      ReportMetric('Critical', '1'),
      ReportMetric('Total Shortage', '33 units'),
    ],
  );

  static const _stockMovement = _ReportContent(
    columns: [
      'Product',
      'Opening',
      'Inward',
      'Sales',
      'Returns',
      'Closing',
      'Unit',
    ],
    rows: [
      ['Full Cream Milk', 105, 60, 48, 3, 120, 'Ltr'],
      ['Toned Milk', 88, 45, 40, 2, 95, 'Ltr'],
      ['Buffalo Milk', 72, 35, 29, 2, 80, 'Ltr'],
      ['Ghee', 35, 12, 8, 1, 40, 'Pcs'],
      ['Curd', 54, 30, 26, 2, 60, 'Pcs'],
    ],
    metrics: [
      ReportMetric('Opening', '354'),
      ReportMetric('Inward', '182'),
      ReportMetric('Closing', '395'),
    ],
  );

  static const _productStock = _ReportContent(
    columns: [
      'Product',
      'Variants',
      'Milk Stock',
      'Piece Stock',
      'Stock Value',
      'Share',
    ],
    rows: [
      ['Full Cream Milk', 2, 120, 0, 3840, '21.1%'],
      ['Toned Milk', 2, 95, 0, 2660, '14.6%'],
      ['Buffalo Milk', 1, 80, 0, 3040, '16.7%'],
      ['Ghee', 3, 0, 40, 7200, '39.5%'],
      ['Curd', 2, 0, 60, 1500, '8.2%'],
    ],
    metrics: [
      ReportMetric('Milk Stock', '295 Ltr'),
      ReportMetric('Piece Stock', '100 Pcs'),
      ReportMetric('Value', 'Rs. 18,240'),
    ],
  );

  static const _salesTrend = _ReportContent(
    columns: [
      'Period',
      'Invoices',
      'Quantity',
      'Sales Value',
      'Collections',
      'Growth',
    ],
    rows: [
      ['Week 1', 42, 560, 32800, 28600, '+4.2%'],
      ['Week 2', 48, 624, 36950, 32100, '+12.7%'],
      ['Week 3', 45, 598, 35200, 31750, '-4.7%'],
      ['Week 4', 56, 712, 42850, 38900, '+21.7%'],
    ],
    metrics: [
      ReportMetric('Total Sales', 'Rs. 1,47,800'),
      ReportMetric('Invoices', '191'),
      ReportMetric('Growth', '+10.8%'),
    ],
  );

  static const _purchaseTrend = _ReportContent(
    columns: [
      'Period',
      'Invoices',
      'Quantity',
      'Purchase Value',
      'Paid',
      'Variance',
    ],
    rows: [
      ['Week 1', 8, 680, 24500, 21000, '-2.0%'],
      ['Week 2', 10, 760, 27800, 24000, '+13.5%'],
      ['Week 3', 9, 710, 25900, 22500, '-6.8%'],
      ['Week 4', 11, 840, 31200, 27600, '+20.5%'],
    ],
    metrics: [
      ReportMetric('Purchase Value', 'Rs. 1,09,400'),
      ReportMetric('Invoices', '38'),
      ReportMetric('Quantity', '2,990'),
    ],
  );

  static const _salesVsPurchase = _ReportContent(
    columns: [
      'Period',
      'Sales',
      'Purchase',
      'Gross Difference',
      'Sales Qty',
      'Purchase Qty',
    ],
    rows: [
      ['Week 1', 32800, 24500, 8300, 560, 680],
      ['Week 2', 36950, 27800, 9150, 624, 760],
      ['Week 3', 35200, 25900, 9300, 598, 710],
      ['Week 4', 42850, 31200, 11650, 712, 840],
    ],
    metrics: [
      ReportMetric('Sales', 'Rs. 1,47,800'),
      ReportMetric('Purchase', 'Rs. 1,09,400'),
      ReportMetric('Difference', 'Rs. 38,400'),
    ],
  );

  static const _productTrend = _ReportContent(
    columns: [
      'Product',
      'Previous Qty',
      'Current Qty',
      'Change',
      'Revenue',
      'Trend',
    ],
    rows: [
      ['Full Cream Milk', 520, 594, '+14.2%', 19008, 'Growing'],
      ['Toned Milk', 465, 498, '+7.1%', 13944, 'Growing'],
      ['Buffalo Milk', 310, 294, '-5.2%', 11172, 'Declining'],
      ['Curd', 220, 268, '+21.8%', 6700, 'Growing'],
      ['Ghee', 82, 88, '+7.3%', 15840, 'Stable'],
    ],
    metrics: [
      ReportMetric('Top Product', 'Full Cream Milk'),
      ReportMetric('Fastest Growth', 'Curd +21.8%'),
      ReportMetric('Needs Attention', 'Buffalo Milk'),
    ],
  );

  static const _salesmanOutstanding = _ReportContent(
    columns: [
      'Salesman',
      'Route',
      'Customers',
      'Total Billed',
      'Collected',
      'Outstanding',
    ],
    rows: [
      ['Mahesh Patil', 'Route A', 18, 48250, 40100, 8150],
      ['Suresh Jadhav', 'Route B', 15, 39750, 34600, 5150],
      ['Ravi More', 'Route C', 12, 32100, 28800, 3300],
      ['Amit Shinde', 'Route D', 10, 27700, 25200, 2500],
    ],
    metrics: [
      ReportMetric('Outstanding', 'Rs. 19,100'),
      ReportMetric('Customers', '55'),
      ReportMetric('Collection Rate', '87.1%'),
    ],
  );

  static const _customerOutstanding = _ReportContent(
    columns: [
      'Customer',
      'Mobile',
      'Route',
      'Last Bill',
      'Due Date',
      'Outstanding',
    ],
    rows: [
      [
        'Anita Patil',
        '9876543210',
        'Route A',
        '28/08/2026',
        '04/09/2026',
        1250,
      ],
      [
        'Rahul Stores',
        '9822012345',
        'Route A',
        '30/08/2026',
        '06/09/2026',
        760,
      ],
      ['Shree Cafe', '9765432108', 'Route B', '31/08/2026', '07/09/2026', 2100],
      [
        'Fresh Farms',
        '9890123456',
        'Route C',
        '01/09/2026',
        '08/09/2026',
        1680,
      ],
      ['Sai Dairy', '9881123456', 'Route D', '01/09/2026', '08/09/2026', 940],
    ],
    metrics: [
      ReportMetric('Customers Due', '5'),
      ReportMetric('Outstanding', 'Rs. 6,730'),
      ReportMetric('Overdue', 'Rs. 2,010'),
    ],
  );

  static const _routeOutstanding = _ReportContent(
    columns: [
      'Route',
      'Customers',
      'Billed',
      'Collected',
      'Outstanding',
      'Collection %',
    ],
    rows: [
      ['Route A', 20, 54000, 47200, 6800, '87.4%'],
      ['Route B', 17, 46200, 40150, 6050, '86.9%'],
      ['Route C', 14, 35800, 31900, 3900, '89.1%'],
      ['Route D', 11, 29600, 27250, 2350, '92.1%'],
    ],
    metrics: [
      ReportMetric('Routes', '4'),
      ReportMetric('Outstanding', 'Rs. 19,100'),
      ReportMetric('Best Route', 'Route D'),
    ],
  );

  static const _outstandingAgeing = _ReportContent(
    columns: [
      'Age Bucket',
      'Customers',
      'Invoice Count',
      'Amount',
      'Share',
      'Priority',
    ],
    rows: [
      ['Current', 18, 26, 10400, '54.5%', 'Normal'],
      ['1-7 Days', 9, 12, 4850, '25.4%', 'Follow up'],
      ['8-15 Days', 5, 7, 2450, '12.8%', 'High'],
      ['16-30 Days', 3, 4, 950, '5.0%', 'Urgent'],
      ['Above 30 Days', 2, 2, 450, '2.4%', 'Critical'],
    ],
    metrics: [
      ReportMetric('Total Due', 'Rs. 19,100'),
      ReportMetric('Over 15 Days', 'Rs. 1,400'),
      ReportMetric('Accounts', '37'),
    ],
  );

  static const _salesmanSales = _ReportContent(
    columns: [
      'Salesman',
      'Route',
      'Invoices',
      'Quantity',
      'Sales Value',
      'Average Bill',
    ],
    rows: [
      ['Mahesh Patil', 'Route A', 58, 742, 48250, 832],
      ['Suresh Jadhav', 'Route B', 49, 628, 39750, 811],
      ['Ravi More', 'Route C', 44, 568, 32100, 730],
      ['Amit Shinde', 'Route D', 40, 556, 27700, 693],
    ],
    metrics: [
      ReportMetric('Sales', 'Rs. 1,47,800'),
      ReportMetric('Top Salesman', 'Mahesh Patil'),
      ReportMetric('Quantity', '2,494'),
    ],
  );

  static const _customerSales = _ReportContent(
    columns: [
      'Customer',
      'Route',
      'Invoices',
      'Quantity',
      'Sales Value',
      'Last Purchase',
    ],
    rows: [
      ['Anita Patil', 'Route A', 12, 148, 8950, '01/09/2026'],
      ['Rahul Stores', 'Route A', 15, 210, 12400, '02/09/2026'],
      ['Shree Cafe', 'Route B', 14, 188, 11350, '02/09/2026'],
      ['Fresh Farms', 'Route C', 11, 164, 9780, '01/09/2026'],
      ['Sai Dairy', 'Route D', 9, 126, 7420, '31/08/2026'],
    ],
    metrics: [
      ReportMetric('Active Customers', '5'),
      ReportMetric('Sales', 'Rs. 49,900'),
      ReportMetric('Top Customer', 'Rahul Stores'),
    ],
  );

  static const _routeSales = _ReportContent(
    columns: [
      'Route',
      'Customers',
      'Invoices',
      'Quantity',
      'Sales Value',
      'Contribution',
    ],
    rows: [
      ['Route A', 20, 62, 790, 51000, '34.5%'],
      ['Route B', 17, 51, 654, 41200, '27.9%'],
      ['Route C', 14, 43, 560, 32600, '22.1%'],
      ['Route D', 11, 35, 490, 23000, '15.6%'],
    ],
    metrics: [
      ReportMetric('Routes', '4'),
      ReportMetric('Sales', 'Rs. 1,47,800'),
      ReportMetric('Top Route', 'Route A'),
    ],
  );

  static const _productSales = _ReportContent(
    columns: [
      'Product',
      'Unit',
      'Quantity',
      'Average Rate',
      'Sales Value',
      'Contribution',
    ],
    rows: [
      ['Full Cream Milk', 'Ltr', 594, 32, 19008, '27.1%'],
      ['Toned Milk', 'Ltr', 498, 28, 13944, '19.9%'],
      ['Buffalo Milk', 'Ltr', 294, 38, 11172, '15.9%'],
      ['Ghee', 'Pcs', 88, 180, 15840, '22.6%'],
      ['Curd', 'Pcs', 268, 25, 6700, '9.6%'],
    ],
    metrics: [
      ReportMetric('Quantity', '1,742'),
      ReportMetric('Sales Value', 'Rs. 66,664'),
      ReportMetric('Top Product', 'Full Cream Milk'),
    ],
  );

  static const _dateSales = _ReportContent(
    columns: ['Date', 'Invoice', 'Customer', 'Payment', 'Quantity', 'Amount'],
    rows: [
      ['02/09/2026', 'SALE-1026', 'Rahul Stores', 'UPI', 18, 1080],
      ['02/09/2026', 'SALE-1025', 'Shree Cafe', 'Credit', 24, 1440],
      ['02/09/2026', 'SALE-1024', 'Anita Patil', 'Cash', 12, 720],
      ['01/09/2026', 'SALE-1023', 'Fresh Farms', 'Bank', 20, 1200],
      ['01/09/2026', 'SALE-1022', 'Sai Dairy', 'Credit', 15, 900],
    ],
    metrics: [
      ReportMetric('Invoices', '5'),
      ReportMetric('Quantity', '89'),
      ReportMetric('Sales', 'Rs. 5,340'),
    ],
  );

  static const _purchaseRegister = _ReportContent(
    columns: [
      'Date',
      'Invoice',
      'Supplier',
      'Payment',
      'Quantity',
      'Bill Amount',
      'Status',
    ],
    rows: [
      [
        '02/09/2026',
        'PUR-1012',
        'Gokul Dairy Farm',
        'Credit',
        190,
        9450,
        'Due',
      ],
      ['30/08/2026', 'PUR-1011', 'Shivneri Milk', 'Bank', 240, 11800, 'Paid'],
      ['27/08/2026', 'PUR-1010', 'Mahalaxmi Foods', 'UPI', 85, 7200, 'Paid'],
      [
        '24/08/2026',
        'PUR-1009',
        'Gokul Dairy Farm',
        'Credit',
        210,
        10250,
        'Part Paid',
      ],
    ],
    metrics: [
      ReportMetric('Invoices', '4'),
      ReportMetric('Purchase', 'Rs. 38,700'),
      ReportMetric('Due', 'Rs. 14,450'),
    ],
  );

  static const _supplierPurchase = _ReportContent(
    columns: [
      'Supplier',
      'Invoices',
      'Quantity',
      'Purchase Value',
      'Paid',
      'Outstanding',
    ],
    rows: [
      ['Gokul Dairy Farm', 12, 1850, 86400, 70200, 16200],
      ['Shivneri Milk', 9, 1420, 65800, 62000, 3800],
      ['Mahalaxmi Foods', 7, 680, 54200, 54200, 0],
      ['Krishna Dairy', 5, 790, 36800, 31000, 5800],
    ],
    metrics: [
      ReportMetric('Suppliers', '4'),
      ReportMetric('Purchase', 'Rs. 2,43,200'),
      ReportMetric('Outstanding', 'Rs. 25,800'),
    ],
  );

  static const _productPurchase = _ReportContent(
    columns: [
      'Product',
      'Unit',
      'Quantity',
      'Average Rate',
      'Purchase Value',
      'Suppliers',
    ],
    rows: [
      ['Raw Milk', 'Ltr', 2250, 36, 81000, 3],
      ['Toned Milk', 'Ltr', 980, 28, 27440, 2],
      ['Curd', 'Pcs', 620, 21, 13020, 2],
      ['Ghee', 'Pcs', 210, 158, 33180, 2],
      ['Paneer', 'Pcs', 340, 72, 24480, 1],
    ],
    metrics: [
      ReportMetric('Quantity', '4,400'),
      ReportMetric('Purchase Value', 'Rs. 1,79,120'),
      ReportMetric('Top Product', 'Raw Milk'),
    ],
  );

  static const _purchaseDue = _ReportContent(
    columns: [
      'Supplier',
      'Invoice',
      'Bill Date',
      'Due Date',
      'Bill Amount',
      'Paid',
      'Due',
    ],
    rows: [
      [
        'Gokul Dairy Farm',
        'PUR-1012',
        '02/09/2026',
        '12/09/2026',
        9450,
        0,
        9450,
      ],
      [
        'Gokul Dairy Farm',
        'PUR-1009',
        '24/08/2026',
        '03/09/2026',
        10250,
        6000,
        4250,
      ],
      [
        'Krishna Dairy',
        'PUR-1008',
        '20/08/2026',
        '30/08/2026',
        7800,
        5200,
        2600,
      ],
      [
        'Shivneri Milk',
        'PUR-1005',
        '11/08/2026',
        '21/08/2026',
        6200,
        4700,
        1500,
      ],
    ],
    metrics: [
      ReportMetric('Invoices Due', '4'),
      ReportMetric('Total Due', 'Rs. 17,800'),
      ReportMetric('Overdue', 'Rs. 8,350'),
    ],
  );

  static const _collection = _ReportContent(
    columns: [
      'Date',
      'Receipt',
      'Customer',
      'Route',
      'Mode',
      'Amount',
      'Collected By',
    ],
    rows: [
      [
        '02/09/2026',
        'REC-2081',
        'Rahul Stores',
        'Route A',
        'UPI',
        1200,
        'Mahesh',
      ],
      [
        '02/09/2026',
        'REC-2080',
        'Shree Cafe',
        'Route B',
        'Cash',
        1800,
        'Suresh',
      ],
      [
        '02/09/2026',
        'REC-2079',
        'Anita Patil',
        'Route A',
        'Bank',
        950,
        'Mahesh',
      ],
      ['01/09/2026', 'REC-2078', 'Fresh Farms', 'Route C', 'UPI', 1400, 'Ravi'],
      ['01/09/2026', 'REC-2077', 'Sai Dairy', 'Route D', 'Cash', 860, 'Amit'],
    ],
    metrics: [
      ReportMetric('Receipts', '5'),
      ReportMetric('Collection', 'Rs. 6,210'),
      ReportMetric('Digital', 'Rs. 3,550'),
    ],
  );

  static const _allocation = _ReportContent(
    columns: [
      'Date',
      'Salesman',
      'Route',
      'Product',
      'Allocated',
      'Sold',
      'Returned',
      'Pending',
    ],
    rows: [
      ['02/09/2026', 'Mahesh', 'Route A', 'Full Cream Milk', 80, 68, 6, 6],
      ['02/09/2026', 'Suresh', 'Route B', 'Toned Milk', 70, 59, 5, 6],
      ['02/09/2026', 'Ravi', 'Route C', 'Buffalo Milk', 55, 46, 4, 5],
      ['02/09/2026', 'Amit', 'Route D', 'Curd', 45, 38, 3, 4],
    ],
    metrics: [
      ReportMetric('Allocated', '250'),
      ReportMetric('Sold', '211'),
      ReportMetric('Efficiency', '84.4%'),
    ],
  );

  static const _returns = _ReportContent(
    columns: [
      'Date',
      'Salesman',
      'Route',
      'Product',
      'Good',
      'Damaged',
      'Expired',
      'Value',
    ],
    rows: [
      ['02/09/2026', 'Mahesh', 'Route A', 'Full Cream Milk', 5, 1, 0, 192],
      ['02/09/2026', 'Suresh', 'Route B', 'Toned Milk', 4, 1, 0, 140],
      ['02/09/2026', 'Ravi', 'Route C', 'Buffalo Milk', 3, 1, 0, 152],
      ['01/09/2026', 'Amit', 'Route D', 'Curd', 2, 1, 1, 100],
    ],
    metrics: [
      ReportMetric('Returned', '20 units'),
      ReportMetric('Damaged', '4 units'),
      ReportMetric('Return Value', 'Rs. 584'),
    ],
  );

  static const _expenses = _ReportContent(
    columns: [
      'Date',
      'Voucher',
      'Category',
      'Description',
      'Mode',
      'Amount',
      'Approved By',
    ],
    rows: [
      [
        '02/09/2026',
        'EXP-401',
        'Fuel',
        'Route vehicles diesel',
        'Cash',
        3200,
        'Admin',
      ],
      [
        '02/09/2026',
        'EXP-400',
        'Vehicle',
        'MH-12 service',
        'Bank',
        1850,
        'Admin',
      ],
      [
        '01/09/2026',
        'EXP-399',
        'Packaging',
        'Crates and bags',
        'UPI',
        1260,
        'Admin',
      ],
      [
        '31/08/2026',
        'EXP-398',
        'Utilities',
        'Cold storage power',
        'Bank',
        2840,
        'Admin',
      ],
      [
        '30/08/2026',
        'EXP-397',
        'Other',
        'Cleaning supplies',
        'Cash',
        680,
        'Admin',
      ],
    ],
    metrics: [
      ReportMetric('Expenses', 'Rs. 9,830'),
      ReportMetric('Entries', '5'),
      ReportMetric('Top Category', 'Fuel'),
    ],
  );
}

class _ReportContent {
  const _ReportContent({
    required this.columns,
    required this.rows,
    required this.metrics,
  });

  final List<String> columns;
  final List<List<Object>> rows;
  final List<ReportMetric> metrics;
}
