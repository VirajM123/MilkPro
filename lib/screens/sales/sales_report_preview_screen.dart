import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/sale_model.dart';
import '../../services/bill_pdf_service.dart';

class SalesReportPreviewScreen extends StatefulWidget {
  const SalesReportPreviewScreen({
    super.key,
    required this.sales,
    this.selectedDate,
  });

  final List<SaleModel> sales;
  final DateTime? selectedDate;

  @override
  State<SalesReportPreviewScreen> createState() =>
      _SalesReportPreviewScreenState();
}

class _SalesReportPreviewScreenState extends State<SalesReportPreviewScreen> {
  late final Future<Uint8List> _reportBytes;

  @override
  void initState() {
    super.initState();
    _reportBytes = BillPdfService.buildSalesReport(
      widget.sales,
      selectedDate: widget.selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report PDF'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: _download,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => _reportBytes,
        pdfFileName:
            BillPdfService.salesReportFileName(date: widget.selectedDate),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }

  Future<void> _download() async {
    try {
      final bytes = await _reportBytes;
      await BillPdfService.downloadSalesReport(bytes,
          date: widget.selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sales report downloaded.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to download report: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

