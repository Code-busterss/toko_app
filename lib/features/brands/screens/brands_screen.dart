// lib/features/brands/screens/brands_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toko_app/features/brands/models/brand_model.dart';
import 'package:toko_app/features/brands/providers/brand_notifier.dart';

class BrandsScreen extends ConsumerStatefulWidget {
  const BrandsScreen({super.key});

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(brandNotifierProvider.notifier).loadBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddEditDialog({Brand? brand}) async {
    final controller = TextEditingController(text: brand?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(brand == null ? 'Add Brand' : 'Edit Brand'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Brand Name',
              hintText: 'Enter brand name',
              prefixIcon: Icon(Icons.branding_watermark),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Brand name is required';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final name = controller.text.trim();

              if (brand == null) {
                final existing = await ref
                    .read(brandNotifierProvider.notifier)
                    .getBrandByName(name);
                if (existing != null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Brand already exists'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                await ref.read(brandNotifierProvider.notifier).addBrand(Brand(
                      name: name,
                      createdAt: DateTime.now(),
                    ));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Brand added'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                await ref.read(brandNotifierProvider.notifier).updateBrand(Brand(
                      id: brand.id,
                      name: name,
                      createdAt: brand.createdAt,
                    ));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Brand updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              }

              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ref.read(brandNotifierProvider.notifier).loadBrands();
    }
  }

  Future<void> _deleteBrand(Brand brand) async {
    final productCount = await ref
        .read(brandNotifierProvider.notifier)
        .getProductCountByBrand(brand.name);

    if (!mounted) return;

    if (productCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: Text(
            'This brand is used by $productCount product(s). Please reassign those products before deleting.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Brand'),
        content: Text('Are you sure you want to delete "${brand.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(brandNotifierProvider.notifier).deleteBrand(brand.id!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brand deleted'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(brandNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brands'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(brandNotifierProvider.notifier).loadBrands(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search brands...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: (value) {
                ref
                    .read(brandNotifierProvider.notifier)
                    .setSearchQuery(value);
              },
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filteredBrands.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.branding_watermark_outlined,
                              size: 80,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.searchQuery.isEmpty
                                  ? 'No brands yet'
                                  : 'No brands found',
                              style:
                                  Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(brandNotifierProvider.notifier)
                            .loadBrands(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.filteredBrands.length,
                          itemBuilder: (context, index) {
                            final brand = state.filteredBrands[index];
                            return _buildBrandItem(context, brand);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Brand'),
      ),
    );
  }

  Widget _buildBrandItem(BuildContext context, Brand brand) {
    return FutureBuilder<int>(
      future: ref
          .read(brandNotifierProvider.notifier)
          .getProductCountByBrand(brand.name),
      builder: (context, snapshot) {
        final productCount = snapshot.data ?? 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withOpacity(0.1),
              child: Icon(
                Icons.branding_watermark,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            title: Text(
              brand.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('$productCount product(s)'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddEditDialog(brand: brand);
                } else if (value == 'delete') {
                  _deleteBrand(brand);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
