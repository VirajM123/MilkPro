import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/sale_model.dart';
import '../../services/bill_pdf_service.dart';
import '../../theme/app_colors.dart';

class SalesBillPreviewScreen extends StatefulWidget {
  const SalesBillPreviewScreen({
    super.key,
    required this.sale,
    this.openWhatsAppOnStart = false,
  });

  final SaleModel sale;
  final bool openWhatsAppOnStart;

  @override
  State<SalesBillPreviewScreen> createState() => _SalesBillPreviewScreenState();
}

class _SalesBillPreviewScreenState extends State<SalesBillPreviewScreen> {
  late final Future<Uint8List> _billBytes;
  bool _openingWhatsApp = false;

  @override
  void initState() {
    super.initState();
    _billBytes = BillPdfService.buildBill(widget.sale);
    if (widget.openWhatsAppOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openWhatsApp());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Bill PDF'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: _download,
            icon: const Icon(Icons.download_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _openingWhatsApp ? null : _openWhatsApp,
              icon: _openingWhatsApp
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chat_outlined),
              label: const Text('WhatsApp'),
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => _billBytes,
        pdfFileName: BillPdfService.billFileName(widget.sale),
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
      await BillPdfService.downloadBill(widget.sale, await _billBytes);
      if (mounted) _message('PDF bill downloaded.', success: true);
    } catch (error) {
      if (mounted) _message('Unable to download bill: $error');
    }
  }

  Future<void> _openWhatsApp() async {
    final mobile = await _askMobile(
      BillPdfService.customerMobileFor(widget.sale),
    );
    if (mobile == null || !mounted) return;

    setState(() => _openingWhatsApp = true);
    try {
      final bytes = await _billBytes;
      await BillPdfService.downloadBill(widget.sale, bytes);
      final opened = await BillPdfService.openWhatsApp(widget.sale, mobile);
      if (mounted && !opened) {
        _message('WhatsApp could not be opened on this device.');
      }
    } catch (error) {
      if (mounted) _message('Unable to open WhatsApp: $error');
    } finally {
      if (mounted) setState(() => _openingWhatsApp = false);
    }
  }

  Future<String?> _askMobile(String initialValue) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send bill on WhatsApp'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: initialValue.isEmpty,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp number',
              prefixText: '+91 ',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (text) {
              final digits = (text ?? '').replaceAll(RegExp(r'\D'), '');
              return digits.length == 10 || digits.length == 12
                  ? null
                  : 'Enter a valid WhatsApp number';
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(dialogContext, controller.text.trim());
            },
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Open WhatsApp'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    return value;
  }

  void _message(String text, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }
}
