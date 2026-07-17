// lib/features/orders/providers/invoice_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:toko_app/core/services/invoice_service.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/features/customers/repositories/customer_repository.dart';
import 'package:toko_app/features/orders/repositories/order_repository.dart';

enum InvoiceActionType { printing, saving, sharing, whatsapp }

class InvoiceState {
  final pw.Document? document;
  final String? savedFilePath;
  final InvoiceActionType? currentAction;
  final String? errorMessage;
  final String? successMessage;
  final bool isGenerating;

  const InvoiceState({
    this.document,
    this.savedFilePath,
    this.currentAction,
    this.errorMessage,
    this.successMessage,
    this.isGenerating = false,
  });

  InvoiceState copyWith({
    pw.Document? document,
    String? savedFilePath,
    InvoiceActionType? currentAction,
    String? errorMessage,
    String? successMessage,
    bool? isGenerating,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearAction = false,
  }) {
    return InvoiceState(
      document: document ?? this.document,
      savedFilePath: savedFilePath ?? this.savedFilePath,
      currentAction: clearAction ? null : (currentAction ?? this.currentAction),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

class InvoiceNotifier extends Notifier<InvoiceState> {
  final InvoiceService _invoiceService = InvoiceService();
  final OrderRepository _orderRepository = OrderRepository();
  final CustomerRepository _customerRepository = CustomerRepository();

  InvoiceService get service => _invoiceService;

  @override
  InvoiceState build() {
    return const InvoiceState();
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<void> generateInvoice({
    required Order order,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
  }) async {
    if (state.document != null) return;

    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      final customer = await _customerRepository.getCustomerById(
        order.customerId,
      );

      if (customer == null) {
        throw Exception('Customer not found');
      }

      final doc = await _invoiceService.generateInvoicePdf(
        order: order,
        customer: customer,
        companyName: companyName,
        companyAddress: companyAddress,
        companyPhone: companyPhone,
      );

      state = state.copyWith(
        document: doc,
        isGenerating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: 'Failed to generate invoice: $e',
      );
    }
  }

  Future<void> printInvoice(String fileName) async {
    if (state.document == null) {
      state = state.copyWith(errorMessage: 'Invoice not generated yet');
      return;
    }

    state = state.copyWith(
      currentAction: InvoiceActionType.printing,
      clearError: true,
    );

    try {
      await _invoiceService.printInvoice(state.document!, fileName);
      state = state.copyWith(
        clearAction: true,
        successMessage: 'Print job sent successfully',
      );
    } catch (e) {
      state = state.copyWith(
        clearAction: true,
        errorMessage: 'Print failed: $e',
      );
    }
  }

  Future<void> savePdf(String fileName) async {
    if (state.document == null) {
      state = state.copyWith(errorMessage: 'Invoice not generated yet');
      return;
    }

    state = state.copyWith(
      currentAction: InvoiceActionType.saving,
      clearError: true,
    );

    try {
      final path = await _invoiceService.savePdf(state.document!, fileName);
      state = state.copyWith(
        savedFilePath: path,
        clearAction: true,
        successMessage: 'PDF saved successfully',
      );
    } catch (e) {
      state = state.copyWith(
        clearAction: true,
        errorMessage: 'Save failed: $e',
      );
    }
  }

  Future<void> sharePdf(String fileName) async {
    if (state.savedFilePath == null) {
      // Save first if not already saved
      await savePdf(fileName);
      if (state.savedFilePath == null) return;
    }

    state = state.copyWith(
      currentAction: InvoiceActionType.sharing,
      clearError: true,
    );

    try {
      await _invoiceService.sharePdf(state.savedFilePath!);
      state = state.copyWith(clearAction: true);
    } catch (e) {
      state = state.copyWith(
        clearAction: true,
        errorMessage: 'Share failed: $e',
      );
    }
  }

  Future<void> shareViaWhatsApp({
    required Order order,
    required Customer customer,
    required String fileName,
  }) async {
    if (state.savedFilePath == null) {
      await savePdf(fileName);
      if (state.savedFilePath == null) return;
    }

    state = state.copyWith(
      currentAction: InvoiceActionType.whatsapp,
      clearError: true,
    );

    try {
      await _invoiceService.shareViaWhatsApp(
        order: order,
        customer: customer,
        pdfPath: state.savedFilePath!,
      );
      state = state.copyWith(clearAction: true);
    } catch (e) {
      state = state.copyWith(
        clearAction: true,
        errorMessage: 'WhatsApp share failed: $e',
      );
    }
  }
}

final invoiceNotifierProvider = NotifierProvider<InvoiceNotifier, InvoiceState>(
  InvoiceNotifier.new,
);

// Provider to fetch order by ID
final orderByIdProvider = FutureProvider.family<Order?, int>((ref, id) async {
  final repo = OrderRepository();
  final db = await (await _getDatabase());
  final results = await db.query(
    'orders',
    where: 'id = ?',
    whereArgs: [id],
  );
  if (results.isEmpty) return null;
  return Order.fromMap(results.first);
});

Future<dynamic> _getDatabase() async {
  final dbService =
      await Future.value(() => _importDatabaseService());
  return dbService();
}

dynamic _importDatabaseService() {
  // This will be replaced by proper import in the screen
  return null;
}
