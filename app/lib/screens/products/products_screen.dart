import 'package:flutter/material.dart';
import '../../models/lpg_product.dart';
import '../../services/lpg_api_service.dart';
import '../../lpg_theme.dart';
import '../../widgets/app_drawer.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LPGProduct> _products = [];
  List<LPGProduct> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedType = 'All';

  final List<String> _categories = [
    'All',
    'LPG Cylinder',
    'Gas Pipe',
    'Regulator',
    'Gas Stove',
    'Accessories',
    'Safety Equipment',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoading = true);
      final products = await LPGApiService.getLPGProducts(limit: 100);
      setState(() {
        _products = products;
        _filterProducts();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load products: $e');
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.sku.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
        final matchesType = _selectedType == 'All' ||
            (_selectedType == 'Cylinder' && product.productType == 'cylinder') ||
            (_selectedType == 'Accessory' && product.productType == 'accessory');
        
        return matchesSearch && matchesCategory && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products & Inventory'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Products'),
            Tab(text: 'Cylinders'),
            Tab(text: 'Accessories'),
          ],
          onTap: (index) {
            setState(() {
              _selectedType = index == 0 ? 'All' : (index == 1 ? 'Cylinder' : 'Accessory');
              _filterProducts();
            });
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: '/products'),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : _buildProductList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddProduct(),
        icon: Icon(Icons.add),
        label: Text('Add Product'),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filterProducts();
              });
            },
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _filterProducts();
                      });
                    },
                    selectedColor: LPGColors.primary.withOpacity(0.2),
                    checkmarkColor: LPGColors.primary,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(LPGProduct product) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: product.productType == 'cylinder'
                          ? LPGColors.primary.withOpacity(0.1)
                          : LPGColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      product.productType == 'cylinder' ? Icons.propane_tank : Icons.build,
                      color: product.productType == 'cylinder' ? LPGColors.primary : LPGColors.secondary,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.displayName,
                          style: LPGTextStyles.subtitle1,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${product.brand} • ${product.category}',
                          style: LPGTextStyles.body2.copyWith(color: LPGColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  _buildStockBadge(product),
                ],
              ),
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip('Price', '₹${product.price.toStringAsFixed(0)}', LPGColors.success),
                  if (product.productType == 'cylinder')
                    _buildInfoChip('Available', '${product.availableCylinders}', LPGColors.info)
                  else
                    _buildInfoChip('Stock', '${product.stock}', LPGColors.info),
                  _buildInfoChip('SKU', product.sku, LPGColors.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(LPGProduct product) {
    Color color;
    String text;
    
    switch (product.stockStatus) {
      case 'Out of Stock':
        color = LPGColors.error;
        text = 'Out';
        break;
      case 'Low Stock':
        color = LPGColors.warning;
        text = 'Low';
        break;
      case 'Overstock':
        color = LPGColors.info;
        text = 'High';
        break;
      default:
        color = LPGColors.success;
        text = 'OK';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: LPGTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: LPGTextStyles.caption,
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: LPGTextStyles.body2.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 80, color: LPGColors.textTertiary),
          SizedBox(height: 16),
          Text(
            'No products found',
            style: LPGTextStyles.heading3.copyWith(color: LPGColors.textTertiary),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first product to get started',
            style: LPGTextStyles.body2.copyWith(color: LPGColors.textTertiary),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddProduct(),
            icon: Icon(Icons.add),
            label: Text('Add Product'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
    if (result == true) {
      _loadProducts();
    }
  }

  void _navigateToProductDetail(LPGProduct product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
    );
    if (result == true) {
      _loadProducts();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LPGColors.error),
    );
  }
}
