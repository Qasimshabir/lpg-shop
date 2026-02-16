import 'package:flutter/material.dart';
import '../../services/lpg_api_service.dart';
import '../../models/lpg_product.dart';
import '../../lpg_theme.dart';

class AddProductScreen extends StatefulWidget {
  final LPGProduct? product; // null for add, non-null for edit

  const AddProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _depositAmountController = TextEditingController();
  final _refillPriceController = TextEditingController();

  // Form values
  String _productType = 'cylinder';
  String _category = 'LPG Cylinder';
  String? _cylinderType;
  double? _capacity;

  // Cylinder states (only for cylinders)
  final _emptyController = TextEditingController(text: '0');
  final _filledController = TextEditingController(text: '0');

  bool get isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final product = widget.product!;
    _nameController.text = product.name;
    _brandController.text = product.brand;
    _skuController.text = product.sku;
    _priceController.text = product.price.toString();
    _costPriceController.text = product.costPrice.toString();
    _stockController.text = product.stock.toString();
    _minStockController.text = product.minStock.toString();
    _descriptionController.text = product.description ?? '';
    _depositAmountController.text = product.depositAmount.toString();
    _refillPriceController.text = product.refillPrice.toString();
    
    _productType = product.productType;
    _category = product.category;
    _cylinderType = product.cylinderType;
    _capacity = product.capacity;
    
    if (product.cylinderStates != null) {
      _emptyController.text = product.cylinderStates!.empty.toString();
      _filledController.text = product.cylinderStates!.filled.toString();
    }
  }

  final List<String> _categories = [
    'LPG Cylinder',
    'Gas Pipe',
    'Regulator',
    'Gas Stove',
    'Gas Tandoor',
    'Gas Heater',
    'LPG Instant Geyser',
    'Safety Equipment',
    'Accessories',
    'Other',
  ];

  final List<Map<String, dynamic>> _cylinderTypes = [
    {'label': '11.8 kg (Domestic)', 'value': '11.8kg', 'capacity': 11.8},
    {'label': '15 kg (Commercial)', 'value': '15kg', 'capacity': 15.0},
    {'label': '45.4 kg (Industrial)', 'value': '45.4kg', 'capacity': 45.4},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    _depositAmountController.dispose();
    _refillPriceController.dispose();
    _emptyController.dispose();
    _filledController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productData = {
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'category': _category,
        'productType': _productType,
        'sku': _skuController.text.trim(),
        'price': double.parse(_priceController.text),
        'costPrice': double.parse(_costPriceController.text),
        'description': _descriptionController.text.trim(),
        'isActive': true,
      };

      if (_productType == 'cylinder') {
        productData['cylinderType'] = _cylinderType!;
        productData['capacity'] = _capacity!;
        productData['depositAmount'] = double.parse(_depositAmountController.text);
        productData['refillPrice'] = double.parse(_refillPriceController.text);
        productData['cylinderStates'] = {
          'empty': int.parse(_emptyController.text),
          'filled': int.parse(_filledController.text),
          'sold': 0,
        };
      } else {
        productData['stock'] = int.parse(_stockController.text);
        productData['minStock'] = int.parse(_minStockController.text);
      }

      if (isEditMode) {
        await LPGApiService.updateLPGProduct(widget.product!.id, productData);
      } else {
        await LPGApiService.createLPGProduct(productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Product updated successfully!' : 'Product added successfully!'),
            backgroundColor: LPGColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isEditMode ? 'update' : 'add'} product: $e'),
            backgroundColor: LPGColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Product' : 'Add New Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildProductTypeSelector(),
            SizedBox(height: 24),
            _buildBasicInfoSection(),
            SizedBox(height: 24),
            if (_productType == 'cylinder') ...[
              _buildCylinderSpecificSection(),
              SizedBox(height: 24),
            ],
            _buildPricingSection(),
            SizedBox(height: 24),
            if (_productType == 'accessory') ...[
              _buildStockSection(),
              SizedBox(height: 24),
            ] else ...[
              _buildCylinderStatesSection(),
              SizedBox(height: 24),
            ],
            _buildAdditionalInfoSection(),
            SizedBox(height: 32),
            _buildSaveButton(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTypeSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Type', style: LPGTextStyles.subtitle1),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Radio<String>(
                    value: 'cylinder',
                    groupValue: _productType,
                    onChanged: (value) {
                      setState(() {
                        _productType = value!;
                        _category = 'LPG Cylinder';
                      });
                    },
                  ),
                ),
                Text('Cylinder'),
                SizedBox(width: 16),
                Expanded(
                  child: Radio<String>(
                    value: 'accessory',
                    groupValue: _productType,
                    onChanged: (value) {
                      setState(() {
                        _productType = value!;
                        _category = 'Accessories';
                      });
                    },
                  ),
                ),
                Text('Accessory'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Product Name *',
                hintText: 'e.g., HP Gas Cylinder',
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: InputDecoration(
                labelText: 'Brand *',
                hintText: 'e.g., HP, Indane, Bharat Gas',
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(labelText: 'Category *'),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _skuController,
              decoration: InputDecoration(
                labelText: 'SKU *',
                hintText: 'Stock Keeping Unit',
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCylinderSpecificSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cylinder Specifications', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _cylinderType,
              decoration: InputDecoration(labelText: 'Cylinder Type *'),
              items: _cylinderTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'] as String,
                  child: Text(type['label'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _cylinderType = value;
                  _capacity = _cylinderTypes.firstWhere(
                    (t) => t['value'] == value,
                  )['capacity'];
                });
              },
              validator: (value) => value == null ? 'Required' : null,
            ),
            if (_capacity != null) ...[
              SizedBox(height: 8),
              Text(
                'Capacity: $_capacity kg',
                style: LPGTextStyles.body2.copyWith(color: LPGColors.info),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pricing', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Selling Price *',
                prefixText: 'Rs ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                if (double.tryParse(value!) == null) return 'Invalid number';
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _costPriceController,
              decoration: InputDecoration(
                labelText: 'Cost Price *',
                prefixText: 'Rs ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                if (double.tryParse(value!) == null) return 'Invalid number';
                return null;
              },
            ),
            if (_productType == 'cylinder') ...[
              SizedBox(height: 16),
              TextFormField(
                controller: _depositAmountController,
                decoration: InputDecoration(
                  labelText: 'Deposit Amount',
                  prefixText: 'Rs ',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _refillPriceController,
                decoration: InputDecoration(
                  labelText: 'Refill Price',
                  prefixText: 'Rs ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock Management', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: InputDecoration(labelText: 'Initial Stock *'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                if (int.tryParse(value!) == null) return 'Invalid number';
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _minStockController,
              decoration: InputDecoration(
                labelText: 'Minimum Stock Level *',
                hintText: 'Alert when stock falls below this',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                if (int.tryParse(value!) == null) return 'Invalid number';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCylinderStatesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cylinder Inventory', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emptyController,
                    decoration: InputDecoration(
                      labelText: 'Empty Cylinders',
                      prefixIcon: Icon(Icons.propane_tank, color: LPGColors.cylinderEmpty),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _filledController,
                    decoration: InputDecoration(
                      labelText: 'Filled Cylinders',
                      prefixIcon: Icon(Icons.propane_tank, color: LPGColors.cylinderFilled),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Additional Information', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Product details, features, etc.',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProduct,
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text('Add Product'),
      ),
    );
  }
}
