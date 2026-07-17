// lib/core/services/invoice_service.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // Modern share_plus syntax compatibility
import 'package:url_launcher/url_launcher.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';

class InvoiceService {
  /// Generate PDF document for invoice
  Future<pw.Document> generateInvoicePdf({
    required Order order,
    required Customer customer,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
  }) async {
    final doc = pw.Document();

    final subtotal = order.items.fold<double>(
      0,
          (sum, item) => sum + item.total,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(companyName, companyAddress, companyPhone),
              pw.SizedBox(height: 24),
              _buildInvoiceInfo(order),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(customer),
              pw.SizedBox(height: 24),
              _buildItemsTable(order.items),
              pw.SizedBox(height: 16),
              _buildTotals(
                subtotal: subtotal,
                discount: order.discount,
                tax: order.tax,
                total: order.totalAmount,
                paid: order.paidAmount,
              ),
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return doc;
  }

  pw.Widget _buildHeader(
      String? companyName,
      String? companyAddress,
      String? companyPhone,
      ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 60,
                height: 60,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'T',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                companyName ?? AppConstants.appName,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              if (companyAddress != null && companyAddress.isNotEmpty)
                pw.Text(
                  companyAddress,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (companyPhone != null && companyPhone.isNotEmpty)
                pw.Text(
                  'Phone: $companyPhone',
                  style: const pw.TextStyle(fontSize: 10),
                ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceInfo(Order order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Invoice Number',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  order.invoiceNumber,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Date',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  AppConstants.dateFormat.format(order.date),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Status',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  order.status.name.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerInfo(Customer customer) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Bill To:',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                customer.shopName,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                customer.ownerName,
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                customer.phone,
                style: const pw.TextStyle(fontSize: 10),
              ),
              if (customer.address != null && customer.address!.isNotEmpty)
                pw.Text(
                  customer.address!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (customer.city != null && customer.city!.isNotEmpty)
                pw.Text(
                  customer.city!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (customer.email != null && customer.email!.isNotEmpty)
                pw.Text(
                  customer.email!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<OrderItem> items) {
    // ✅ Fixed: TableHelper.fromTextArray generic lists of Strings accept karta hai, widgets nahi.
    final headers = <String>['#', 'Product', 'Qty', 'Rate', 'Total'];

    final data = <List<String>>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      data.add([
        '${i + 1}',
        item.productName,
        '${item.qty}',
        '${AppConstants.currencySymbol}${item.rate.toStringAsFixed(0)}',
        '${AppConstants.currencySymbol}${item.total.toStringAsFixed(0)}',
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(0.8),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.2),
      },
    );
  }

  pw.Widget _buildTotals({
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required double paid,
  }) {
    final remaining = total - paid;
    final labelStyle = const pw.TextStyle(fontSize: 10);
    final valueStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildTotalRow('Subtotal', subtotal, labelStyle, valueStyle),
            if (discount > 0)
              _buildTotalRow(
                'Discount',
                -discount,
                labelStyle,
                pw.TextStyle(fontSize: 10, color: PdfColors.red700),
              ),
            if (tax > 0)
              _buildTotalRow('Tax', tax, labelStyle, valueStyle),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            _buildTotalRow(
              'Grand Total',
              total,
              pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
              pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 4),
            _buildTotalRow('Paid', paid, labelStyle, valueStyle),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            _buildTotalRow(
              'Remaining',
              remaining,
              pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
              pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: remaining > 0 ? PdfColors.red700 : PdfColors.green700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(
      String label,
      double value,
      pw.TextStyle labelStyle,
      pw.TextStyle valueStyle,
      ) {
    final prefix = value < 0 ? '-' : '';
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: labelStyle),
          pw.Text(
            '$prefix${AppConstants.currencySymbol}${value.abs().toStringAsFixed(0)}',
            style: valueStyle,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 8),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'This is a computer-generated invoice.',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }

  /// Print invoice directly
  Future<void> printInvoice(pw.Document doc, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: fileName,
    );
  }

  /// Save PDF to device and return path
  Future<String> savePdf(pw.Document doc, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(await doc.save());
    return filePath;
  }

  /// Share PDF file
  /// ✅ Fixed: share_plus plugin v9+ standard format
  Future<void> sharePdf(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Invoice',
    );
  }

  /// Share via WhatsApp with pre-filled message
  Future<void> shareViaWhatsApp({
    required Order order,
    required Customer customer,
    required String pdfPath,
    String? companyPhone,
  }) async {
    final subtotal = order.items.fold<double>(
      0,
          (sum, item) => sum + item.total,
    );
    final remaining = order.totalAmount - order.paidAmount;

    final message = '''
*INVOICE - ${order.invoiceNumber}*
Date: ${AppConstants.dateFormat.format(order.date)}

*Customer:* ${customer.shopName}
*Phone:* ${customer.phone}

*Items:*
${order.items.map((item) => '• ${item.productName} × ${item.qty} = ${AppConstants.currencySymbol}${item.total.toStringAsFixed(0)}').join('\n')}

*Subtotal:* ${AppConstants.currencySymbol}${subtotal.toStringAsFixed(0)}
${order.discount > 0 ? '*Discount:* -${AppConstants.currencySymbol}${order.discount.toStringAsFixed(0)}\n' : ''}${order.tax > 0 ? '*Tax:* ${AppConstants.currencySymbol}${order.tax.toStringAsFixed(0)}\n' : ''}*Grand Total:* ${AppConstants.currencySymbol}${order.totalAmount.toStringAsFixed(0)}
*Paid:* ${AppConstants.currencySymbol}${order.paidAmount.toStringAsFixed(0)}
*Remaining:* ${AppConstants.currencySymbol}${remaining.toStringAsFixed(0)}

Thank you for your business!
''';

    try {
      // ✅ Fixed: Modern share_plus context call
      await Share.shareXFiles(
        [XFile(pdfPath)],
        text: message,
      );
    } catch (e) {
      // Fallback to WhatsApp URL if Native share fails
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = Uri.parse(
        'https://wa.me/${customer.phone.replaceAll(RegExp(r'[^\d]'), '')}?text=$encodedMessage',
      );
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    }
  }
}