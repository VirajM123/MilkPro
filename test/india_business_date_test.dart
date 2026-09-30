import 'package:flutter_test/flutter_test.dart';

import 'package:MilkPro/utils/india_business_date.dart';

void main() {
  group('IndiaBusinessDate', () {
    test('keeps a date-only API business key unchanged', () {
      expect(IndiaBusinessDate.apiDateKey('2026-09-26'), '2026-09-26');
      expect(
        IndiaBusinessDate.dateFromApi('2026-09-26'),
        DateTime(2026, 9, 26),
      );
    });

    test('converts timestamp API values to the India calendar day', () {
      expect(
        IndiaBusinessDate.apiDateKey('2026-09-26T20:00:00.000Z'),
        '2026-09-27',
      );

      final DateTime indiaTime = IndiaBusinessDate.timestampFromApi(
        '2026-09-26T20:00:00.000Z',
      );
      expect(indiaTime, DateTime(2026, 9, 27, 1, 30));
    });

    test('formats a picked date as a date-only API value', () {
      expect(
        IndiaBusinessDate.toDateKey(DateTime(2026, 9, 26, 23, 59)),
        '2026-09-26',
      );
    });
  });
}
