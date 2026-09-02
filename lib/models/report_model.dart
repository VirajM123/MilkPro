class ReportMetric {
  const ReportMetric(this.label, this.value);

  final String label;
  final String value;
}

class ReportData {
  const ReportData({
    required this.title,
    required this.description,
    required this.columns,
    required this.rows,
    required this.metrics,
  });

  final String title;
  final String description;
  final List<String> columns;
  final List<List<Object>> rows;
  final List<ReportMetric> metrics;

  ReportData copyWith({
    String? title,
    String? description,
    List<String>? columns,
    List<List<Object>>? rows,
    List<ReportMetric>? metrics,
  }) => ReportData(
    title: title ?? this.title,
    description: description ?? this.description,
    columns: columns ?? this.columns,
    rows: rows ?? this.rows,
    metrics: metrics ?? this.metrics,
  );

  String get fileName => title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
