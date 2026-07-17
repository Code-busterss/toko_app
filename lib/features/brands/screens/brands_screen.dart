// lib/features/brands/screens/brands_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/features/brands/models/brand_model.dart';
import 'package:toko_app/features/brands/repositories/brand_repository.dart';

class BrandsScreen extends ConsumerStatefulWidget {
  const BrandsScreen({super.key});

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  final _repository = BrandRepository();
  final _searchController = TextEditingController();
  List<Brand> _allBrands = [];
  List<Brand> _filteredBrands = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoading = true);
    try {
      _allBrands = await _repository.getAllBrands();
      _applyFilter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading brands: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredBrands = List.from(_allBrands);
    } else {
      _filteredBrands = _allBrands
          .where((b) => b.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    setState(() {});
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
                final existing = await _repository.getBrandByName(name);
                if (existing != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Brand already exists'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                await _repository.addBrand(Brand(
                  name: name,
                  createdAt: DateTime.now(),
                ));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Brand added'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                await _repository.updateBrand(Brand(
                  id: brand.id,
                  name: name,
                  createdAt: brand.createdAt,
                ));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Brand updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }

              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadBrands();
    }
  }

  Future<void> _deleteBrand(Brand brand) async {
    final productCount = await _repository.getProductCountByBrand(brand.name);

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

    if (confirm == true) {
      await _repository.deleteBrand(brand.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brand deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBrands();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brands'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBrands,
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
                _searchQuery = value;
                _applyFilter();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBrands.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.branding_watermark_outlined,
                              size: 80,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No brands yet' : 'No brands found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBrands,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredBrands.length,
                          itemBuilder: (context, index) {
                            final brand = _filteredBrands[index];
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
      future: _repository.getProductCountByBrand(brand.name),
      builder: (context, snapshot) {
        final productCount = snapshot.data ?? 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
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
