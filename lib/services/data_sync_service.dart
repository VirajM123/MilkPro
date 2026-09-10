import 'package:flutter/foundation.dart';

/// Types of data mutation synchronization events.
enum SyncEventType {
  allocation,
  sale,
  returnSettlement,
  all,
}

/// Lightweight central synchronization event notifier.
///
/// NOTE:
/// - This service does NOT store any data records.
/// - The backend database and REST APIs remain the sole source of truth.
/// - Its only purpose is to notify mounted screens that a mutation occurred
///   so they can re-fetch authoritative data.
class DataSyncService extends ChangeNotifier {
  DataSyncService._();

  static final DataSyncService instance = DataSyncService._();

  int _allocationVersion = 0;
  int _saleVersion = 0;
  int _returnVersion = 0;

  SyncEventType? _lastEventType;
  DateTime? _lastSyncTime;

  int get allocationVersion => _allocationVersion;
  int get saleVersion => _saleVersion;
  int get returnVersion => _returnVersion;

  SyncEventType? get lastEventType => _lastEventType;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Notify that an allocation was created, updated, or cancelled.
  void notifyAllocationChanged() {
    _allocationVersion++;
    _lastEventType = SyncEventType.allocation;
    _lastSyncTime = DateTime.now();
    notifyListeners();
  }

  /// Notify that a sale was created, updated, or cancelled.
  void notifySaleChanged() {
    _saleVersion++;
    _lastEventType = SyncEventType.sale;
    _lastSyncTime = DateTime.now();
    notifyListeners();
  }

  /// Notify that a return / settlement was recorded or updated.
  void notifyReturnChanged() {
    _returnVersion++;
    _lastEventType = SyncEventType.returnSettlement;
    _lastSyncTime = DateTime.now();
    notifyListeners();
  }

  /// Notify a general full sync event across all modules.
  void notifyAllChanged() {
    _allocationVersion++;
    _saleVersion++;
    _returnVersion++;
    _lastEventType = SyncEventType.all;
    _lastSyncTime = DateTime.now();
    notifyListeners();
  }
}

