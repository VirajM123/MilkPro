import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

import '../models/report_model.dart';

abstract final class ExcelService {
  static Uint8List buildExcelBytes(
    ReportData report, {
    required DateTime from,
    required DateTime to,
    String? filterSummary,
  }) {
    final workbook = Excel.createExcel();
    final sheetName = _safeSheetName(report.title);
    workbook.rename('Sheet1', sheetName);
    final sheet = workbook[sheetName];
    final lastColumn = report.columns.length - 1;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: lastColumn, rowIndex: 0),
      customValue: TextCellValue('KK ENTERPRISES - ${report.title}'),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: lastColumn, rowIndex: 1),
      customValue: TextCellValue(
        'Period: ${_date(from)} to ${_date(to)} | Demo report data',
      ),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      CellIndex.indexByColumnRow(columnIndex: lastColumn, rowIndex: 2),
      customValue: TextCellValue(
        '${filterSummary ?? 'All records'} | ${report.rows.length} records',
      ),
    );
    sheet.appendRow(<CellValue?>[]);
    sheet.appendRow(
      report.metrics
          .map<CellValue?>(
            (metric) => TextCellValue(metric.label.toUpperCase()),
          )
          .toList(),
    );
    sheet.appendRow(
      report.metrics
          .map<CellValue?>((metric) => TextCellValue(metric.value))
          .toList(),
    );
    sheet.appendRow(<CellValue?>[]);
    sheet.appendRow(
      report.columns.map<CellValue?>((value) => TextCellValue(value)).toList(),
    );

    for (final row in report.rows) {
      sheet.appendRow(row.map<CellValue?>(_excelValue).toList());
    }

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 18,
      fontFamily: 'Calibri',
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#0B2D69'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final subtitleStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#33547F'),
      backgroundColorHex: ExcelColor.fromHexString('#EDF5FF'),
      fontFamily: 'Calibri',
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final metadataStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#64748B'),
      backgroundColorHex: ExcelColor.fromHexString('#F8FAFD'),
      fontFamily: 'Calibri',
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#0B2D69'),
      fontFamily: 'Calibri',
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#16A765'),
      ),
    );

    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
            .cellStyle =
        titleStyle;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
            .cellStyle =
        subtitleStyle;
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
            .cellStyle =
        metadataStyle;
    const metricColors = ['#1665E8', '#16A765', '#7357EB'];
    for (var index = 0; index < report.metrics.length; index++) {
      final color = ExcelColor.fromHexString(metricColors[index % 3]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: index, rowIndex: 4))
          .cellStyle = CellStyle(
        bold: true,
        fontSize: 9,
        fontFamily: 'Calibri',
        fontColorHex: ExcelColor.fromHexString('#64748B'),
        backgroundColorHex: ExcelColor.fromHexString('#F3F7FF'),
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: color,
        ),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: index, rowIndex: 5))
          .cellStyle = CellStyle(
        bold: true,
        fontSize: 13,
        fontFamily: 'Calibri',
        fontColorHex: ExcelColor.fromHexString('#14213D'),
        backgroundColorHex: ExcelColor.fromHexString('#F3F7FF'),
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: color,
        ),
      );
    }
    for (var column = 0; column < report.columns.length; column++) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 7),
              )
              .cellStyle =
          headerStyle;
      final header = report.columns[column].toLowerCase();
      final isWide =
          header.contains('product') ||
          header.contains('customer') ||
          header.contains('supplier') ||
          header.contains('description');
      sheet.setColumnWidth(column, isWide ? 26 : 17);
    }
    sheet.setRowHeight(0, 32);
    sheet.setRowHeight(1, 24);
    sheet.setRowHeight(2, 21);
    sheet.setRowHeight(4, 20);
    sheet.setRowHeight(5, 26);
    sheet.setRowHeight(7, 27);

    for (var row = 0; row < report.rows.length; row++) {
      for (var column = 0; column < report.columns.length; column++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row + 8),
        );
        final isCurrency = _isCurrencyColumn(report.columns[column]);
        final numeric = report.rows[row][column] is num;
        final gridBorder = Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#DCE4EF'),
        );
        cell.cellStyle = CellStyle(
          fontFamily: 'Calibri',
          fontSize: 10,
          fontColorHex: ExcelColor.fromHexString('#14213D'),
          backgroundColorHex: row.isEven
              ? ExcelColor.white
              : ExcelColor.fromHexString('#F3F7FF'),
          horizontalAlign: numeric
              ? HorizontalAlign.Right
              : HorizontalAlign.Left,
          verticalAlign: VerticalAlign.Center,
          bottomBorder: gridBorder,
          numberFormat: numeric && isCurrency
              ? CustomNumericNumFormat(formatCode: '"Rs. "#,##0.00')
              : numeric
              ? CustomNumericNumFormat(formatCode: '#,##0.##')
              : NumFormat.standard_49,
        );
      }
      sheet.setRowHeight(row + 8, 22);
    }

    final bytes = workbook.encode();
    if (bytes == null) throw StateError('Unable to create Excel workbook.');
    return Uint8List.fromList(bytes);
  }

  static Uint8List buildCsvBytes(
    ReportData report, {
    required DateTime from,
    required DateTime to,
    String? filterSummary,
  }) {
    final rows = <List<Object>>[
      ['KK ENTERPRISES - ${report.title}'],
      ['Period', _date(from), 'To', _date(to)],
      ['Filter', filterSummary ?? 'All records'],
      <Object>[...report.columns],
      ...report.rows,
    ];
    final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n');
    return Uint8List.fromList(utf8.encode('\uFEFF$csv'));
  }

  static Future<String> exportExcel(
    ReportData report, {
    required DateTime from,
    required DateTime to,
    String? filterSummary,
  }) {
    return FileSaver.instance.saveFile(
      name: '${report.fileName}_${_fileDate(from)}_${_fileDate(to)}',
      bytes: buildExcelBytes(
        report,
        from: from,
        to: to,
        filterSummary: filterSummary,
      ),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  static Future<String> exportCsv(
    ReportData report, {
    required DateTime from,
    required DateTime to,
    String? filterSummary,
  }) {
    return FileSaver.instance.saveFile(
      name: '${report.fileName}_${_fileDate(from)}_${_fileDate(to)}',
      bytes: buildCsvBytes(
        report,
        from: from,
        to: to,
        filterSummary: filterSummary,
      ),
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  static CellValue _excelValue(Object value) => switch (value) {
    int number => IntCellValue(number),
    double number => DoubleCellValue(number),
    bool flag => BoolCellValue(flag),
    _ => TextCellValue(value.toString()),
  };

  static bool _isCurrencyColumn(String header) {
    final value = header.toLowerCase();
    return value.contains('amount') ||
        value.contains('value') ||
        value == 'sales' ||
        value == 'purchase' ||
        value == 'collected' ||
        value == 'paid' ||
        value == 'due' ||
        value == 'outstanding' ||
        value.contains('difference') ||
        value.contains('average bill');
  }

  static String _escapeCsv(Object value) {
    final text = value.toString();
    if (!text.contains(RegExp('[,"\n\r]'))) return text;
    return '"${text.replaceAll('"', '""')}"';
  }

  static String _safeSheetName(String value) {
    final safe = value.replaceAll(RegExp(r'[\\/*?:\[\]]'), ' ');
    return safe.length <= 31 ? safe : safe.substring(0, 31);
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _fileDate(DateTime value) =>
      '${value.year}${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}';
}
