// lib/core/constants/constants.dart
import 'package:intl/intl.dart';

class AppConstants {
  // App Info
  static const String appName = 'Toko App';
  static const String appVersion = '1.0.0';
  static const String currencySymbol = 'Rp';
  static const String currencyCode = 'IDR';

  // Date Formats
  static final DateFormat dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');
  static final DateFormat timeFormat = DateFormat('HH:mm');
  static final DateFormat isoFormat =
      DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  static final DateFormat dayMonthFormat = DateFormat('dd MMM');
  static final DateFormat monthYearFormat = DateFormat('MMM yyyy');
  static final DateFormat yearMonthFormat = DateFormat('yyyy-MM');
  static final DateFormat backupFileFormat = DateFormat('yyyyMMdd');

  // Storage Keys (SharedPreferences)
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyIsFirstLaunch = 'is_first_launch';

  // Session
  static const String keySession = 'is_logged_in';

  // Business profile
  static const String keyCompanyName = 'company_name';
  static const String keyCompanyPhone = 'company_phone';
  static const String keyCompanyAddress = 'company_address';
  static const String keyCompanyLogo = 'company_logo'; // base64 string
  static const String keyUserEmail = 'user_email';

  // Invoice settings
  static const String keyInvoicePrefix = 'invoice_prefix';
  static const String keyInvoiceStartNo = 'invoice_start_no';

  // App settings
  static const String keyCurrencySymbol = 'currency_symbol';
  static const String keyCurrencyCode = 'currency_code';
  static const String keyDarkMode = 'dark_mode';

  // Security
  static const String keyPinCode = 'user_pin';
  static const String keyPinEnabled = 'pin_enabled';
  static const String keyFingerprintEnabled = 'fingerprint_enabled';

  // Backup
  static const String keyLastBackupDate = 'last_backup_date';

  // Search
  static const String keyRecentSearches = 'recent_searches';

  // Notifications
  static const String keyNotificationHistory = 'notification_history';

  // Currencies supported by the app
  static const List<Map<String, String>> currencies = [
    {'code': 'IDR', 'symbol': 'Rp', 'name': 'Indonesian Rupiah'},
    {'code': 'PKR', 'symbol': '₨', 'name': 'Pakistani Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
    {'code': 'SAR', 'symbol': '﷼', 'name': 'Saudi Riyal'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'MYR', 'symbol': 'RM', 'name': 'Malaysian Ringgit'},
  ];

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 6;
  static const int pinLength = 4;
  static const int maxProductNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const int searchDebounceMs = 300;
  static const int maxRecentSearches = 5;
  static const int backupReminderDays = 7;
  static const int paymentDueDays = 7;

  // Routes
  static const String routeSplash = '/splash';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeDashboard = '/dashboard';
  static const String routeProducts = '/products';
  static const String routeProductDetail = '/products/:id';
  static const String routeProductAdd = '/products/add';
  static const String routeProductEdit = '/products/:id/edit';
  static const String routeCustomers = '/customers';
  static const String routeCustomerDetail = '/customers/:id';
  static const String routeCustomerAdd = '/customers/add';
  static const String routeCustomerEdit = '/customers/:id/edit';
  static const String routeOrders = '/orders';
  static const String routeOrderDetail = '/orders/:id';
  static const String routeOrderAdd = '/orders/add';
  static const String routeOrderEdit = '/orders/:id/edit';
  static const String routePayments = '/payments';
  static const String routePaymentAdd = '/payments/add';
  static const String routeReceivePayment = '/payments/receive';
  static const String routePurchases = '/purchases';
  static const String routePurchaseDetail = '/purchases/:id';
  static const String routePurchaseAdd = '/purchases/add';
  static const String routePurchaseEdit = '/purchases/:id/edit';
  static const String routeSuppliers = '/suppliers';
  static const String routeSupplierDetail = '/suppliers/:id';
  static const String routeSupplierAdd = '/suppliers/add';
  static const String routeSupplierEdit = '/suppliers/:id/edit';
  static const String routeStock = '/stock';
  static const String routeStockDetail = '/stock/:id';
  static const String routeStockAdjustment = '/stock/adjustment';
  static const String routeStockHistory = '/stock/history/:id';
  static const String routeExpenses = '/expenses';
  static const String routeExpenseAdd = '/expenses/add';
  static const String routeExpenseEdit = '/expenses/:id/edit';
  static const String routeReports = '/reports';
  static const String routeReportDetail = '/reports/:id';
  static const String routeReportGenerate = '/reports/generate';
  static const String routeAnalytics = '/analytics';
  static const String routeSettings = '/settings';
  static const String routeProfile = '/settings/profile';
  static const String routeBackupRestore = '/settings/backup';
  static const String routePinLock = '/pin-lock';
  static const String routePinSettings = '/settings/pin';
  static const String routeCreditLedger = '/credit-ledger/:id';
  static const String routeInvoicePreview = '/invoice-preview';
  static const String routeCategories = '/categories';
  static const String routeBrands = '/brands';
  static const String routeNotifications = '/notifications';
  static const String routeSearch = '/search';
  static const String routeProfitLoss = '/reports/profit-loss';
  static const String routeCreateOrder = '/orders/add';
  static const String routeBarcodeScanner = '/barcode-scanner';
  static const String routeBarcodeDetail = '/barcode-detail';
  static const String routeImportPreview = '/import-preview';
  static const String routeAddProduct = '/products/add';
  static const String routeEditProduct = '/products/:id/edit';
  static const String routeCustomerBillProducts = '/customer-bill-products';
  static const String routeCustomerBillSummary = '/customer-bill-summary';
  static const String routeStats = '/settings/stats';
}
