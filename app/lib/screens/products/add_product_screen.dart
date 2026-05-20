import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../services/lpg_api_service.dart';
import '../../models/lpg_product.dart';
import '../../lpg_theme.dart';
import '../../widgets/product_image_widget.dart';

class AddProductScreen extends StatefulWidget {
  final LPGProduct? product; // null for add, non-null for edit

  const AddProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImageFile;
  Uint8List? _webImageBytes;
  String? _imageBase64;

  // Form controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _depositAmountController = TextEditingController(text: '0');
  final _refillPriceController = TextEditingController(text: '0');

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        // Get file extension
        final extension = pickedFile.name.split('.').last.toLowerCase();
        final mimeType = extension == 'png' ? 'png' : 'jpeg';
        
        setState(() {
          _selectedImageFile = pickedFile;
          if (kIsWeb) {
            _webImageBytes = bytes;
          }
          _imageBase64 = 'data:image/$mimeType;base64,$base64Image';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: LPGColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    // On web, camera is not available, so directly pick from gallery
    if (kIsWeb) {
      _pickImage(ImageSource.gallery);
      return;
    }
    
    // On mobile, show options for camera or gallery
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImageFile != null || (isEditMode && widget.product!.imageUrl != null))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImageFile = null;
                    _webImageBytes = null;
                    _imageBase64 = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
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
      // Debug: Log all controller values before building productData
      print('=== FORM CONTROLLER VALUES ===');
      print('Name: ${_nameController.text}');
      print('Price: ${_priceController.text}');
      print('Cost Price: ${_costPriceController.text}');
      print('Product Type: $_productType');
      print('Deposit Amount Controller: "${_depositAmountController.text}"');
      print('Refill Price Controller: "${_refillPriceController.text}"');
      
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

      // Add image if selected
      if (_imageBase64 != null) {
        productData['image'] = _imageBase64!;
      }

      if (_productType == 'cylinder') {
        productData['cylinderType'] = _cylinderType!;
        productData['capacity'] = _capacity!;
        
        // Debug: Log controller values
        print('=== FRONTEND DEBUG ===');
        print('depositAmountController.text: "${_depositAmountController.text}"');
        print('refillPriceController.text: "${_refillPriceController.text}"');
        
        final depositAmount = _depositAmountController.text.isEmpty 
            ? 0.0 
            : double.parse(_depositAmountController.text);
        final refillPrice = _refillPriceController.text.isEmpty 
            ? 0.0 
            : double.parse(_refillPriceController.text);
            
        print('Parsed depositAmount: $depositAmount');
        print('Parsed refillPrice: $refillPrice');
        
        productData['depositAmount'] = depositAmount;
        productData['refillPrice'] = refillPrice;
        productData['cylinderStates'] = {
          'empty': int.parse(_emptyController.text),
          'filled': int.parse(_filledController.text),
          'sold': 0,
        };
        
        print('Final productData: $productData');
      } else {
        productData['stock'] = int.parse(_stockController.text);
        productData['minStock'] = int.parse(_minStockController.text);
      }

      print('=== SENDING TO API ===');
      print('Product Data: ${json.encode(productData)}');

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
            _buildImageSection(),
            SizedBox(height: 24),
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

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Image', style: LPGTextStyles.subtitle1),
            SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: Icon(_selectedImageFile != null || (isEditMode && widget.product!.imageUrl != null)
                    ? Icons.edit
                    : Icons.add_photo_alternate),
                label: Text(_selectedImageFile != null || (isEditMode && widget.product!.imageUrl != null)
                    ? 'Change Image'
                    : 'Add Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LPGColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (_selectedImageFile != null || (isEditMode && widget.product!.imageUrl != null))
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImageFile = null;
                      _webImageBytes = null;
                      _imageBase64 = null;
                    });
                  },
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('Remove Image', style: TextStyle(color: Colors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    // Show selected image
    if (_selectedImageFile != null) {
      if (kIsWeb && _webImageBytes != null) {
        // Web: Use memory image
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            _webImageBytes!,
            fit: BoxFit.cover,
          ),
        );
      } else if (!kIsWeb) {
        // Mobile: Use file image
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(_selectedImageFile!.path),
            fit: BoxFit.cover,
          ),
        );
      }
    }
    
    // Show existing image in edit mode
    if (isEditMode && widget.product!.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          widget.product!.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
        ),
      );
    }
    
    // Show placeholder
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.propane_tank, size: 80, color: Colors.grey[400]),
        SizedBox(height: 8),
        Text(
          'Tap to add image',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
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
                helperText: 'Enter a descriptive product name',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Product name is required';
                if (value!.length < 3) return 'Name must be at least 3 characters';
                if (value.length > 100) return 'Name is too long (max: 100 characters)';
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: InputDecoration(
                labelText: 'Brand *',
                hintText: 'e.g., HP, Indane, Bharat Gas',
                helperText: 'Enter the brand or manufacturer name',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Brand is required';
                if (value!.length < 2) return 'Brand must be at least 2 characters';
                if (value.length > 50) return 'Brand name is too long (max: 50 characters)';
                return null;
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'Category *',
                helperText: 'Select product category',
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) => setState(() => _category = value!),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Category is required';
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _skuController,
              decoration: InputDecoration(
                labelText: 'SKU *',
                hintText: 'e.g., HP-15KG-001',
                helperText: 'Stock Keeping Unit - unique identifier',
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'SKU is required';
                if (value!.length < 3) return 'SKU must be at least 3 characters';
                if (value.length > 50) return 'SKU is too long (max: 50 characters)';
                // Check for valid SKU format (alphanumeric and hyphens)
                if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(value)) {
                  return 'SKU can only contain uppercase letters, numbers, and hyphens';
                }
                return null;
              },
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
            SizedBox(height: 8),
            Text(
              'Select cylinder type and capacity',
              style: LPGTextStyles.caption.copyWith(color: LPGColors.textSecondary),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _cylinderType,
              decoration: InputDecoration(
                labelText: 'Cylinder Type *',
                helperText: 'Select the cylinder size category',
              ),
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Cylinder type is required';
                }
                return null;
              },
            ),
            if (_capacity != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LPGColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LPGColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: LPGColors.success),
                    SizedBox(width: 8),
                    Text(
                      'Capacity: $_capacity kg',
                      style: LPGTextStyles.body2.copyWith(
                        color: LPGColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
                hintText: 'e.g., 3000',
                helperText: 'Must be a positive number',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Selling price is required';
                final price = double.tryParse(value!);
                if (price == null) return 'Please enter a valid number';
                if (price <= 0) return 'Price must be greater than 0';
                if (price > 1000000) return 'Price seems too high (max: 1,000,000)';
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _costPriceController,
              decoration: InputDecoration(
                labelText: 'Cost Price *',
                prefixText: 'Rs ',
                hintText: 'e.g., 2500',
                helperText: 'Must be a positive number',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Cost price is required';
                final cost = double.tryParse(value!);
                if (cost == null) return 'Please enter a valid number';
                if (cost < 0) return 'Cost price cannot be negative';
                if (cost > 1000000) return 'Cost price seems too high (max: 1,000,000)';
                
                // Validate cost vs selling price
                final sellingPrice = double.tryParse(_priceController.text);
                if (sellingPrice != null && cost > sellingPrice) {
                  return 'Cost price should not exceed selling price';
                }
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
                  hintText: 'e.g., 1500',
                  helperText: 'Optional - Amount for cylinder deposit',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return null; // Optional field
                  final deposit = double.tryParse(value!);
                  if (deposit == null) return 'Please enter a valid number';
                  if (deposit < 0) return 'Deposit amount cannot be negative';
                  if (deposit > 100000) return 'Deposit amount seems too high (max: 100,000)';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _refillPriceController,
                decoration: InputDecoration(
                  labelText: 'Refill Price',
                  prefixText: 'Rs ',
                  hintText: 'e.g., 800',
                  helperText: 'Optional - Price for refilling cylinder',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return null; // Optional field
                  final refill = double.tryParse(value!);
                  if (refill == null) return 'Please enter a valid number';
                  if (refill < 0) return 'Refill price cannot be negative';
                  if (refill > 100000) return 'Refill price seems too high (max: 100,000)';
                  return null;
                },
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
              decoration: InputDecoration(
                labelText: 'Initial Stock *',
                hintText: 'e.g., 50',
                helperText: 'Number of units in stock',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Initial stock is required';
                final stock = int.tryParse(value!);
                if (stock == null) return 'Please enter a valid whole number';
                if (stock < 0) return 'Stock cannot be negative';
                if (stock > 10000) return 'Stock seems too high (max: 10,000)';
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _minStockController,
              decoration: InputDecoration(
                labelText: 'Minimum Stock Level *',
                hintText: 'e.g., 10',
                helperText: 'Alert when stock falls below this level',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Minimum stock level is required';
                final minStock = int.tryParse(value!);
                if (minStock == null) return 'Please enter a valid whole number';
                if (minStock < 0) return 'Minimum stock cannot be negative';
                if (minStock > 1000) return 'Minimum stock seems too high (max: 1,000)';
                
                // Validate min stock vs current stock
                final currentStock = int.tryParse(_stockController.text);
                if (currentStock != null && minStock > currentStock) {
                  return 'Minimum stock should not exceed current stock';
                }
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
            SizedBox(height: 8),
            Text(
              'Track cylinder states for inventory management',
              style: LPGTextStyles.caption.copyWith(color: LPGColors.textSecondary),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emptyController,
                    decoration: InputDecoration(
                      labelText: 'Empty Cylinders',
                      hintText: '0',
                      prefixIcon: Icon(Icons.propane_tank, color: LPGColors.cylinderEmpty),
                      helperText: 'Number of empty units',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      final empty = int.tryParse(value!);
                      if (empty == null) return 'Invalid number';
                      if (empty < 0) return 'Cannot be negative';
                      if (empty > 10000) return 'Too high (max: 10,000)';
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
                      hintText: '0',
                      prefixIcon: Icon(Icons.propane_tank, color: LPGColors.cylinderFilled),
                      helperText: 'Number of filled units',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      final filled = int.tryParse(value!);
                      if (filled == null) return 'Invalid number';
                      if (filled < 0) return 'Cannot be negative';
                      if (filled > 10000) return 'Too high (max: 10,000)';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LPGColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LPGColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: LPGColors.info),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total stock will be calculated as: Empty + Filled',
                      style: LPGTextStyles.caption.copyWith(color: LPGColors.info),
                    ),
                  ),
                ],
              ),
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
                hintText: 'Product details, features, specifications, etc.',
                helperText: 'Optional - Add any additional product information',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'Description is too long (max: 500 characters)';
                }
                return null;
              },
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
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveProduct,
        icon: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(isEditMode ? Icons.save : Icons.add),
        label: Text(
          _isLoading 
              ? 'Saving...' 
              : isEditMode 
                  ? 'Update Product' 
                  : 'Add Product',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: LPGColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
