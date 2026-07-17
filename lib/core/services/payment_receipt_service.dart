// lib/core/services/payment_receipt_service.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // Compatibility fixed for ^9.0.0
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/payments/models/payment_model.dart';

class PaymentReceiptService {
  Future<pw.Document> generateReceiptPdf({
    required Payment payment,
    required Customer customer,
    required List<Order> linkedOrders,
    required double previousBalance,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
  }) async {
    final doc = pw.Document();

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
              _buildReceiptTitle(),
              pw.SizedBox(height: 16),
              _buildPaymentInfo(payment),
              pw.SizedBox(height: 16),
              _buildCustomerInfo(customer),
              pw.SizedBox(height: 20),
              if (linkedOrders.isNotEmpty) ...[
                _buildLinkedOrdersTable(linkedOrders),
                pw.SizedBox(height: 16),
              ],
              _buildSummary(
                paymentAmount: payment.amount,
                previousBalance: previousBalance,
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
                  color: PdfColors.green800,
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
                  color: PdfColors.green800,
                ),
              ),
              if (companyAddress != null && companyAddress.isNotEmpty)
                pw.Text(companyAddress, style: const pw.TextStyle(fontSize: 10)),
              if (companyPhone != null && companyPhone.isNotEmpty)
                pw.Text('Phone: $companyPhone',
                    style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildReceiptTitle() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green200),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'PAYMENT RECEIPT',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Thank you for your payment',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.green700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentInfo(Payment payment) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoField(
                  'Receipt No',
                  'PAY-${payment.id}',
                ),
              ),
              pw.Expanded(
                child: _buildInfoField(
                  'Date',
                  AppConstants.dateTimeFormat.format(payment.date),
                ),
              ),
              pw.Expanded(
                child: _buildInfoField(
                  'Method',
                  payment.type.name.toUpperCase(),
                ),
              ),
            ],
          ),
          if (payment.semanticType != null && payment.semanticType!.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildInfoField(
                    'Payment Type',
                    _capitalizeSemanticType(payment.semanticType!),
                  ),
                ),
              ],
            ),
          ],
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildInfoField(
                    'Notes',
                    payment.notes!,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _capitalizeSemanticType(String type) {
    if (type.isEmpty) return '';
    return type.substring(0, 1).toUpperCase() + type.substring(1);
  }

  pw.Widget _buildInfoField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerInfo(Customer customer) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Received From:',
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
              pw.Text(customer.ownerName, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(customer.phone, style: const pw.TextStyle(fontSize: 10)),
              if (customer.address != null && customer.address!.isNotEmpty)
                pw.Text(customer.address!, style: const pw.TextStyle(fontSize: 10)),
              if (customer.city != null && customer.city!.isNotEmpty)
                pw.Text(customer.city!, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildLinkedOrdersTable(List<Order> orders) {
    // ✅ Fixed: TableHelper.fromTextArray flat generic String structure use karta hai
    final headers = <String>['Invoice #', 'Date', 'Total', 'Paid'];

    final data = <List<String>>[];
    for (final order in orders) {
      data.add([
        order.invoiceNumber,
        AppConstants.dateFormat.format(order.date),
        '${AppConstants.currencySymbol}${order.totalAmount.toStringAsFixed(0)}',
        '${AppConstants.currencySymbol}${order.paidAmount.toStringAsFixed(0)}',
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Payment Applied To:',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          headerStyle: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        ),
      ],
    );
  }

  pw.Widget _buildSummary({
    required double paymentAmount,
    required double previousBalance,
  }) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 280,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.green200),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Amount Received',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${AppConstants.currencySymbol}${paymentAmount.toStringAsFixed(0)}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.green200, thickness: 0.5),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Previous Balance',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  '${AppConstants.currencySymbol}${previousBalance.toStringAsFixed(0)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Payment',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  '-${AppConstants.currencySymbol}${paymentAmount.toStringAsFixed(0)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.green700,
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.green200, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'New Balance',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${AppConstants.currencySymbol}${(previousBalance - paymentAmount).toStringAsFixed(0)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: previousBalance - paymentAmount > 0
                        ? PdfColors.red700
                        : PdfColors.green700,
                  ),
                ),
              ],
            ),
          ],
        ),
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
          'This is a computer-generated receipt.',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'No signature required.',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }

  Future<void> printReceipt(pw.Document doc) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return doc.save();
      },
    );
  }

  Future<String> saveReceipt(pw.Document doc, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(await doc.save());
    return filePath;
  }

  /// Share PDF file
  /// ✅ Fixed: share_plus plugin v9+ structure mapping
  Future<void> shareReceipt(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Payment Receipt',
    );
  }
}