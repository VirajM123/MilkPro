import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Helper to parse numbers safely from JSON
double _asDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? defaultValue;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value.toString().trim());
  return parsed;
}

int _asInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim()) ?? defaultValue;
}

// ============================================================================
// ALLOCATION MODEL
// ============================================================================

class CollectionAllocationModel {
  const CollectionAllocationModel({
    this.allocationSequence = 1,
    this.sourceType = 'SALE',
    this.referenceId = '',
    this.referenceNo = '',
    this.customerName = '',
    this.sourceAmount = 0.0,
    this.outstandingBefore,
    this.amountApplied = 0.0,
    this.outstandingAfter,
  });

  final int allocationSequence;
  final String sourceType;
  final String referenceId;
  final String referenceNo;
  final String customerName;
  final double sourceAmount;

  /// Nullable snapshots to preserve historical receipt fidelity.
  /// Must NOT default to 0 if absent in historical receipts.
  final double? outstandingBefore;
  final double amountApplied;
  final double? outstandingAfter;

  /// Indicates whether the allocation includes persisted before/after accounting snapshots.
  bool get hasAccountingSnapshot =>
      outstandingBefore != null && outstandingAfter != null;

  factory CollectionAllocationModel.fromJson(Map<String, dynamic> json) {
    return CollectionAllocationModel(
      allocationSequence: _asInt(json['allocationSequence'], 1),
      sourceType: (json['sourceType'] ?? 'SALE').toString().toUpperCase(),
      referenceId: (json['referenceId'] ?? json['saleId'] ?? '').toString(),
      referenceNo: (json['referenceNo'] ??
              json['saleNo'] ??
              json['referenceId'] ??
              json['saleId'] ??
              '')
          .toString(),
      customerName: (json['customerName'] ?? '').toString(),
      sourceAmount: _asDouble(json['sourceAmount'] ?? json['billAmount']),
      outstandingBefore: _asNullableDouble(json['outstandingBefore']),
      amountApplied: _asDouble(json['amountApplied']),
      outstandingAfter: _asNullableDouble(json['outstandingAfter']),
    );
  }

  Map<String, dynamic> toJson() => {
        'allocationSequence': allocationSequence,
        'sourceType': sourceType,
        'referenceId': referenceId,
        'referenceNo': referenceNo,
        'customerName': customerName,
        'sourceAmount': sourceAmount,
        'outstandingBefore': outstandingBefore,
        'amountApplied': amountApplied,
        'outstandingAfter': outstandingAfter,
      };
}

// ============================================================================
// BILL PAYMENT ITEM MODEL (Breakup)
// ============================================================================

class BillPaymentItemModel {
  const BillPaymentItemModel({
    this.mode = 'Cash',
    this.amount = 0.0,
    this.referenceNo = '',
  });

  final String mode;
  final double amount;
  final String referenceNo;

  factory BillPaymentItemModel.fromJson(Map<String, dynamic> json) {
    return BillPaymentItemModel(
      mode: (json['mode'] ?? json['paymentMode'] ?? 'Cash').toString(),
      amount: _asDouble(json['amount']),
      referenceNo: (json['referenceNo'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'amount': amount,
        'referenceNo': referenceNo,
      };
}

// ============================================================================
// COLLECTION RECEIPT MODEL (Unified: Virtual BILL_PAYMENT + Real COLLECTION)
// ============================================================================

class CollectionReceiptModel {
  const CollectionReceiptModel({
    this.sourceType = 'COLLECTION',
    this.id = '',
    this.receiptNo = '',
    this.saleNo = '',
    this.date,
    this.collectionDate,
    this.customerId = '',
    this.customerName = '',
    this.customerMobile = '',
    this.route = '',
    this.salesmanId = '',
    this.salesmanName = '',
    this.amount = 0.0,
    this.paidAmount = 0.0,
    this.billAmount = 0.0,
    this.appliedAmount = 0.0,
    this.paymentApplied = 0.0,
    this.advanceAmount = 0.0,
    this.advanceCreated = 0.0,
    this.advanceUsed = 0.0,
    this.previousOutstanding = 0.0,
    this.remainingOutstanding = 0.0,
    this.previousAdvanceBalance = 0.0,
    this.currentAdvanceBalance = 0.0,
    this.paymentMode = 'Cash',
    this.referenceNo = '',
    this.remarks = '',
    this.status = 'POSTED',
    this.cancelReason = '',
    this.clientRequestId = '',
    this.allocationMode = 'FIFO',
    this.payments = const [],
    this.allocations = const [],
    this.canDownloadReceipt = true,
  });

  final String sourceType; // "COLLECTION" or "BILL_PAYMENT"
  final String id;
  final String receiptNo;
  final String saleNo;
  final DateTime? date;
  final DateTime? collectionDate;
  final String customerId;
  final String customerName;
  final String customerMobile;
  final String route;
  final String salesmanId;
  final String salesmanName;

  /// Actual money received
  final double amount;

  /// Money received at billing (for BILL_PAYMENT)
  final double paidAmount;

  /// Total bill/invoice value (for BILL_PAYMENT)
  final double billAmount;

  /// Amount applied to outstanding
  final double appliedAmount;

  /// Payment applied to this bill (capped at billAmount)
  final double paymentApplied;

  /// Advance created
  final double advanceAmount;
  final double advanceCreated;

  /// Advance consumed from customer balance
  final double advanceUsed;

  /// Snapshots recorded at creation time
  final double previousOutstanding;
  final double remainingOutstanding;
  final double previousAdvanceBalance;
  final double currentAdvanceBalance;

  final String paymentMode;
  final String referenceNo;
  final String remarks;
  final String status;
  final String cancelReason;
  final String clientRequestId;
  final String allocationMode;
  final bool canDownloadReceipt;

  final List<BillPaymentItemModel> payments;
  final List<CollectionAllocationModel> allocations;

  bool get isCollection => sourceType.toUpperCase() == 'COLLECTION';
  bool get isBillPayment => sourceType.toUpperCase() == 'BILL_PAYMENT';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
  bool get isPosted => status.toUpperCase() == 'POSTED';
  bool get isManualAllocation => allocationMode.toUpperCase() == 'MANUAL';

  DateTime? get displayDate => collectionDate ?? date;

  factory CollectionReceiptModel.fromJson(Map<String, dynamic> json) {
    final rawPayments = json['payments'];
    final List<BillPaymentItemModel> paymentsList = [];
    if (rawPayments is List) {
      for (final p in rawPayments) {
        if (p is Map) {
          paymentsList.add(
            BillPaymentItemModel.fromJson(Map<String, dynamic>.from(p)),
          );
        }
      }
    }

    final rawAllocations = json['allocations'];
    final List<CollectionAllocationModel> allocationsList = [];
    if (rawAllocations is List) {
      for (final a in rawAllocations) {
        if (a is Map) {
          allocationsList.add(
            CollectionAllocationModel.fromJson(Map<String, dynamic>.from(a)),
          );
        }
      }
    }

    final String srcType =
        (json['sourceType'] ?? 'COLLECTION').toString().toUpperCase();

    final double rawAmount = _asDouble(json['amount']);
    final double rawPaidAmount =
        _asDouble(json['paidAmount'] ?? json['amount']);
    final double rawBillAmount =
        _asDouble(json['billAmount'] ?? json['grandTotal']);

    // Payment applied logic: prefer backend field, fallback to min(paidAmount, billAmount)
    final double rawPaymentApplied = json['paymentApplied'] != null
        ? _asDouble(json['paymentApplied'])
        : (srcType == 'BILL_PAYMENT'
            ? math.min(rawPaidAmount, rawBillAmount)
            : _asDouble(json['appliedAmount']));

    return CollectionReceiptModel(
      sourceType: srcType,
      id: (json['id'] ?? json['collectionId'] ?? json['saleId'] ?? '')
          .toString(),
      receiptNo: (json['receiptNo'] ??
              json['saleNo'] ??
              json['collectionId'] ??
              json['saleId'] ??
              '')
          .toString(),
      saleNo: (json['saleNo'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString()),
      collectionDate: DateTime.tryParse(
          (json['collectionDate'] ?? json['date'] ?? '').toString()),
      customerId: (json['customerId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerMobile: (json['customerMobile'] ?? '').toString(),
      route: (json['route'] ?? '').toString(),
      salesmanId: (json['salesmanId'] ?? '').toString(),
      salesmanName: (json['salesmanName'] ?? '').toString(),
      amount: rawAmount,
      paidAmount: rawPaidAmount,
      billAmount: rawBillAmount,
      appliedAmount: _asDouble(json['appliedAmount']),
      paymentApplied: rawPaymentApplied,
      advanceAmount: _asDouble(json['advanceAmount']),
      advanceCreated:
          _asDouble(json['advanceCreated'] ?? json['advanceAmount']),
      advanceUsed: _asDouble(json['advanceUsed']),
      previousOutstanding: _asDouble(json['previousOutstanding']),
      remainingOutstanding: _asDouble(
          json['remainingOutstanding'] ?? json['outstandingAmount']),
      previousAdvanceBalance: _asDouble(json['previousAdvanceBalance']),
      currentAdvanceBalance: _asDouble(json['currentAdvanceBalance']),
      paymentMode: (json['paymentMode'] ?? 'Cash').toString(),
      referenceNo: (json['referenceNo'] ?? '').toString(),
      remarks: (json['remarks'] ?? '').toString(),
      status: (json['status'] ?? (srcType == 'BILL_PAYMENT' ? 'PAID' : 'POSTED'))
          .toString()
          .toUpperCase(),
      cancelReason: (json['cancelReason'] ?? '').toString(),
      clientRequestId: (json['clientRequestId'] ?? '').toString(),
      allocationMode:
          (json['allocationMode'] ?? 'FIFO').toString().toUpperCase(),
      payments: paymentsList,
      allocations: allocationsList,
      canDownloadReceipt: json['canDownloadReceipt'] != false,
    );
  }
}

// ============================================================================
// MANUAL / OPENING OUTSTANDING
// ============================================================================

class ManualOutstandingModel {
  const ManualOutstandingModel({
    required this.adjustmentId,
    required this.adjustmentNo,
    required this.adjustmentDate,
    required this.amount,
    required this.collectionApplied,
    required this.outstandingAmount,
    this.remainingOutstanding = 0.0,
    this.customerId = '',
    this.customerName = '',
    required this.status,
    required this.remarks,
  });

  final String adjustmentId;
  final String adjustmentNo;
  final DateTime? adjustmentDate;
  final double amount;
  final double collectionApplied;
  final double outstandingAmount;
  final double remainingOutstanding;
  final String customerId;
  final String customerName;
  final String status;
  final String remarks;

  double get currentDue => remainingOutstanding > 0.001
      ? remainingOutstanding
      : (outstandingAmount > 0.001 ? outstandingAmount : 0.0);

  bool get isPaid => currentDue <= 0.001;
  bool get isPartial => !isPaid && collectionApplied > 0.001;

  factory ManualOutstandingModel.fromJson(Map<String, dynamic> json) {
    final double outAmt = _asDouble(json['outstandingAmount']);
    final double remOut = _asDouble(
      json['remainingOutstanding'] ?? json['outstandingAmount'],
    );
    return ManualOutstandingModel(
      adjustmentId:
          (json['adjustmentId'] ?? json['referenceId'] ?? '').toString(),
      adjustmentNo:
          (json['adjustmentNo'] ?? json['referenceNo'] ?? '').toString(),
      adjustmentDate: DateTime.tryParse(
        (json['adjustmentDate'] ?? json['referenceDate'] ?? '').toString(),
      ),
      amount: _asDouble(json['amount'] ?? json['initialOutstanding']),
      collectionApplied: _asDouble(json['collectionApplied']),
      outstandingAmount: outAmt,
      remainingOutstanding: remOut,
      customerId: (json['customerId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      status: (json['status'] ?? 'DUE').toString().toUpperCase(),
      remarks: (json['remarks'] ?? '').toString(),
    );
  }
}

// ============================================================================
// COLLECTION BILL MODEL
// ============================================================================

class CollectionBillModel {
  const CollectionBillModel({
    required this.saleId,
    required this.saleNo,
    required this.saleDate,
    this.customerId = '',
    this.customerName = '',
    required this.billAmount,
    required this.paidAtBilling,
    required this.paymentAppliedAtBilling,
    required this.advanceUsed,
    required this.collectionApplied,
    required this.totalAppliedToBill,
    required this.remainingOutstanding,
    required this.paymentMode,
    required this.paymentStatus,
    required this.payments,
  });

  final String saleId;
  final String saleNo;
  final DateTime? saleDate;
  final String customerId;
  final String customerName;
  final double billAmount;
  final double paidAtBilling;
  final double paymentAppliedAtBilling;
  final double advanceUsed;
  final double collectionApplied;
  final double totalAppliedToBill;
  final double remainingOutstanding;
  final String paymentMode;
  final String paymentStatus;
  final List<BillPaymentItemModel> payments;

  bool get isPaid => remainingOutstanding <= 0.001;
  bool get isPartial => !isPaid && totalAppliedToBill > 0.001;
  bool get isDue => !isPaid && totalAppliedToBill <= 0.001;

  double paymentAmount(String mode) {
    double total = 0;
    for (final payment in payments) {
      if (payment.mode.trim().toLowerCase() == mode.trim().toLowerCase()) {
        total += payment.amount;
      }
    }
    return total;
  }

  double get cashAmount => paymentAmount('Cash');
  double get upiAmount {
    double total = 0;
    for (final payment in payments) {
      final mode = payment.mode.trim().toLowerCase();
      if (mode == 'upi' ||
          mode == 'phonepe' ||
          mode == 'google pay' ||
          mode == 'gpay' ||
          mode == 'paytm') {
        total += payment.amount;
      }
    }
    return total;
  }

  double get bankAmount =>
      paymentAmount('Bank Transfer') + paymentAmount('Bank');

  factory CollectionBillModel.fromJson(Map<String, dynamic> json) {
    final rawPayments = json['payments'];
    final List<BillPaymentItemModel> paymentsList = [];
    if (rawPayments is List) {
      for (final p in rawPayments) {
        if (p is Map) {
          paymentsList.add(
            BillPaymentItemModel.fromJson(Map<String, dynamic>.from(p)),
          );
        }
      }
    }

    final double bAmount = _asDouble(json['billAmount'] ?? json['grandTotal']);
    final double pBilling = _asDouble(
        json['paidAtBilling'] ?? json['salePaidAmount'] ?? json['paidAmount']);
    final double pAppliedBilling = json['paymentAppliedAtBilling'] != null
        ? _asDouble(json['paymentAppliedAtBilling'])
        : math.min(pBilling, bAmount);
    final double advUsed = _asDouble(json['advanceUsed']);
    final double colApplied = _asDouble(json['collectionApplied']);

    final double totalApplied = json['totalAppliedToBill'] != null
        ? _asDouble(json['totalAppliedToBill'])
        : math.min(bAmount, pAppliedBilling + advUsed + colApplied);

    final double remOutstanding = json['remainingOutstanding'] != null
        ? _asDouble(json['remainingOutstanding'])
        : _asDouble(json['outstandingAmount'], math.max(0.0, bAmount - totalApplied));

    return CollectionBillModel(
      saleId: (json['saleId'] ?? '').toString(),
      saleNo: (json['saleNo'] ?? '').toString(),
      saleDate: DateTime.tryParse((json['saleDate'] ?? '').toString()),
      customerId: (json['customerId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      billAmount: bAmount,
      paidAtBilling: pBilling,
      paymentAppliedAtBilling: pAppliedBilling,
      advanceUsed: advUsed,
      collectionApplied: colApplied,
      totalAppliedToBill: totalApplied,
      remainingOutstanding: remOutstanding,
      paymentMode: (json['paymentMode'] ?? '').toString(),
      paymentStatus: (json['paymentStatus'] ?? 'CREDIT')
          .toString()
          .toUpperCase(),
      payments: paymentsList,
    );
  }
}

// ============================================================================
// CUSTOMER COLLECTION MODEL
// ============================================================================

class CustomerCollectionModel {
  const CustomerCollectionModel({
    required this.customerId,
    required this.name,
    required this.code,
    required this.mobile,
    required this.route,
    required this.salesmanId,
    required this.salesmanName,
    required this.outstanding,
    required this.netOutstanding,
    required this.advanceBalance,
    required this.grossBillOutstanding,
    required this.grossManualOutstanding,
    required this.grossOutstanding,
    required this.totalCreditSales,
    required this.totalPaidAtBilling,
    required this.totalLaterCollections,
    required this.totalCollected,
    required this.totalReceived,
    required this.paymentMode,
    required this.status,
    required this.bills,
    required this.manualOutstandings,
    required this.receiptHistory,
    required this.avatarColor,
    required this.avatarIconColor,
  });

  final String customerId;
  final String name;
  final String code;
  final String mobile;
  final String route;
  final String salesmanId;
  final String salesmanName;

  /// Signed customer account position (positive = owes money, 0 = settled, negative = advance)
  final double outstanding;
  final double netOutstanding;

  /// Available advance
  final double advanceBalance;

  /// Live collectible net outstanding: always non-negative.
  /// Used for: Collect Payment visibility, Maximum Collectable, amount validation, settlement preview.
  double get collectibleOutstanding => math.max(0.0, outstanding);

  /// Breakdown
  final double grossBillOutstanding;
  final double grossManualOutstanding;
  final double grossOutstanding;

  final double totalCreditSales;
  final double totalPaidAtBilling;
  final double totalLaterCollections;
  final double totalCollected;

  /// Total money received: binds directly to backend totalReceived.
  final double totalReceived;

  final String paymentMode;

  /// Primary accounting status from backend: PAID, PARTIAL, DUE, ADVANCE
  final String status;

  final List<CollectionBillModel> bills;
  final List<ManualOutstandingModel> manualOutstandings;
  final List<CollectionReceiptModel> receiptHistory;

  final Color avatarColor;
  final Color avatarIconColor;

  bool get isSettled => collectibleOutstanding <= 0.001;
  bool get isAdvance =>
      advanceBalance > 0.001 && collectibleOutstanding <= 0.001;

  factory CustomerCollectionModel.fromJson(Map<String, dynamic> json) {
    final rawBills = json['bills'];
    final List<CollectionBillModel> billsList = [];
    if (rawBills is List) {
      for (final b in rawBills) {
        if (b is Map) {
          billsList.add(
            CollectionBillModel.fromJson(Map<String, dynamic>.from(b)),
          );
        }
      }
    }

    final rawManual = json['manualOutstandings'];
    final List<ManualOutstandingModel> manualList = [];
    if (rawManual is List) {
      for (final m in rawManual) {
        if (m is Map) {
          manualList.add(
            ManualOutstandingModel.fromJson(Map<String, dynamic>.from(m)),
          );
        }
      }
    }

    final rawReceipts = json['receiptHistory'];
    final List<CollectionReceiptModel> receiptsList = [];
    if (rawReceipts is List) {
      for (final r in rawReceipts) {
        if (r is Map) {
          receiptsList.add(
            CollectionReceiptModel.fromJson(Map<String, dynamic>.from(r)),
          );
        }
      }
    }

    final double out = _asDouble(json['outstanding'] ?? json['netOutstanding']);
    final double netOut = _asDouble(json['netOutstanding'] ?? json['outstanding']);
    final double advBal = _asDouble(json['advanceBalance']);

    final double pBilling = _asDouble(json['totalPaidAtBilling']);
    final double lCol = _asDouble(json['totalLaterCollections']);
    final double totCol = _asDouble(json['totalCollected']);

    // Direct binding to backend totalReceived, fallback to pBilling + lCol if missing
    final double totRec = json['totalReceived'] != null
        ? _asDouble(json['totalReceived'])
        : (pBilling + lCol > 0 ? pBilling + lCol : totCol);

    final String backendStatus =
        (json['status'] ?? (out <= 0.001 ? 'PAID' : 'DUE'))
            .toString()
            .toUpperCase();

    return CustomerCollectionModel(
      customerId: (json['customerId'] ?? '').toString(),
      name: (json['customerName'] ?? json['name'] ?? '').toString(),
      code: (json['customerId'] ?? json['code'] ?? '').toString(),
      mobile: (json['customerMobile'] ?? json['mobile'] ?? '').toString(),
      route: (json['route'] ?? '').toString(),
      salesmanId: (json['salesmanId'] ?? '').toString(),
      salesmanName: (json['salesmanName'] ?? '').toString(),
      outstanding: out,
      netOutstanding: netOut,
      advanceBalance: advBal,
      grossBillOutstanding: _asDouble(json['grossBillOutstanding']),
      grossManualOutstanding: _asDouble(
          json['grossManualOutstanding'] ?? json['totalManualOutstanding']),
      grossOutstanding: _asDouble(json['grossOutstanding']),
      totalCreditSales: _asDouble(json['totalCreditSales']),
      totalPaidAtBilling: pBilling,
      totalLaterCollections: lCol,
      totalCollected: totCol,
      totalReceived: totRec,
      paymentMode: (json['lastPaymentMode'] ?? 'Pending').toString(),
      status: backendStatus,
      bills: billsList,
      manualOutstandings: manualList,
      receiptHistory: receiptsList,
      avatarColor: const Color(0xFFE6F2FF),
      avatarIconColor: const Color(0xFF1767D9),
    );
  }
}
