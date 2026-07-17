// lib/core/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'toko_app.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT UNIQUE,
        barcode TEXT,
        name TEXT NOT NULL,
        category TEXT,
        brand TEXT,
        buyingPrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        wholesalePrice REAL NOT NULL,
        stock INTEGER NOT NULL,
        minStock INTEGER NOT NULL,
        unit TEXT NOT NULL,
        supplierId INTEGER,
        tax REAL DEFAULT 0.0,
        discount REAL DEFAULT 0.0,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopName TEXT NOT NULL,
        ownerName TEXT NOT NULL,
        phone TEXT NOT NULL,
        whatsapp TEXT,
        address TEXT,
        city TEXT,
        email TEXT,
        creditLimit REAL DEFAULT 0.0,
        previousBalance REAL DEFAULT 0.0,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        items TEXT NOT NULL,
        discount REAL DEFAULT 0.0,
        tax REAL DEFAULT 0.0,
        totalAmount REAL NOT NULL,
        paidAmount REAL DEFAULT 0.0,
        paymentMethod INTEGER DEFAULT 0,
        status INTEGER DEFAULT 0,
        notes TEXT,
        invoiceNumber TEXT UNIQUE NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER,
        customerId INTEGER NOT NULL,
        customerName TEXT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        semanticType TEXT,
        type INTEGER NOT NULL,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        email TEXT,
        companyName TEXT,
        totalPurchases REAL DEFAULT 0,
        pendingAmount REAL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER NOT NULL,
        supplierName TEXT,
        purchaseDate TEXT NOT NULL,
        invoiceNo TEXT,
        subtotal REAL,
        transportCharges REAL DEFAULT 0,
        otherCharges REAL DEFAULT 0,
        totalAmount REAL NOT NULL,
        notes TEXT,
        products TEXT NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE purchaseitems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchaseId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT,
        quantity INTEGER NOT NULL,
        buyingPrice REAL NOT NULL,
        total REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_adjustments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        type INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        date TEXT NOT NULL,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE brands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Returns created lazily by ReturnRepository for backwards compatibility.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_returns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        invoiceNumber TEXT NOT NULL,
        customerId INTEGER NOT NULL,
        customerName TEXT NOT NULL,
        items TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        reason TEXT,
        status INTEGER NOT NULL,
        refundIssued INTEGER NOT NULL,
        stockRestored INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        completedAt TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v2 -> categories + brands
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS brands (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }

    // v3 -> enriched schema (additive, non-breaking) + purchaseitems table
    if (oldVersion < 3) {
      await _safeAddColumn(db, 'products', 'createdAt', 'TEXT');
      await _safeAddColumn(db, 'customers', 'createdAt', 'TEXT');

      await _safeAddColumn(db, 'orders', 'createdAt', 'TEXT');

      await _safeAddColumn(db, 'payments', 'customerName', 'TEXT');
      await _safeAddColumn(db, 'payments', 'notes', 'TEXT');
      await _safeAddColumn(db, 'payments', 'createdAt', 'TEXT');

      await _safeAddColumn(db, 'suppliers', 'totalPurchases', 'REAL DEFAULT 0');
      await _safeAddColumn(db, 'suppliers', 'pendingAmount', 'REAL DEFAULT 0');
      // suppliers already had no createdAt in <=v2; keep nullable for legacy rows.
      await _safeAddColumn(db, 'suppliers', 'createdAt', 'TEXT');

      await _safeAddColumn(db, 'purchases', 'supplierName', 'TEXT');
      await _safeAddColumn(db, 'purchases', 'subtotal', 'REAL');
      await _safeAddColumn(db, 'purchases', 'transportCharges', 'REAL DEFAULT 0');
      await _safeAddColumn(db, 'purchases', 'otherCharges', 'REAL DEFAULT 0');
      await _safeAddColumn(db, 'purchases', 'notes', 'TEXT');
      await _safeAddColumn(db, 'purchases', 'createdAt', 'TEXT');
      // Alias: older code reads purchases.date; keep it populated.
      await _safeAddColumn(db, 'purchases', 'date', 'TEXT');

      await _safeAddColumn(db, 'expenses', 'createdAt', 'TEXT');

      await _safeAddColumn(db, 'stock_adjustments', 'createdAt', 'TEXT');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchaseitems (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          purchaseId INTEGER NOT NULL,
          productId INTEGER NOT NULL,
          productName TEXT,
          quantity INTEGER NOT NULL,
          buyingPrice REAL NOT NULL,
          total REAL NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales_returns (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          orderId INTEGER NOT NULL,
          invoiceNumber TEXT NOT NULL,
          customerId INTEGER NOT NULL,
          customerName TEXT NOT NULL,
          items TEXT NOT NULL,
          totalAmount REAL NOT NULL,
          reason TEXT,
          status INTEGER NOT NULL,
          refundIssued INTEGER NOT NULL,
          stockRestored INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          completedAt TEXT
        )
      ''');
    }

    // v4 -> add semanticType to payments table
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE payments ADD COLUMN semanticType TEXT');
      } catch (_) {
        // Ignore error if column already exists
      }
    }
  }

  /// Adds a column only if it does not already exist (safe under re-run / partial upgrades).
  Future<void> _safeAddColumn(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final cols = await db.rawQuery('PRAGMA table_info($table)');
    final exists = cols.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('products');
    await db.delete('customers');
    await db.delete('orders');
    await db.delete('payments');
    await db.delete('suppliers');
    await db.delete('purchases');
    await db.delete('purchaseitems');
    await db.delete('expenses');
    await db.delete('stock_adjustments');
    await db.delete('categories');
    await db.delete('brands');
    try {
      await db.delete('sales_returns');
    } catch (_) {
      // table may not exist on legacy dbs
    }
  }

  /// All tables backed up / restored by Settings. Order matters for restore
  /// (parents before children).
  Future<List<String>> get allTableNames async {
    return const [
      'products',
      'customers',
      'orders',
      'payments',
      'suppliers',
      'purchases',
      'purchaseitems',
      'expenses',
      'stock_adjustments',
      'categories',
      'brands',
      'sales_returns',
    ];
  }
}
