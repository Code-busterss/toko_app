// lib/features/products/screens/barcode_screen.dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode_widget/barcode_widget.dart';
import '../../../core/constants/constants.dart';

class BarcodeScreen extends StatefulWidget {
  final Product product;
  final int quantity;

  const BarcodeScreen({
    super.key,
    required this.product,
    this.quantity = 1,
  });

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  int _quantity = 1;

  // ✅ Separate barcode types for PDF and UI
  pw.Barcode _selectedPdfBarcodeType = pw.Barcode.code128();
  pw.Barcode _selectedUiBarcodeType = pw.Barcode.code128();
  String _selectedBarcodeTypeName = 'Code 128';

  final List<Map<String, dynamic>> _barcodeTypes = [
    {
      'name': 'Code 128',
      'pdfBarcode': pw.Barcode.code128(),
      'uiBarcode': pw.Barcode.code128(),
    },
    {
      'name': 'Code 39',
      'pdfBarcode': pw.Barcode.code39(),
      'uiBarcode': pw.Barcode.code39(),
    },
    {
      'name': 'EAN 13',
      'pdfBarcode': pw.Barcode.ean13(),
      'uiBarcode': pw.Barcode.ean13(),
    },
    {
      'name': 'EAN 8',
      'pdfBarcode': pw.Barcode.ean8(),
      'uiBarcode': pw.Barcode.ean8(),
    },
    {
      'name': 'UPC A',
      'pdfBarcode': pw.Barcode.upcA(),
      'uiBarcode': pw.Barcode.upcA(),
    },
    {
      'name': 'QR Code',
      'pdfBarcode': pw.Barcode.qrCode(),
      'uiBarcode': pw.Barcode.qrCode(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _quantity = widget.quantity;
    _detectBarcodeType();
  }

  void _detectBarcodeType() {
    final barcode = widget.product.barcode ?? widget.product.sku ?? '';
    if (barcode.isEmpty) return;

    if (barcode.length == 13 && RegExp(r'^\d{13}$').hasMatch(barcode)) {
      setState(() {
        _selectedPdfBarcodeType = pw.Barcode.ean13();
        _selectedUiBarcodeType = pw.Barcode.ean13();
        _selectedBarcodeTypeName = 'EAN 13';
      });
    } else if (barcode.length == 8 && RegExp(r'^\d{8}$').hasMatch(barcode)) {
      setState(() {
        _selectedPdfBarcodeType = pw.Barcode.ean8();
        _selectedUiBarcodeType = pw.Barcode.ean8();
        _selectedBarcodeTypeName = 'EAN 8';
      });
    } else if (barcode.length == 12 && RegExp(r'^\d{12}$').hasMatch(barcode)) {
      setState(() {
        _selectedPdfBarcodeType = pw.Barcode.upcA();
        _selectedUiBarcodeType = pw.Barcode.upcA();
        _selectedBarcodeTypeName = 'UPC A';
      });
    }
  }

  String get _barcodeData {
    return widget.product.barcode ?? widget.product.sku ?? 'N/A';
  }

  Future<void> _printBarcode() async {
    try {
      final pdf = await _buildPdfDocument(PdfPageFormat.a4);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Print job sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareOrPreview() async {
    try {
      final pdf = await _buildPdfDocument(PdfPageFormat.roll80);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '${widget.product.name}_barcode.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<pw.Document> _buildPdfDocument(PdfPageFormat format) async {
    final doc = pw.Document();
    final barcodeData = _barcodeData;

    final labelWidth = format.width;
    final labelHeight = format.height;

    for (int i = 0; i < _quantity; i++) {
      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(8),
          build: (pw.Context context) {
            return pw.Container(
              width: labelWidth,
              height: labelHeight,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              ),
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    widget.product.name,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                    maxLines: 2,
                  ),
                  pw.SizedBox(height: 4),
                  if (widget.product.sku != null)
                    pw.Text(
                      'SKU: ${widget.product.sku}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${AppConstants.currencySymbol} ${widget.product.sellingPrice.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.BarcodeWidget(
                    barcode: _selectedPdfBarcodeType, // ✅ Using PDF barcode type
                    data: barcodeData,
                    width: labelWidth - 32,
                    height: 60,
                    textStyle: const pw.TextStyle(fontSize: 8),
                    drawText: true,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return doc;
  }

  @override
  Widget build(BuildContext context) {
    final barcodeData = _barcodeData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Label'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareOrPreview,
            tooltip: 'Share / Save PDF',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printBarcode,
            tooltip: 'Print',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      widget.product.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppConstants.currencySymbol} ${widget.product.sellingPrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.product.sku != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${widget.product.sku}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: BarcodeWidget(
                        barcode: _selectedUiBarcodeType, // ✅ Using UI barcode type
                        data: barcodeData,
                        width: double.infinity,
                        height: 100,
                        color: Colors.black,
                        drawText: true,
                        style: const TextStyle(fontSize: 12),
                        errorBuilder: (context, error) => Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'Invalid barcode data',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                              Text(
                                error,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      barcodeData,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Barcode Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBarcodeTypeName,
                      decoration: const InputDecoration(
                        labelText: 'Barcode Type',
                        prefixIcon: Icon(Icons.barcode_reader),
                      ),
                      items: _barcodeTypes.map((type) {
                        return DropdownMenuItem(
                          value: type['name'] as String,
                          child: Text(type['name'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          final selected = _barcodeTypes.firstWhere(
                                (type) => type['name'] == value,
                          );
                          setState(() {
                            _selectedPdfBarcodeType = selected['pdfBarcode'] as pw.Barcode;
                            _selectedUiBarcodeType = selected['uiBarcode'] as Barcode;
                            _selectedBarcodeTypeName = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Print Quantity:'),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$_quantity',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: _quantity < 100
                              ? () => setState(() => _quantity++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Name', widget.product.name),
                    _buildDetailRow('SKU', widget.product.sku ?? 'N/A'),
                    _buildDetailRow('Barcode', widget.product.barcode ?? 'N/A'),
                    _buildDetailRow(
                      'Price',
                      '${AppConstants.currencySymbol} ${widget.product.sellingPrice.toStringAsFixed(0)}',
                    ),
                    _buildDetailRow('Category', widget.product.category ?? 'N/A'),
                    _buildDetailRow('Brand', widget.product.brand ?? 'N/A'),
                    _buildDetailRow('Stock', '${widget.product.stock} ${widget.product.unit}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _printBarcode,
              icon: const Icon(Icons.print),
              label: const Text('Print Label'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _shareOrPreview,
              icon: const Icon(Icons.share),
              label: const Text('Share / Save as PDF'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}