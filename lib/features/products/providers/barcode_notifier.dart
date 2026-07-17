// lib/features/products/providers/barcode_notifier.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/constants/constants.dart';

class BarcodeState {
  final int quantity;
  final pw.Barcode selectedPdfBarcodeType;
  final pw.Barcode selectedUiBarcodeType;
  final String selectedBarcodeTypeName;
  final bool isLoading;
  final String? errorMessage;

  BarcodeState({
    this.quantity = 1,
    pw.Barcode? selectedPdfBarcodeType,
    pw.Barcode? selectedUiBarcodeType,
    String? selectedBarcodeTypeName,
    this.isLoading = false,
    this.errorMessage,
  })  : selectedPdfBarcodeType = selectedPdfBarcodeType ?? pw.Barcode.code128(),
        selectedUiBarcodeType = selectedUiBarcodeType ?? pw.Barcode.code128(),
        selectedBarcodeTypeName = selectedBarcodeTypeName ?? 'Code 128';

  BarcodeState copyWith({
    int? quantity,
    pw.Barcode? selectedPdfBarcodeType,
    pw.Barcode? selectedUiBarcodeType,
    String? selectedBarcodeTypeName,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BarcodeState(
      quantity: quantity ?? this.quantity,
      selectedPdfBarcodeType: selectedPdfBarcodeType ?? this.selectedPdfBarcodeType,
      selectedUiBarcodeType: selectedUiBarcodeType ?? this.selectedUiBarcodeType,
      selectedBarcodeTypeName: selectedBarcodeTypeName ?? this.selectedBarcodeTypeName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BarcodeNotifier extends StateNotifier<BarcodeState> {
  BarcodeNotifier() : super(BarcodeState());

  void setQuantity(int quantity) {
    state = state.copyWith(quantity: quantity);
  }

  void incrementQuantity() {
    if (state.quantity < 100) {
      state = state.copyWith(quantity: state.quantity + 1);
    }
  }

  void decrementQuantity() {
    if (state.quantity > 1) {
      state = state.copyWith(quantity: state.quantity - 1);
    }
  }

  void setBarcodeType(String typeName) {
    final barcodeTypes = _getBarcodeTypes();
    final selected = barcodeTypes.firstWhere(
      (type) => type['name'] == typeName,
      orElse: () => barcodeTypes.first,
    );
    state = state.copyWith(
      selectedPdfBarcodeType: selected['pdfBarcode'] as pw.Barcode,
      selectedUiBarcodeType: selected['uiBarcode'] as pw.Barcode,
      selectedBarcodeTypeName: typeName,
    );
  }

  void detectBarcodeType(String? barcode, String? sku) {
    final code = barcode ?? sku ?? '';
    if (code.isEmpty) return;

    final barcodeTypes = _getBarcodeTypes();

    if (code.length == 13 && RegExp(r'^\d{13}$').hasMatch(code)) {
      final ean13 = barcodeTypes.firstWhere((t) => t['name'] == 'EAN 13');
      state = state.copyWith(
        selectedPdfBarcodeType: ean13['pdfBarcode'] as pw.Barcode,
        selectedUiBarcodeType: ean13['uiBarcode'] as pw.Barcode,
        selectedBarcodeTypeName: 'EAN 13',
      );
    } else if (code.length == 8 && RegExp(r'^\d{8}$').hasMatch(code)) {
      final ean8 = barcodeTypes.firstWhere((t) => t['name'] == 'EAN 8');
      state = state.copyWith(
        selectedPdfBarcodeType: ean8['pdfBarcode'] as pw.Barcode,
        selectedUiBarcodeType: ean8['uiBarcode'] as pw.Barcode,
        selectedBarcodeTypeName: 'EAN 8',
      );
    } else if (code.length == 12 && RegExp(r'^\d{12}$').hasMatch(code)) {
      final upcA = barcodeTypes.firstWhere((t) => t['name'] == 'UPC A');
      state = state.copyWith(
        selectedPdfBarcodeType: upcA['pdfBarcode'] as pw.Barcode,
        selectedUiBarcodeType: upcA['uiBarcode'] as pw.Barcode,
        selectedBarcodeTypeName: 'UPC A',
      );
    }
  }

  List<Map<String, dynamic>> _getBarcodeTypes() {
    return [
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
  }

  List<Map<String, dynamic>> get barcodeTypes => _getBarcodeTypes();

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final barcodeNotifierProvider =
    StateNotifierProvider<BarcodeNotifier, BarcodeState>((ref) {
  return BarcodeNotifier();
});
