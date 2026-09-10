import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/access_models.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/excel_service.dart';
import '../../services/report_pdf_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../common/access_denied_screen.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({
    super.key,
    required this.report,
    required this.from,
    required this.to,
    required this.icon,
    required this.color,
    this.filterLabel,
    this.filterValue,
  });

  final ReportData report;
  final DateTime from;
  final DateTime to;
  final IconData icon;
  final Color color;
  final String? filterLabel;
  final String? filterValue;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _exporting;

  List<List<Object>> get _visibleRows {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.report.rows;
    return widget.report.rows
        .where(
          (row) => row.any(
            (value) => value.toString().toLowerCase().contains(query),
          ),
        )
        .toList(growable: false);
  }

  ReportData get _visibleReport => widget.report.copyWith(rows: _visibleRows);

  String get _filterSummary {
    if (widget.filterLabel == null || widget.filterValue == null) {
      return 'All records';
    }
    return '${widget.filterLabel}: ${widget.filterValue}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!UiSession.instance.can(AppPermission.reportsView)) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: widget.report.title,
        subtitle: '${_date(widget.from)} to ${_date(widget.to)} • Demo data',
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 760;
            return SingleChildScrollView(
              padding: EdgeInsets.all(desktop ? 20 : 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _actionToolbar(desktop),
                      const SizedBox(height: 14),
                      _reportHeader(desktop),
                      const SizedBox(height: 14),
                      _metricCards(desktop),
                      const SizedBox(height: 16),
                      _reportTable(),
                      const SizedBox(height: 14),
                      _demoNote(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _actionToolbar(bool desktop) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: desktop
          ? Row(
              children: [
                Expanded(child: _searchField()),
                const SizedBox(width: 12),
                _exportButtons(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _searchField(),
                const SizedBox(height: 10),
                _exportButtons(expanded: true),
              ],
            ),
    ),
  );

  Widget _searchField() => AppSearchField(
    controller: _searchController,
    hint: 'Search in this report',
    onChanged: (value) => setState(() => _query = value),
    trailing: _query.isEmpty
        ? null
        : IconButton(
            tooltip: 'Clear search',
            onPressed: () {
              _searchController.clear();
              setState(() => _query = '');
            },
            icon: const Icon(Icons.close_rounded),
          ),
  );

  Widget _exportButtons({bool expanded = false}) {
    final buttons = <Widget>[
      _actionButton(
        key: const ValueKey('export-print'),
        type: 'print',
        label: 'Print',
        icon: Icons.print_outlined,
        color: AppColors.primaryDeep,
        onPressed: _printReport,
      ),
      const SizedBox(width: 8),
      _actionButton(
        key: const ValueKey('export-excel'),
        type: 'excel',
        label: 'Excel',
        icon: Icons.table_view_outlined,
        color: const Color(0xFF107C41),
        onPressed: _exportExcel,
      ),
      const SizedBox(width: 8),
      _actionButton(
        key: const ValueKey('export-csv'),
        type: 'csv',
        label: 'CSV',
        icon: Icons.description_outlined,
        color: AppColors.purple,
        onPressed: _exportCsv,
      ),
    ];
    if (!expanded) {
      return Row(mainAxisSize: MainAxisSize.min, children: buttons);
    }
    return Row(
      children: buttons
          .map(
            (button) => button is SizedBox ? button : Expanded(child: button),
          )
          .toList(growable: false),
    );
  }

  Widget _actionButton({
    required Key key,
    required String type,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) => ElevatedButton.icon(
    key: key,
    onPressed: _exporting == null ? onPressed : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      minimumSize: const Size(92, 48),
      padding: const EdgeInsets.symmetric(horizontal: 14),
    ),
    icon: _exporting == type
        ? const SizedBox.square(
            dimension: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Icon(icon, size: 18),
    label: Text(label),
  );

  Widget _reportHeader(bool desktop) => Container(
    padding: EdgeInsets.all(desktop ? 18 : 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primaryDeep, AppColors.primary],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadowPrimary,
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(widget.icon, color: Colors.white),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.report.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: desktop ? 20 : 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.report.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: [
                  _headerChip(
                    Icons.date_range_outlined,
                    '${_date(widget.from)} – ${_date(widget.to)}',
                  ),
                  _headerChip(Icons.filter_alt_outlined, _filterSummary),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _headerChip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _metricCards(bool desktop) {
    final accents = [AppColors.primary, AppColors.success, AppColors.purple];
    final cards = List.generate(widget.report.metrics.length, (index) {
      final metric = widget.report.metrics[index];
      final accent = accents[index % accents.length];
      return Container(
        width: desktop ? 230 : null,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 42,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    metric.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });

    if (desktop) return Wrap(spacing: 12, runSpacing: 12, children: cards);
    return Column(
      children: List.generate(
        cards.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == cards.length - 1 ? 0 : 8),
          child: cards[index],
        ),
      ),
    );
  }

  Widget _reportTable() => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              const Icon(
                Icons.grid_on_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Report data',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_visibleRows.length} records',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        if (_visibleRows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matching records',
              message: 'Clear the search or try another keyword.',
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = widget.report.columns.length * 145.0;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: tableWidth > constraints.maxWidth
                        ? tableWidth
                        : constraints.maxWidth,
                  ),
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: const TableBorder(
                      horizontalInside: BorderSide(color: AppColors.divider),
                      verticalInside: BorderSide(color: AppColors.divider),
                    ),
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: AppColors.primaryDeep,
                        ),
                        children: widget.report.columns
                            .map((column) => _tableCell(column, header: true))
                            .toList(growable: false),
                      ),
                      ...List.generate(_visibleRows.length, (rowIndex) {
                        final row = _visibleRows[rowIndex];
                        return TableRow(
                          decoration: BoxDecoration(
                            color: rowIndex.isEven
                                ? AppColors.surface
                                : AppColors.surfaceBlue,
                          ),
                          children: List.generate(
                            widget.report.columns.length,
                            (index) => _tableCell(
                              _display(
                                row[index],
                                widget.report.columns[index],
                              ),
                              numeric: row[index] is num,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );

  Widget _tableCell(String text, {bool header = false, bool numeric = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        child: Text(
          text,
          textAlign: numeric ? TextAlign.right : TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: header ? Colors.white : AppColors.textPrimary,
            fontSize: header ? 11 : 11.5,
            fontWeight: header ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      );

  Widget _demoNote() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.warningSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.warning.withValues(alpha: .24)),
    ),
    child: const Row(
      children: [
        Icon(Icons.science_outlined, color: AppColors.warning, size: 19),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Preview data: connect the reporting API later to replace these sample rows.',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 11),
          ),
        ),
      ],
    ),
  );

  Future<void> _printReport() => _runExport('print', () async {
    final bytes = await ReportPdfService.buildReport(
      _visibleReport,
      from: widget.from,
      to: widget.to,
      filterSummary: _filterSummary,
    );
    final opened = await Printing.layoutPdf(onLayout: (_) async => bytes);
    if (!opened) throw StateError('Print dialog was closed.');
    return opened;
  });

  Future<void> _exportExcel() => _runExport('excel', () {
    return ExcelService.exportExcel(
      _visibleReport,
      from: widget.from,
      to: widget.to,
      filterSummary: _filterSummary,
    );
  });

  Future<void> _exportCsv() => _runExport('csv', () {
    return ExcelService.exportCsv(
      _visibleReport,
      from: widget.from,
      to: widget.to,
      filterSummary: _filterSummary,
    );
  });

  Future<void> _runExport(
    String type,
    Future<Object?> Function() export,
  ) async {
    setState(() => _exporting = type);
    try {
      await export();
      if (mounted && type != 'print') {
        _message('${type.toUpperCase()} report exported.');
      }
    } catch (error) {
      if (mounted) _message('Unable to $type report: $error', error: true);
    } finally {
      if (mounted) setState(() => _exporting = null);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  String _display(Object value, String column) {
    if (value is num && _isMoney(column)) {
      return 'Rs. ${value.toStringAsFixed(2)}';
    }
    return value.toString();
  }

  bool _isMoney(String header) {
    final value = header.toLowerCase();
    return value.contains('amount') ||
        value.contains('value') ||
        value == 'sales' ||
        value == 'purchase' ||
        value == 'paid' ||
        value == 'due' ||
        value == 'collected' ||
        value == 'outstanding' ||
        value.contains('difference') ||
        value.contains('average bill');
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
