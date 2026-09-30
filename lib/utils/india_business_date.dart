/// Calendar-date helpers for MilkPro's India business day.
///
/// A business date is deliberately represented as a local, date-only
/// [DateTime] or a `YYYY-MM-DD` key. It is not a UTC timestamp.
///
/// Rules are intentionally aligned with the backend:
///
/// 1. YYYY-MM-DD
///    -> business-date token
///
/// 2. Timestamp containing Z / +05:30 / another explicit offset
///    -> real instant, convert to India
///
/// 3. Timestamp WITHOUT an offset
///    -> India wall-clock datetime
///
/// This prevents the device timezone from changing business dates.
abstract final class IndiaBusinessDate {
  static const Duration _indiaOffset =
      Duration(hours: 5, minutes: 30);

  static final RegExp _dateKeyPattern =
      RegExp(
        r'^(\d{4})-(\d{2})-(\d{2})$',
      );

  static final RegExp _isoDateTimePattern =
      RegExp(
        r'^(\d{4})-(\d{2})-(\d{2})'
        r'T'
        r'(\d{2}):(\d{2})'
        r'(?::(\d{2})(?:\.(\d{1,9}))?)?'
        r'([zZ]|[+-]\d{2}:?\d{2})?$',
      );

  /// Today's calendar date in India,
  /// independent of the device timezone.
  static DateTime today() {
    return fromInstant(
      DateTime.now(),
    );
  }

  /// Converts a real instant to India wall-clock
  /// date/time fields.
  static DateTime fromInstant(
    DateTime instant,
  ) {
    final DateTime india =
        instant
            .toUtc()
            .add(
              _indiaOffset,
            );

    return DateTime(
      india.year,
      india.month,
      india.day,
      india.hour,
      india.minute,
      india.second,
      india.millisecond,
      india.microsecond,
    );
  }

  /// Formats a calendar date as YYYY-MM-DD.
  static String toDateKey(
    DateTime date,
  ) {
    final String year =
        date.year
            .toString()
            .padLeft(
              4,
              '0',
            );

    final String month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$year-$month-$day';
  }

  /// Reads an exact YYYY-MM-DD key.
  static DateTime? tryDateFromKey(
    String? value,
  ) {
    final Match? match =
        _dateKeyPattern.firstMatch(
      value?.trim() ?? '',
    );

    if (match == null) {
      return null;
    }

    final int? year =
        int.tryParse(
      match.group(1)!,
    );

    final int? month =
        int.tryParse(
      match.group(2)!,
    );

    final int? day =
        int.tryParse(
      match.group(3)!,
    );

    if (
      year == null ||
      month == null ||
      day == null
    ) {
      return null;
    }

    final DateTime result =
        DateTime(
      year,
      month,
      day,
    );

    if (
      result.year != year ||
      result.month != month ||
      result.day != day
    ) {
      return null;
    }

    return result;
  }

  /// Detect whether an ISO datetime contains
  /// an explicit timezone suffix.
  static bool _hasExplicitZone(
    String value,
  ) {
    final Match? match =
        _isoDateTimePattern.firstMatch(
      value.trim(),
    );

    if (match == null) {
      return false;
    }

    return (
      match.group(8) ??
      ''
    ).isNotEmpty;
  }

  /// Reads a zone-less ISO datetime as
  /// India wall-clock values.
  ///
  /// Example:
  ///
  /// 2026-09-28T00:15:00
  ///
  /// stays:
  ///
  /// 28-Sep 00:15
  ///
  /// regardless of the device timezone.
  static DateTime?
      _indiaWallClockFromZoneLessIso(
    String value,
  ) {
    final Match? match =
        _isoDateTimePattern.firstMatch(
      value.trim(),
    );

    if (match == null) {
      return null;
    }

    if (
      (
        match.group(8) ??
        ''
      ).isNotEmpty
    ) {
      return null;
    }

    final int year =
        int.parse(
      match.group(1)!,
    );

    final int month =
        int.parse(
      match.group(2)!,
    );

    final int day =
        int.parse(
      match.group(3)!,
    );

    final int hour =
        int.parse(
      match.group(4)!,
    );

    final int minute =
        int.parse(
      match.group(5)!,
    );

    final int second =
        int.tryParse(
          match.group(6) ??
              '0',
        ) ??
        0;

    if (
      hour > 23 ||
      minute > 59 ||
      second > 59
    ) {
      return null;
    }

    final String fraction =
        match.group(7) ?? '';

    int microsecond = 0;

    if (fraction.isNotEmpty) {
      final String padded =
          fraction
              .padRight(
                6,
                '0',
              )
              .substring(
                0,
                6,
              );

      microsecond =
          int.tryParse(
            padded,
          ) ??
          0;
    }

    final DateTime result =
        DateTime(
      year,
      month,
      day,
      hour,
      minute,
      second,
      microsecond ~/ 1000,
      microsecond % 1000,
    );

    if (
      result.year != year ||
      result.month != month ||
      result.day != day ||
      result.hour != hour ||
      result.minute != minute ||
      result.second != second
    ) {
      return null;
    }

    return result;
  }

  /// Converts API input into the India
  /// business-date key.
  static String? apiDateKey(
    Object? value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return toDateKey(
        fromInstant(
          value,
        ),
      );
    }

    final String raw =
        value
            .toString()
            .trim();

    if (raw.isEmpty) {
      return null;
    }

    // ==========================================
    // DATE ONLY
    // ==========================================

    final DateTime? dateOnly =
        tryDateFromKey(
      raw,
    );

    if (dateOnly != null) {
      return toDateKey(
        dateOnly,
      );
    }

    // ==========================================
    // ZONE-LESS ISO
    //
    // Backend treats this as India wall clock.
    // ==========================================

    final DateTime? wallClock =
        _indiaWallClockFromZoneLessIso(
      raw,
    );

    if (wallClock != null) {
      return toDateKey(
        wallClock,
      );
    }

    // ==========================================
    // EXPLICIT-ZONE TIMESTAMP
    //
    // Real instant -> India
    // ==========================================

    if (_hasExplicitZone(raw)) {
      final DateTime? instant =
          DateTime.tryParse(
        raw,
      );

      if (instant == null) {
        return null;
      }

      return toDateKey(
        fromInstant(
          instant,
        ),
      );
    }

    return null;
  }

  /// Converts an API business date to a
  /// date-only Flutter value.
  static DateTime dateFromApi(
    Object? value, {
    DateTime? fallback,
  }) {
    final String? key =
        apiDateKey(
      value,
    );

    return tryDateFromKey(
          key,
        ) ??
        fallback ??
        today();
  }

  /// Converts an API timestamp to India
  /// wall-clock display time.
  static DateTime timestampFromApi(
    Object? value, {
    DateTime? fallback,
  }) {
    if (value is DateTime) {
      return fromInstant(
        value,
      );
    }

    if (value != null) {
      final String raw =
          value
              .toString()
              .trim();

      // Zone-less timestamps are already
      // India wall-clock values.
      final DateTime? wallClock =
          _indiaWallClockFromZoneLessIso(
        raw,
      );

      if (wallClock != null) {
        return wallClock;
      }

      // Explicit offset / Z timestamps are
      // real instants.
      final DateTime? instant =
          DateTime.tryParse(
        raw,
      );

      if (instant != null) {
        return fromInstant(
          instant,
        );
      }
    }

    return fromInstant(
      fallback ??
          DateTime.now(),
    );
  }
}