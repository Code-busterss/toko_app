// lib/core/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/features/auth/screens/splash_screen.dart';
import 'package:toko_app/features/auth/screens/login_screen.dart';
import 'package:toko_app/features/auth/screens/register_screen.dart';
import 'package:toko_app/features/auth/screens/forgot_password_screen.dart';
import 'package:toko_app/features/auth/screens/pin_lock_screen.dart';
import 'package:toko_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:toko_app/features/products/screens/product_list_screen.dart';
import 'package:toko_app/features/products/screens/add_product_screen.dart';
import 'package:toko_app/features/categories/screens/categories_screen.dart';
import 'package:toko_app/features/brands/screens/brands_screen.dart';
import 'package:toko_app/features/customers/screens/customer_list_screen.dart';
import 'package:toko_app/features/customers/screens/customer_detail_screen.dart';
import 'package:toko_app/features/customers/screens/add_customer_screen.dart';
import 'package:toko_app/features/orders/screens/create_order_screen.dart';
import 'package:toko_app/features/orders/screens/orders_list_screen.dart';
import 'package:toko_app/features/orders/screens/invoice_preview_screen.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/payments/screens/receive_payment_screen.dart';
import 'package:toko_app/features/payments/screens/credit_ledger_screen.dart';
import 'package:toko_app/features/settings/screens/pin_settings_screen.dart';
import 'package:toko_app/shared/widgets/main_shell.dart';

class _ComingSoonScreen extends StatelessWidget {
  final String title;
  const _ComingSoonScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.routeSplash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppConstants.routeForgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/pin-lock',
        name: 'pinLock',
        builder: (context, state) {
          final isSettingPin = (state.extra as Map<String, dynamic>?)?['isSettingPin'] as bool? ?? false;
          return PinLockScreen(isSettingPin: isSettingPin);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppConstants.routeDashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppConstants.routeProducts,
            builder: (context, state) => const ProductListScreen(),
          ),
          GoRoute(
            path: AppConstants.routeCustomers,
            builder: (context, state) => const CustomerListScreen(),
          ),
          GoRoute(
            path: AppConstants.routeOrders,
            builder: (context, state) => const OrdersListScreen(),
          ),
          GoRoute(
            path: AppConstants.routeSettings,
            builder: (context, state) => const _ComingSoonScreen('Settings'),
          ),
        ],
      ),
      GoRoute(
        path: AppConstants.routeProductAdd,
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProductEdit,
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProductDetail,
        builder: (context, state) => _ComingSoonScreen(
          'Product Detail - ID: ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: AppConstants.routeBrands,
        builder: (context, state) => const BrandsScreen(),
      ),
      GoRoute(
        path: AppConstants.routeCustomerDetail,
        builder: (context, state) => CustomerDetailScreen(
          customerId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppConstants.routeCustomerAdd,
        builder: (context, state) => const AddCustomerScreen(),
      ),
      GoRoute(
        path: AppConstants.routeCustomerEdit,
        builder: (context, state) => const AddCustomerScreen(),
      ),
      GoRoute(
        path: '/credit-ledger/:id',
        builder: (context, state) => CreditLedgerScreen(
          customerId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppConstants.routeOrderAdd,
        builder: (context, state) => const CreateOrderScreen(),
      ),
      GoRoute(
        path: '/invoice-preview',
        builder: (context, state) {
          final order = state.extra as Order?;
          if (order == null) {
            return const Scaffold(
              body: Center(child: Text('Order data not found')),
            );
          }
          return InvoicePreviewScreen(order: order);
        },
      ),
      GoRoute(
        path: AppConstants.routePayments,
        builder: (context, state) {
          final customerId = state.extra as int?;
          return ReceivePaymentScreen(initialCustomerId: customerId);
        },
      ),
      GoRoute(
        path: AppConstants.routePaymentAdd,
        builder: (context, state) {
          final customerId = state.extra as int?;
          return ReceivePaymentScreen(initialCustomerId: customerId);
        },
      ),
      GoRoute(
        path: AppConstants.routeOrderDetail,
        builder: (context, state) => _ComingSoonScreen(
          'Order Detail - ID: ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: AppConstants.routeOrderEdit,
        builder: (context, state) => _ComingSoonScreen(
          'Edit Order - ID: ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: AppConstants.routePurchases,
        builder: (context, state) => const _ComingSoonScreen('Purchases'),
      ),
      GoRoute(
        path: AppConstants.routePurchaseDetail,
        builder: (context, state) => _ComingSoonScreen(
          'Purchase Detail - ID: ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: AppConstants.routePurchaseAdd,
        builder: (context, state) => const _ComingSoonScreen('Add Purchase'),
      ),
      GoRoute(
        path: AppConstants.routePurchaseEdit,
        builder: (context, state) => _ComingSoonScreen(
          'Edit Purchase - ID: ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: AppConstants.routeSuppliers,
        builder: (context, state) => const _ComingSoonScreen('Suppliers'),
      ),
      GoRoute(
        path: AppConstants.routeSupplierDetail,
        builder: (context, state) => _ComingSoonScreen(
          'Supplier Detail - ID: ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: AppConstants.routeSupplierAdd,
        builder: (context, state) => const _ComingSoonScreen('Add Supplier'),
      ),
      GoRoute(
        path: AppConstants.routeSupplierEdit,
        builder: (context, state) => _ComingSoonScreen(
          'Edit Supplier - ID: ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: AppConstants.routeStock,
        builder: (context, state) => const _ComingSoonScreen('Stock'),
      ),
      GoRoute(
        path: AppConstants.routeStockDetail,
        builder: (context, state) => _ComingSoonScreen(
          'Stock Detail - ID: ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: AppConstants.routeStockAdjustment,
        builder: (context, state) =>
            const _ComingSoonScreen('Stock Adjustment'),
      ),
      GoRoute(
        path: AppConstants.routeExpenses,
        builder: (context, state) => const _ComingSoonScreen('Expenses'),
      ),
      GoRoute(
        path: AppConstants.routeExpenseAdd,
        builder: (context, state) => const _ComingSoonScreen('Add Expense'),
      ),
      GoRoute(
        path: AppConstants.routeExpenseEdit,
        builder: (context, state) => _ComingSoonScreen(
          'Edit Expense - ID: ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: AppConstants.routeReports,
        builder: (context, state) => const _ComingSoonScreen('Reports'),
      ),
      GoRoute(
        path: AppConstants.routeReportDetail,
        builder: (context, state) => _ComingSoonScreen(
          'Report Detail - ID: ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: AppConstants.routeReportGenerate,
        builder: (context, state) =>
            const _ComingSoonScreen('Generate Report'),
      ),
      GoRoute(
        path: AppConstants.routeAnalytics,
        builder: (context, state) => const _ComingSoonScreen('Analytics'),
      ),
      GoRoute(
        path: '/settings/pin',
        builder: (context, state) => const PinSettingsScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProfile,
        builder: (context, state) => const _ComingSoonScreen('Profile'),
      ),
      GoRoute(
        path: AppConstants.routeBackupRestore,
        builder: (context, state) =>
            const _ComingSoonScreen('Backup & Restore'),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('${state.uri}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.routeDashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}
