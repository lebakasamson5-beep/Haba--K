import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/manager_service.dart';
import '../models/product.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ManagerService _managerService = ManagerService();
  bool _isLoading = true;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Snacks',
    'Beverages',
    'Food',
    'Electronics',
    'Stationery',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      _products = await _managerService.getAllProducts();
      _filterProducts();
    } catch (e) {
      print('Error loading products: $e');
    }
    setState(() => _isLoading = false);
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
        final matchesSearch = _searchQuery.isEmpty ||
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.barcode.contains(_searchQuery);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> _updateQuantity(Product product, int newQuantity) async {
    if (newQuantity < 0) return;

    try {
      await _managerService.updateProductQuantity(product.id, newQuantity);
      setState(() {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = Product(
            id: product.id,
            barcode: product.barcode,
            name: product.name,
            price: product.price,
            quantity: newQuantity,
            category: product.category,
            createdAt: product.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        _filterProducts();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} quantity updated to $newQuantity'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating quantity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterProducts();
                });
              },
            ),
          ),

          // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _filterProducts();
                      });
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Colors.green.shade100,
                    checkmarkColor: Colors.green.shade700,
                  ),
                );
              },
            ),
          ),

          // Product List
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan products to add them to inventory',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Product Icon
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getCategoryIcon(product.category),
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'TSh ${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Barcode: ${product.barcode}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product.category,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Quantity Controls
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Qty: ${product.quantity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: product.quantity > 0
                                      ? Colors.green.shade700
                                      : Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _updateQuantity(
                                    product,
                                    product.quantity - 1,
                                  ),
                                  iconSize: 20,
                                  color: Colors.red,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _updateQuantity(
                                    product,
                                    product.quantity + 1,
                                  ),
                                  iconSize: 20,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Snacks':
        return Icons.fastfood;
      case 'Beverages':
        return Icons.local_drink;
      case 'Food':
        return Icons.restaurant;
      case 'Electronics':
        return Icons.electrical_services;
      case 'Stationery':
        return Icons.edit_note;
      default:
        return Icons.inventory;
    }
  }
}