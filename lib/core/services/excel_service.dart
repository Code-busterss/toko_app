// lib/core/services/excel_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toko_app/features/products/models/product_model.dart';

class ImportResult {
  final List<Product> products;
  final List<String> errors;
  final int totalRows;

  ImportResult({
    required this.products,
    required this.errors,
    required this.totalRows,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get successCount => products.length;
}

class ExcelService {
  static const List<String> _headers = [
    'Name',
    'SKU',
    'Barcode',
    'Category',
    'Brand',
    'Buying Price',
    'Selling Price',
    'Wholesale Price',
    'Stock',
    'Min Stock',
    'Unit',
    'Tax %',
    'Discount %',
  ];

  /// Pick Excel file and parse products
  Future<ImportResult?> importProducts() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('Unable to read file');
      }

      final excel = Excel.decodeBytes(file.bytes!);
      final sheet = excel.tables[excel.tables.keys.first];

      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('Excel file is empty');
      }

      // Find header row
      int headerRowIndex = -1;
      Map<String, int> columnMap = {};

      for (int i = 0; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final firstCell = _getCellString(row, 0);
        if (firstCell.toLowerCase() == 'name') {
          headerRowIndex = i;
          for (int j = 0; j < row.length; j++) {
            final header = _getCellString(row, j).toLowerCase();
            columnMap[header] = j;
          }
          break;
        }
      }

      if (headerRowIndex == -1) {
        throw Exception('Header row not found. First column must be "Name"');
      }

      final products = <Product>[];
      final errors = <String>[];
      int rowNum = headerRowIndex + 2;

      for (int i = headerRowIndex + 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        if (_isRowEmpty(row)) continue;

        try {
          final name = _getCellString(row, _getColumnIndex(columnMap, 'name'));
          if (name.isEmpty) {
            errors.add('Row $rowNum: Name is required');
            rowNum++;
            continue;
          }

          final buyingPrice = _getCellDouble(row, _getColumnIndex(columnMap, 'buying price'));
          final sellingPrice = _getCellDouble(row, _getColumnIndex(columnMap, 'selling price'));
          final wholesalePrice = _getCellDouble(row, _getColumnIndex(columnMap, 'wholesale price'));
          final stock = _getCellInt(row, _getColumnIndex(columnMap, 'stock'));
          final minStock = _getCellInt(row, _getColumnIndex(columnMap, 'min stock'));
          final unit = _getCellString(row, _getColumnIndex(columnMap, 'unit'));

          if (buyingPrice == null || sellingPrice == null || wholesalePrice == null) {
            errors.add('Row $rowNum: Invalid price values');
            rowNum++;
            continue;
          }

          if (stock == null || minStock == null) {
            errors.add('Row $rowNum: Invalid stock values');
            rowNum++;
            continue;
          }

          if (unit.isEmpty) {
            errors.add('Row $rowNum: Unit is required');
            rowNum++;
            continue;
          }

          final product = Product(
            name: name,
            sku: _getCellString(row, _getColumnIndex(columnMap, 'sku')),
            barcode: _getCellString(row, _getColumnIndex(columnMap, 'barcode')),
            category: _getCellString(row, _getColumnIndex(columnMap, 'category')),
            brand: _getCellString(row, _getColumnIndex(columnMap, 'brand')),
            buyingPrice: buyingPrice,
            sellingPrice: sellingPrice,
            wholesalePrice: wholesalePrice,
            stock: stock,
            minStock: minStock,
            unit: unit,
            tax: _getCellDouble(row, _getColumnIndex(columnMap, 'tax %')) ?? 0.0,
            discount: _getCellDouble(row, _getColumnIndex(columnMap, 'discount %')) ?? 0.0,
          );

          products.add(product);
        } catch (e) {
          errors.add('Row $rowNum: $e');
        }
        rowNum++;
      }

      return ImportResult(
        products: products,
        errors: errors,
        totalRows: sheet.rows.length - headerRowIndex - 1,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Export products to Excel file
  Future<String> exportProducts(List<Product> products) async {
    final excel = Excel.createExcel();
    const sheetName = 'Products';
    final sheet = excel[sheetName];

    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 12,
    );

    for (int i = 0; i < _headers.length; i++) {
      final cellIndex = CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0);
      final cell = sheet.cell(cellIndex);
      cell.value = TextCellValue(_headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final rowIndex = i + 1;

      _setCellString(sheet, 0, rowIndex, product.name);
      _setCellString(sheet, 1, rowIndex, product.sku ?? '');
      _setCellString(sheet, 2, rowIndex, product.barcode ?? '');
      _setCellString(sheet, 3, rowIndex, product.category ?? '');
      _setCellString(sheet, 4, rowIndex, product.brand ?? '');
      _setCellDouble(sheet, 5, rowIndex, product.buyingPrice);
      _setCellDouble(sheet, 6, rowIndex, product.sellingPrice);
      _setCellDouble(sheet, 7, rowIndex, product.wholesalePrice);
      _setCellInt(sheet, 8, rowIndex, product.stock);
      _setCellInt(sheet, 9, rowIndex, product.minStock);
      _setCellString(sheet, 10, rowIndex, product.unit);
      _setCellDouble(sheet, 11, rowIndex, product.tax);
      _setCellDouble(sheet, 12, rowIndex, product.discount);
    }

    for (int i = 0; i < _headers.length; i++) {
      sheet.setColumnWidth(i, 20.0);
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/products_export_$timestamp.xlsx';
    final file = File(filePath);

    await file.writeAsBytes(excel.encode()!);

    return filePath;
  }

  /// Share the exported file
  /// ✅ Fixed: share_plus version ^9.0.0 ke mutabiq new method use kiya
  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Products Export',
    );
  }

  int _getColumnIndex(Map<String, int> columnMap, String header) {
    return columnMap[header.toLowerCase()] ?? -1;
  }

  String _getCellString(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return '';
    final cell = row[index];
    if (cell == null || cell.value == null) return '';

    final value = cell.value;
    if (value is TextCellValue) return (value.value.text ?? '').trim();
    if (value is IntCellValue) return value.value.toString().trim();
    if (value is DoubleCellValue) return value.value.toString().trim();
    return value.toString().trim();
  }

  double? _getCellDouble(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return null;
    final cell = row[index];
    if (cell == null || cell.value == null) return null;

    final value = cell.value;
    if (value is DoubleCellValue) return value.value;
    if (value is IntCellValue) return value.value.toDouble();
    if (value is TextCellValue) {
      return double.tryParse((value.value.text ?? '').replaceAll(',', ''));
    }
    return null;
  }

  int? _getCellInt(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return null;
    final cell = row[index];
    if (cell == null || cell.value == null) return null;

    final value = cell.value;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value.toInt();
    if (value is TextCellValue) {
      return int.tryParse((value.value.text ?? '').replaceAll(',', ''));
    }
    return null;
  }

  bool _isRowEmpty(List<Data?> row) {
    for (final cell in row) {
      if (cell != null && cell.value != null) {
        final value = cell.value;
        String strValue = '';
        if (value is TextCellValue) {
          strValue = value.value.text ?? '';
        } else if (value is IntCellValue) strValue = value.value.toString();
        else if (value is DoubleCellValue) strValue = value.value.toString();
        else strValue = value.toString();

        if (strValue.trim().isNotEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  void _setCellString(Sheet sheet, int col, int row, String value) {
    final cell = CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);
    sheet.cell(cell).value = TextCellValue(value);
  }

  void _setCellDouble(Sheet sheet, int col, int row, double value) {
    final cell = CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);
    sheet.cell(cell).value = DoubleCellValue(value);
  }

  void _setCellInt(Sheet sheet, int col, int row, int value) {
    final cell = CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);
    sheet.cell(cell).value = IntCellValue(value);
  }
}